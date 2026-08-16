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
  getCustomerProfileFromArms,
  getTransactionDetail
} from "./arms.js";

const app = express();

/*
|--------------------------------------------------------------------------
| PORT
|--------------------------------------------------------------------------
*/

const port = Number(process.env.PORT || 5000);

/*
|--------------------------------------------------------------------------
| PATHS
|--------------------------------------------------------------------------
*/

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const webPath = path.resolve(__dirname, "../../web");

/*
|--------------------------------------------------------------------------
| CONFIGURATION
|--------------------------------------------------------------------------
*/

const cookieName =
  process.env.CUSTOMER_SESSION_COOKIE ||
  "hasani_customer_sid";

const CUSTOMER_PASSWORD =
  process.env.CUSTOMER_PASSWORD || "123123";

const SESSION_SECRET =
  process.env.CUSTOMER_SESSION_SECRET ||
  "HASANI_CUSTOMER_SESSION_SECRET_CHANGE_ME_2026";

/*
|--------------------------------------------------------------------------
| RENDER / PROXY
|--------------------------------------------------------------------------
|
| Render sits behind a reverse proxy.
|
*/

app.set("trust proxy", 1);

/*
|--------------------------------------------------------------------------
| CORS
|--------------------------------------------------------------------------
*/

app.use(
  cors({
    origin: true,
    credentials: true
  })
);

/*
|--------------------------------------------------------------------------
| BODY PARSER
|--------------------------------------------------------------------------
*/

app.use(
  express.json({
    limit: "2mb"
  })
);

/*
|--------------------------------------------------------------------------
| SESSION
|--------------------------------------------------------------------------
*/

const sessionMiddleware = session({
  name: cookieName,

  secret: SESSION_SECRET,

  resave: false,

  saveUninitialized: false,

  rolling: true,

  cookie: {
    httpOnly: true,

    secure:
      process.env.NODE_ENV === "production",

    sameSite:
      process.env.COOKIE_SAMESITE || "lax",

    path: "/",

    maxAge: Number(
      process.env.CUSTOMER_SESSION_MAX_AGE_MS ||
        8 * 60 * 60 * 1000
    )
  }
});

/*
|--------------------------------------------------------------------------
| APPLY SESSION
|--------------------------------------------------------------------------
*/

app.use(sessionMiddleware);

/*
|--------------------------------------------------------------------------
| SESSION SAFETY MIDDLEWARE
|--------------------------------------------------------------------------
|
| This prevents:
|
| Cannot set properties of undefined
| (setting 'customer')
|
*/

app.use((req, res, next) => {
  if (!req.session) {
    console.error(
      "[SESSION] Express session was not created."
    );

    return res.status(500).json({
      ok: false,
      error:
        "Customer session service is unavailable."
    });
  }

  next();
});

/*
|--------------------------------------------------------------------------
| REQUEST LOGGING
|--------------------------------------------------------------------------
*/

app.use((req, _res, next) => {
  console.log(
    `[${new Date().toISOString()}] ` +
      `${req.method} ${req.originalUrl} ` +
      `origin=${req.headers.origin || "none"} ` +
      `session=${req.sessionID || "none"}`
  );

  next();
});

/*
|--------------------------------------------------------------------------
| SESSION HELPERS
|--------------------------------------------------------------------------
*/

const requireCustomer = (req, res, next) => {
  if (
    !req.session ||
    !req.session.customer
  ) {
    return res.status(401).json({
      ok: false,
      authenticated: false,
      error:
        "Customer session expired. Please log in again."
    });
  }

  next();
};

const saveSession = (req) =>
  new Promise((resolve, reject) => {
    if (!req.session) {
      return reject(
        new Error(
          "Express customer session is unavailable."
        )
      );
    }

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
| PERSONAL INFORMATION HELPERS
|--------------------------------------------------------------------------
*/

function cleanDisplayName(value) {
  let name = String(value || "").trim();

  if (
    !name ||
    /^(?:arms\s+customer|customer|member)$/i.test(
      name
    )
  ) {
    return null;
  }

  name = name
    .replace(
      /^\s*(?:mr|mrs|ms|miss|dr)\.?\s*/i,
      ""
    )
    .replace(
      /^\s*(?:kb|kg)\s*:\s*/i,
      ""
    )
    .replace(
      /^\s*(?:kb|kg)\s+/i,
      ""
    )
    .replace(/^\s*:\s*/, "")
    .replace(/\s+/g, " ")
    .trim();

  return name || null;
}

function firstRealName(...values) {
  for (const value of values) {
    const cleaned =
      cleanDisplayName(value);

    if (cleaned) {
      return cleaned;
    }
  }

  return null;
}

function firstValue(...values) {
  for (const value of values) {
    const text =
      String(value || "").trim();

    if (text) {
      return text;
    }
  }

  return null;
}

function personal(live, member) {
  member = member || {};

  const arms =
    live?.personalInformation || {};

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
      firstRealName(
        arms.fullName,
        arms.name,
        live?.name,
        member.name,
        member.fullName,
        member.full_name
      ),

    name:
      firstRealName(
        arms.name,
        arms.fullName,
        live?.name,
        member.name,
        member.fullName,
        member.full_name
      ),

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
      firstValue(
        arms.issueBranch,
        live?.issueBranch,
        arms.applyBranch,
        member.issueBranch,
        member.issue_branch,
        member.applyBranch,
        member.apply_branch
      ),

    issueDate:
      arms.issueDate ||
      live?.issueDate ||
      member.issueDate ||
      member.issue_date ||
      null,

    expiryDate:
      firstValue(
        arms.expiryDate,
        live?.expiryDate,
        member.expiryDate,
        member.expiry_date,
        member.nextExpiryDate,
        member.next_expiry_date
      ),

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

    points: Number(
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

    version: "7.5.0",

    port,

    environment:
      process.env.NODE_ENV ||
      "development",

    sessionMiddleware: true,

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

    version: "7.5.0",

    message:
      "Hasani ARMS backend is reachable."
  });
});

/*
|--------------------------------------------------------------------------
| SESSION TEST
|--------------------------------------------------------------------------
*/

app.get("/api/session-test", (req, res) => {
  res.json({
    ok: true,

    sessionAvailable:
      Boolean(req.session),

    sessionId:
      req.sessionID || null,

    authenticated:
      Boolean(req.session?.customer)
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

        authenticated: false,

        error:
          "Membership card number and password are required."
      });
    }

    if (password !== CUSTOMER_PASSWORD) {
      return res.status(401).json({
        ok: false,

        authenticated: false,

        error:
          "Invalid membership number or password."
      });
    }

    /*
     * Make absolutely sure Express session exists.
     */

    if (!req.session) {
      console.error(
        "[CUSTOMER LOGIN] req.session is undefined."
      );

      return res.status(500).json({
        ok: false,

        authenticated: false,

        error:
          "Customer session service is unavailable."
      });
    }

    try {
      console.log(
        `[CUSTOMER LOGIN] Verifying membership ${membership}`
      );

      /*
       * Verify membership against ARMS.
       */

      const live =
        await getCustomerProfileFromArms(
          membership
        );

      console.log(
        "[CUSTOMER LOGIN] ARMS profile received."
      );

      const history =
        await getMembershipHistory(
          membership
        );

      console.log(
        "[CUSTOMER LOGIN] ARMS history received."
      );

      const verifiedName =
        firstRealName(
          history?.name,

          history
            ?.personalInformation
            ?.fullName,

          history
            ?.personalInformation
            ?.name,

          history
            ?.member
            ?.fullName,

          history
            ?.member
            ?.full_name,

          history
            ?.member
            ?.name,

          live
            ?.personalInformation
            ?.fullName,

          live
            ?.personalInformation
            ?.name,

          live?.name
        );

      const liveExpiry =
        String(
          live?.expiryDate || ""
        ).trim();

      const historyExpiry =
        String(
          history?.expiryDate ||
            history?.member?.expiryDate ||
            history?.member?.expiry_date ||
            ""
        ).trim();

      const verifiedExpiry =
        firstValue(
          historyExpiry,

          liveExpiry,

          history
            ?.personalInformation
            ?.expiryDate,

          history
            ?.member
            ?.expiryDate,

          history
            ?.member
            ?.expiry_date
        );

      if (!verifiedName) {
        throw Object.assign(
          new Error(
            "ARMS verified the membership, but a customer name was not returned."
          ),
          {
            code:
              "ARMS_CUSTOMER_NAME_MISSING"
          }
        );
      }

      const profileForPersonal = {
        ...live,

        name:
          verifiedName,

        expiryDate:
          verifiedExpiry
      };

      const info =
        personal(
          profileForPersonal,
          history?.member
        );

      /*
       * IMPORTANT:
       *
       * Set the session only AFTER all ARMS
       * verification has succeeded.
       */

      req.session.customer = {
        membership:
          live?.membership ||
          history?.membership ||
          membership,

        name:
          verifiedName,

        points:
          Number(
            live?.points || 0
          ),

        pointsBalance:
          Number(
            live?.pointsBalance ??
              live?.points ??
              0
          ),

        pointsEarned:
          Number(
            live?.pointsEarned || 0
          ),

        pointsUpdate:
          live?.pointsUpdate ||
          null,

        issueBranch:
          firstValue(
            history?.issueBranch,

            history
              ?.personalInformation
              ?.issueBranch,

            history
              ?.personalInformation
              ?.applyBranch,

            live?.issueBranch,

            live
              ?.personalInformation
              ?.issueBranch,

            live
              ?.personalInformation
              ?.applyBranch
          ),

        issueDate:
          live?.issueDate ||
          null,

        expiryDate:
          verifiedExpiry,

        memberType:
          live?.memberType ||
          null,

        gender:
          live?.gender ||
          null,

        birthday:
          live?.birthday ||
          null,

        personalInformation:
          info
      };

      req.session.armsVerifiedAt =
        Date.now();

      /*
       * Explicitly save session.
       */

      await saveSession(req);

      console.log(
        "[CUSTOMER LOGIN] Session saved successfully:",
        req.sessionID
      );

      return res.json({
        ok: true,

        authenticated: true,

        customer:
          req.session.customer,

        session: {
          active: true,

          sessionId:
            req.sessionID
        },

        arms: {
          authenticated: true,

          historyConfigured:
            Boolean(
              live?.historyConfigured ??
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
| PURCHASE DETAIL
|--------------------------------------------------------------------------
*/

app.post(
  "/api/customer/purchase-detail",
  requireCustomer,
  async (req, res) => {
    try {
      const requestedPurchase =
        req.body?.purchase ||
        null;

      let transaction =
        req.body?.transaction ||
        requestedPurchase
          ?.transaction_detail ||
        requestedPurchase
          ?.transactionDetail ||
        null;

      const existingDetail =
        requestedPurchase?.detail ||
        requestedPurchase
          ?.transactionDetailData ||
        null;

      if (
        existingDetail &&
        Array.isArray(
          existingDetail.items
        ) &&
        existingDetail.items.length
      ) {
        return res.json({
          ok: true,

          source: "ARMS",

          detail:
            existingDetail
        });
      }

      if (!transaction) {
        const membership =
          req.session.customer.membership;

        const history =
          await getMembershipHistory(
            membership
          );

        const purchases =
          Array.isArray(
            history?.purchases
          )
            ? history.purchases
            : [];

        const requestedReceipt =
          String(
            requestedPurchase?.receiptNo ??
              requestedPurchase
                ?.receipt_no ??
              ""
          ).trim();

        const requestedReference =
          String(
            requestedPurchase
              ?.receiptRefNo ??
              requestedPurchase
                ?.receipt_ref_no ??
              ""
          ).trim();

        const requestedDate =
          String(
            requestedPurchase?.date ??
              requestedPurchase
                ?.transaction_time ??
              ""
          ).trim();

        const exact =
          purchases.find(
            function (item) {
              const receipt =
                String(
                  item?.receiptNo ??
                    item?.receipt_no ??
                    ""
                ).trim();

              const reference =
                String(
                  item?.receiptRefNo ??
                    item?.receipt_ref_no ??
                    ""
                ).trim();

              const date =
                String(
                  item?.date ??
                    item?.transaction_time ??
                    ""
                ).trim();

              if (
                requestedReceipt &&
                receipt === requestedReceipt
              ) {
                return true;
              }

              if (
                requestedReference &&
                reference === requestedReference
              ) {
                return true;
              }

              return Boolean(
                requestedDate &&
                  date === requestedDate
              );
            }
          );

        if (
          exact?.detail?.items?.length
        ) {
          return res.json({
            ok: true,

            source: "ARMS",

            detail:
              exact.detail
          });
        }

        transaction =
          exact?.transaction_detail ||
          exact?.transactionDetail ||
          null;
      }

      const required = [
        "branch_id",
        "counter_id",
        "pos_id",
        "cashier_id",
        "date"
      ];

      const missing =
        required.filter(
          function (field) {
            return (
              transaction?.[field] ===
                undefined ||
              transaction?.[field] ===
                null ||
              String(
                transaction[field]
              ).trim() === ""
            );
          }
        );

      if (missing.length) {
        return res.status(422).json({
          ok: false,

          code:
            "TRANSACTION_FIELDS_MISSING",

          error:
            "ARMS did not return enough transaction-detail information for this receipt yet.",

          missing
        });
      }

      const detail =
        await getTransactionDetail(
          transaction
        );

      return res.json({
        ok: true,

        source: "ARMS",

        detail
      });
    } catch (error) {
      console.error(
        "[PURCHASE DETAIL]",
        error
      );

      return res.status(502).json({
        ok: false,

        code:
          error?.code ||
          "ARMS_TRANSACTION_DETAIL_ERROR",

        error:
          error?.message ||
          "Unable to load item-level purchase details from ARMS."
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
          bcid: "code128",

          text: membership,

          scale: 3,

          height: 12,

          includetext: true,

          textxalign: "center"
        });

      res.json({
        ok: true,

        qrDataUrl: qr,

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
    } catch (error) {
      console.error(
        "[LOGOUT]",
        error
      );
    }

    res.clearCookie(
      cookieName,
      {
        httpOnly: true,

        sameSite:
          process.env.COOKIE_SAMESITE ||
          "lax",

        secure:
          process.env.NODE_ENV ===
          "production",

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
| STATIC FRONTEND
|--------------------------------------------------------------------------
*/

app.use(
  "/web",
  express.static(webPath)
);

/*
|--------------------------------------------------------------------------
| ROOT
|--------------------------------------------------------------------------
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
| ERROR HANDLER
|--------------------------------------------------------------------------
*/

app.use(
  (error, req, res, _next) => {
    console.error(
      "[EXPRESS ERROR]",
      error
    );

    res.status(500).json({
      ok: false,

      error:
        error?.message ||
        "Internal server error."
    });
  }
);

/*
|--------------------------------------------------------------------------
| START
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
      " Hasani ARMS Customer API 7.5.0"
    );

    console.log(
      "=================================================="
    );

    console.log(
      ` Port: ${port}`
    );

    console.log(
      ` Environment: ${
        process.env.NODE_ENV ||
        "development"
      }`
    );

    console.log(
      ` Session cookie: ${cookieName}`
    );

    console.log(
      " Health: /health"
    );

    console.log(
      " API Test: /api/test"
    );

    console.log(
      " Session Test: /api/session-test"
    );

    console.log(
      "=================================================="
    );

    console.log("");
  }
);
