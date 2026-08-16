import "dotenv/config";
import express from "express";
import cors from "cors";
import session from "express-session";
import QRCode from "qrcode";
import bwipjs from "bwip-js";
import path from "path";
import { fileURLToPath } from "url";

import {
  getMembershipHistory,
  getCustomerProfileFromArms
} from "./arms.js";

const app = express();
const port = Number(process.env.PORT || 5000);

/*
|--------------------------------------------------------------------------
| PATHS
|--------------------------------------------------------------------------
*/

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// C:\123\backend\src\server.js
// C:\123\web\index.html
const webPath = path.resolve(__dirname, "../../web");

const frontendOrigin =
  process.env.FRONTEND_ORIGIN || "http://localhost:5000";

const cookieName =
  process.env.CUSTOMER_SESSION_COOKIE ||
  "hasani_customer_sid";

/*
|--------------------------------------------------------------------------
| CORS
|--------------------------------------------------------------------------
*/

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow PowerShell, curl and direct server requests
      if (!origin) {
        return callback(null, true);
      }

      const allowed =
        origin === "http://localhost:5000" ||
        origin === "http://127.0.0.1:5000" ||
        origin === "http://localhost:5500" ||
        origin === "http://127.0.0.1:5500" ||
        origin === frontendOrigin ||
        /^http:\/\/192\.168\.0\.\d{1,3}(:\d+)?$/.test(origin);

      if (allowed) {
        return callback(null, true);
      }

      console.log(
        "CORS blocked this frontend origin:",
        origin
      );

      return callback(
        new Error("CORS blocked this frontend origin.")
      );
    },

    credentials: true
  })
);

/*
|--------------------------------------------------------------------------
| BASIC MIDDLEWARE
|--------------------------------------------------------------------------
*/

app.use(express.json({ limit: "1mb" }));

/*
|--------------------------------------------------------------------------
| SESSION
|--------------------------------------------------------------------------
*/

app.use(
  session({
    name: cookieName,

    secret:
      process.env.CUSTOMER_SESSION_SECRET ||
      "CHANGE_THIS_TO_A_LONG_RANDOM_SECRET",

    resave: false,

    saveUninitialized: false,

    rolling: true,

    cookie: {
      httpOnly: true,

      sameSite:
        process.env.COOKIE_SAMESITE || "lax",

      // HTTP LAN deployment
      secure: false,

      path: "/",

      maxAge: Number(
        process.env.CUSTOMER_SESSION_MAX_AGE_MS ||
        28800000
      )
    }
  })
);

/*
|--------------------------------------------------------------------------
| REQUEST LOGGING
|--------------------------------------------------------------------------
*/

app.use((req, _res, next) => {
  console.log(
    `[${new Date().toISOString()}] ` +
      `${req.method} ${req.originalUrl} ` +
      `from ${req.headers.origin || "no-origin"}`
  );

  next();
});

/*
|--------------------------------------------------------------------------
| CUSTOMER CONFIGURATION
|--------------------------------------------------------------------------
*/

const CUSTOMER_PASSWORD =
  process.env.CUSTOMER_PASSWORD || "123123";

/*
|--------------------------------------------------------------------------
| SESSION HELPERS
|--------------------------------------------------------------------------
*/

const requireCustomer = (req, res, next) => {
  if (!req.session?.customer) {
    return res.status(401).json({
      ok: false,
      error:
        "Customer session expired. Please log in again."
    });
  }

  next();
};

const saveSession = (req) =>
  new Promise((resolve, reject) => {
    req.session.save((error) => {
      if (error) {
        reject(error);
      } else {
        resolve();
      }
    });
  });

const destroySession = (req) =>
  new Promise((resolve, reject) => {
    if (!req.session) {
      return resolve();
    }

    req.session.destroy((error) => {
      if (error) {
        reject(error);
      } else {
        resolve();
      }
    });
  });

/*
|--------------------------------------------------------------------------
| PERSONAL INFORMATION
|--------------------------------------------------------------------------
*/

function personal(live, member) {
  member = member || {};

  const arms =
    live?.personalInformation ||
    {};

  return {
    cardNo:
      arms.cardNo ||
      live?.membership ||
      member.membership_number ||
      null,

    nric:
      arms.nric ||
      member.nric ||
      null,

    fullName:
      arms.fullName ||
      live?.name ||
      member.name ||
      null,

    name:
      arms.name ||
      live?.name ||
      member.name ||
      null,

    title:
      arms.title ||
      member.title ||
      null,

    membershipType:
      arms.membershipType ||
      live?.memberType ||
      member.member_type ||
      null,

    memberType:
      arms.memberType ||
      live?.memberType ||
      member.member_type ||
      null,

    gender:
      arms.gender ||
      live?.gender ||
      member.gender ||
      null,

    dob:
      arms.dob ||
      live?.birthday ||
      member.birthday ||
      null,

    birthday:
      arms.birthday ||
      live?.birthday ||
      member.birthday ||
      null,

    race:
      arms.race ||
      member.race ||
      null,

    nationality:
      arms.nationality ||
      member.nationality ||
      member.national ||
      null,

    applyBranch:
      arms.applyBranch ||
      member.applyBranch ||
      member.apply_branch ||
      null,

    issueBranch:
      arms.issueBranch ||
      live?.issueBranch ||
      member.issueBranch ||
      member.issue_branch ||
      null,

    issueDate:
      arms.issueDate ||
      live?.issueDate ||
      member.issueDate ||
      member.issue_date ||
      null,

    expiryDate:
      arms.expiryDate ||
      live?.expiryDate ||
      member.expiryDate ||
      member.expiry_date ||
      null,

    lastRenewBranch:
      arms.lastRenewBranch ||
      member.lastRenewBranch ||
      member.last_renew_branch ||
      null,

    lastPurchaseBranch:
      arms.lastPurchaseBranch ||
      member.lastPurchaseBranch ||
      member.last_purchase_branch ||
      null,

    terminatedDate:
      arms.terminatedDate ||
      member.terminatedDate ||
      member.terminated_date ||
      null,

    blockedDate:
      arms.blockedDate ||
      member.blockedDate ||
      member.blocked_date ||
      null,

    verifiedBy:
      arms.verifiedBy ||
      member.verifiedBy ||
      member.verified_by ||
      null,

    points:
      Number(
        arms.points ??
        live?.points ??
        member.points ??
        0
      ),

    pointsUpdate:
      arms.pointsUpdate ||
      live?.pointsUpdate ||
      member.pointsUpdate ||
      member.points_update ||
      null
  };
}

/*
|--------------------------------------------------------------------------
| HEALTH
|--------------------------------------------------------------------------
*/

app.get("/health", (_req, res) => {
  res.json({
    ok: true,

    service:
      "hasani-arms-customer-api",

    version:
      "7.3.2",

    port,

    armsConfigured:
      Boolean(
        process.env.ARMS_USERNAME &&
        process.env.ARMS_PASSWORD
      ),

    armsBaseUrl:
      process.env.ARMS_BASE_URL ||
      "https://hasani.arms.com.my",

    historyConfigured:
      Boolean(
        process.env.ARMS_HISTORY_URL_TEMPLATE
      )
  });
});

/*
|--------------------------------------------------------------------------
| API TEST
|--------------------------------------------------------------------------
*/

app.get("/api/test", (_req, res) => {
  res.json({
    ok: true,

    service:
      "hasani-arms-customer-api",

    version:
      "7.3.2",

    message:
      "Hasani ARMS backend is reachable from this network."
  });
});

/*
|--------------------------------------------------------------------------
| CUSTOMER LOGIN
|--------------------------------------------------------------------------
*/

app.post(
  "/api/customer/login",
  async (req, res) => {

    const membership =
      String(
        req.body?.membership || ""
      ).trim();

    const password =
      String(
        req.body?.password || ""
      );

    if (!membership || !password) {
      return res.status(400).json({
        ok: false,

        error:
          "Membership card number and password are required."
      });
    }

    if (password !== CUSTOMER_PASSWORD) {
      return res.status(401).json({
        ok: false,

        error:
          "Invalid membership number or password."
      });
    }

    try {

      const live =
        await getCustomerProfileFromArms(
          membership
        );

      if (!live?.name) {
        throw Object.assign(
          new Error(
            "ARMS returned the member page, but the member name could not be parsed."
          ),
          {
            code:
              "ARMS_CUSTOMER_NAME_MISSING"
          }
        );
      }

      const history =
        await getMembershipHistory(
          membership
        );

      const info =
        personal(
          live,
          history?.member
        );

      req.session.customer = {

        membership:
          live.membership ||
          membership,

        name:
          live.name,

        points:
          Number(
            live.points || 0
          ),

        pointsBalance:
          Number(
            live.pointsBalance ??
            live.points ??
            0
          ),

        pointsEarned:
          Number(
            live.pointsEarned || 0
          ),

        pointsUpdate:
          live.pointsUpdate ||
          null,

        issueBranch:
          live.issueBranch ||
          null,

        issueDate:
          live.issueDate ||
          null,

        expiryDate:
          live.expiryDate ||
          null,

        memberType:
          live.memberType ||
          null,

        gender:
          live.gender ||
          null,

        birthday:
          live.birthday ||
          null,

        personalInformation:
          info
      };

      req.session.armsVerifiedAt =
        Date.now();

      await saveSession(req);

      res.json({
        ok: true,

        authenticated: true,

        customer:
          req.session.customer,

        arms: {
          authenticated: true,

          historyConfigured:
            Boolean(
              live.historyConfigured ??
              process.env
                .ARMS_HISTORY_URL_TEMPLATE
            )
        }
      });

    } catch (error) {

      console.error(
        "[CUSTOMER LOGIN] ARMS verification failed:",
        error
      );

      if (
        error?.code ===
          "ARMS_MEMBER_NOT_FOUND" ||
        error?.code ===
          "MEMBERSHIP_NOT_FOUND"
      ) {
        return res.status(401).json({
          ok: false,

          authenticated: false,

          error:
            "Membership card number was not found in ARMS."
        });
      }

      if (
        error?.code ===
        "ARMS_SESSION_EXPIRED"
      ) {
        return res.status(502).json({
          ok: false,

          authenticated: false,

          error:
            "ARMS session expired while checking the membership. Please try again."
        });
      }

      return res.status(502).json({
        ok: false,

        authenticated: false,

        error:
          "ARMS authentication/verification failed: " +
          (
            error?.message ||
            "Unknown ARMS error"
          )
      });
    }
  }
);

/*
|--------------------------------------------------------------------------
| CURRENT CUSTOMER
|--------------------------------------------------------------------------
*/

app.get(
  "/api/customer/me",
  requireCustomer,
  (req, res) => {

    res.json({
      ok: true,

      authenticated: true,

      customer:
        req.session.customer
    });
  }
);

/*
|--------------------------------------------------------------------------
| PERSONAL INFORMATION
|--------------------------------------------------------------------------
*/

app.get(
  "/api/customer/personal-information",
  requireCustomer,
  async (req, res) => {

    try {

      const history =
        await getMembershipHistory(
          req.session.customer.membership
        );

      const info =
        personal(
          req.session.customer,
          history?.member
        );

      req.session.customer.personalInformation =
        info;

      await saveSession(req);

      res.json({
        ok: true,

        source: "ARMS",

        personalInformation:
          info
      });

    } catch (error) {

      console.error(
        "[PERSONAL INFORMATION]",
        error
      );

      res.status(502).json({
        ok: false,

        error:
          error?.message ||
          "Unable to load ARMS personal information."
      });
    }
  }
);

/*
|--------------------------------------------------------------------------
| DASHBOARD
|--------------------------------------------------------------------------
*/

app.get(
  "/api/customer/dashboard",
  requireCustomer,
  (req, res) => {

    const customer =
      req.session.customer;

    res.json({

      ok: true,

      source: "ARMS",

      customer: {

        membership:
          customer.membership,

        name:
          customer.name,

        points:
          customer.points,

        pointsBalance:
          customer.pointsBalance,

        pointsEarned:
          customer.pointsEarned
      },

      purchases: [],

      rewards: [],

      offers: [],

      locations: []
    });
  }
);

/*
|--------------------------------------------------------------------------
| PURCHASE HISTORY
|--------------------------------------------------------------------------
*/

app.get(
  "/api/customer/purchases",
  requireCustomer,
  async (req, res) => {

    try {

      const history =
        await getMembershipHistory(
          req.session.customer.membership
        );

      res.json({
        ok: true,

        source: "ARMS",

        ...history
      });

    } catch (error) {

      console.error(
        "[PURCHASE HISTORY]",
        error
      );

      res.status(502).json({
        ok: false,

        error:
          error?.message ||
          "Unable to load ARMS purchase history."
      });
    }
  }
);

/*
|--------------------------------------------------------------------------
| CARD VISUALS
|--------------------------------------------------------------------------
*/

app.get(
  "/api/customer/card-visuals",
  requireCustomer,
  async (req, res) => {

    try {

      const membership =
        req.session.customer.membership;

      const qr =
        await QRCode.toDataURL(
          "HASANI-MEMBER:" +
            membership,
          {
            margin: 1,
            width: 260
          }
        );

      const png =
        await bwipjs.toBuffer({

          bcid:
            "code128",

          text:
            membership,

          scale:
            3,

          height:
            12,

          includetext:
            true,

          textxalign:
            "center"
        });

      res.json({

        ok: true,

        qrDataUrl:
          qr,

        barcodeDataUrl:
          "data:image/png;base64," +
          png.toString("base64")
      });

    } catch (error) {

      res.status(500).json({

        ok: false,

        error:
          error?.message ||
          "Unable to create membership card visuals."
      });
    }
  }
);

/*
|--------------------------------------------------------------------------
| LOGOUT
|--------------------------------------------------------------------------
*/

app.post(
  "/api/customer/logout",
  requireCustomer,
  async (req, res) => {

    try {

      await destroySession(req);

    } catch {
      // Session may already be destroyed.
    }

    res.clearCookie(
      cookieName,
      {
        httpOnly: true,

        sameSite:
          process.env.COOKIE_SAMESITE ||
          "lax",

        secure: false,

        path: "/"
      }
    );

    res.json({
      ok: true,

      loggedOut: true
    });
  }
);

/*
|--------------------------------------------------------------------------
| SERVE FRONTEND
|--------------------------------------------------------------------------
|
| C:\123\web\index.html
|
| /web/index.html
|     -> C:\123\web\index.html
|
*/

app.use(
  "/web",
  express.static(webPath)
);

/*
|--------------------------------------------------------------------------
| ROOT FRONTEND
|--------------------------------------------------------------------------
|
| http://192.168.0.59:5000
|     -> C:\123\web\index.html
|
*/

app.get(
  "/",
  (_req, res) => {

    res.sendFile(
      path.join(
        webPath,
        "index.html"
      )
    );
  }
);

/*
|--------------------------------------------------------------------------
| 404
|--------------------------------------------------------------------------
*/

app.use(
  (req, res) => {

    res.status(404).json({

      ok: false,

      error:
        "API endpoint not found.",

      method:
        req.method,

      path:
        req.originalUrl
    });
  }
);

/*
|--------------------------------------------------------------------------
| START SERVER
|--------------------------------------------------------------------------
*/

app.listen(
  port,
  "0.0.0.0",
  () => {

    console.log("");
    console.log(
      "=================================================="
    );

    console.log(
      " Hasani ARMS Customer API 7.3.3"
    );

    console.log(
      "=================================================="
    );

    console.log(
      ` Local:    http://localhost:${port}`
    );

    console.log(
      ` LAN:      http://192.168.0.59:${port}`
    );

    console.log(
      ` Health:   http://192.168.0.59:${port}/health`
    );

    console.log(
      ` Test:     http://192.168.0.59:${port}/api/test`
    );

    console.log(
      ` Frontend: http://192.168.0.59:${port}/`
    );

    console.log(
      "=================================================="
    );

    console.log("");
  }
);