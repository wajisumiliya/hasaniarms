
/*
 * HASANI CUSTOMER WEB APP
 *
 * File:
 * C:\123\web\js\app.js
 *
 * Backend:
 * http://localhost:5000
 *
 * This file:
 * - Logs customer in through Node backend
 * - Sends/receives customer session cookie
 * - Verifies /api/customer/me
 * - Loads ARMS dashboard information
 * - Loads QR/barcode
 * - Shows purchase history
 * - Shows points
 * - Handles logout
 */


/* ==========================================================================
   CONFIGURATION
   ========================================================================== */

const API = (
  new URLSearchParams(window.location.search).get("api") ||
  `${window.location.protocol}//${window.location.hostname}:5000`
).replace(/\/$/, "");

/* ==========================================================================
   APPLICATION STATE
   ========================================================================== */

const state = {
  customer: null,
  dashboard: null,
  authenticated: false
};


/* ==========================================================================
   DOM HELPERS
   ========================================================================== */

function $(id) {
  return document.getElementById(id);
}


function esc(value) {
  return String(value ?? "").replace(
    /[&<>"']/g,
    function (character) {
      if (character === "&") return "&amp;";
      if (character === "<") return "&lt;";
      if (character === ">") return "&gt;";
      if (character === '"') return "&quot;";
      if (character === "'") return "&#39;";
      return character;
    }
  );
}


/* ==========================================================================
   SESSION STATE
   ========================================================================== */

function clearState() {
  state.customer = null;
  state.dashboard = null;
  state.authenticated = false;
}


function showLogin(message) {
  clearState();

  const loginPage = $("loginPage");
  const appShell = $("appShell");

  if (loginPage) {
    loginPage.classList.remove("hidden");
  }

  if (appShell) {
    appShell.classList.add("hidden");
  }

  if ($("loginMessage")) {
    $("loginMessage").textContent = message || "";
  }
}


function showApp() {
  const loginPage = $("loginPage");
  const appShell = $("appShell");

  if (loginPage) {
    loginPage.classList.add("hidden");
  }

  if (appShell) {
    appShell.classList.remove("hidden");
  }
}


/* ==========================================================================
   API REQUEST
   ========================================================================== */

async function request(path, options) {
  const config = options || {};

  const fetchOptions = {
    method: config.method || "GET",
    credentials: "include"
  };


  /*
   * Copy additional options.
   */
  if (config.body !== undefined) {
    fetchOptions.body = config.body;
  }


  if (config.headers) {
    fetchOptions.headers = {
      ...config.headers
    };
  } else {
    fetchOptions.headers = {};
  }


  /*
   * JSON body.
   */
  if (
    config.body !== undefined &&
    config.body !== null &&
    typeof config.body === "string"
  ) {
    fetchOptions.headers["Content-Type"] =
      "application/json";
  }


  let response;

  try {
    response = await fetch(
      API + path,
      fetchOptions
    );
  } catch (error) {
    throw new Error(
      "Cannot reach backend at " +
      API +
      ". Start Node on port 5000."
    );
  }


  const text =
    await response.text();


  let data = {};


  if (text) {
    try {
      data = JSON.parse(text);
    } catch (error) {
      data = {
        raw: text
      };
    }
  }


  /*
   * Customer session expired.
   */
  if (
    response.status === 401 &&
    path !== "/api/customer/login"
  ) {
    const error =
      new Error(
        "Customer session expired. Please log in again."
      );

    error.code =
      "CUSTOMER_SESSION_EXPIRED";

    error.status = 401;

    showLogin(
      "Customer session expired. Please log in again."
    );

    throw error;
  }


  /*
   * Backend error.
   */
  if (!response.ok) {
    const message =
      data && data.error
        ? data.error
        : "HTTP " + response.status;

    const error =
      new Error(message);

    error.status =
      response.status;

    error.code =
      data && data.code
        ? data.code
        : null;

    throw error;
  }


  return data;
}


/* ==========================================================================
   NAVIGATION
   ========================================================================== */

function showView(view) {
  document
    .querySelectorAll(".view")
    .forEach(function (element) {
      element.classList.add("hidden");
    });


  const target =
    $("view-" + view);


  if (target) {
    target.classList.remove("hidden");
  }


  document
    .querySelectorAll(".nav-item")
    .forEach(function (element) {
      element.classList.toggle(
        "active",
        element.dataset.view === view
      );
    });


  const titles = {
    dashboard: "Dashboard",
    purchases: "Purchase History",
    points: "Member Points",
    rewards: "Rewards",
    offers: "Offers",
    store: "Online Store",
    locations: "Locations"
  };


  if ($("pageTitle")) {
    $("pageTitle").textContent =
      titles[view] || "Dashboard";
  }


  if ($("sidebar")) {
    $("sidebar").classList.remove("open");
  }


  window.scrollTo({
    top: 0,
    behavior: "smooth"
  });
}


function setupNavigation() {
  document
    .querySelectorAll("[data-view]")
    .forEach(function (element) {
      element.addEventListener(
        "click",
        function () {
          const view =
            element.dataset.view;

          showView(view);

          if (
            view === "purchases" &&
            !(state.dashboard?.purchases || []).length
          ) {
            loadPurchaseHistory();
          }
        }
      );
    });


  if ($("menuBtn")) {
    $("menuBtn").addEventListener(
      "click",
      function () {
        if ($("sidebar")) {
          $("sidebar").classList.toggle(
            "open"
          );
        }
      }
    );
  }


  if ($("logoutBtn")) {
    $("logoutBtn").addEventListener(
      "click",
      logout
    );
  }
}


/* ==========================================================================
   LOGOUT
   ========================================================================== */

async function logout() {
  try {
    await request(
      "/api/customer/logout",
      {
        method: "POST"
      }
    );
  } catch (error) {
    /*
     * Even if the server session is already gone,
     * clear the browser application state.
     */
  }


  clearState();

  showLogin("");

  if ($("loginPassword")) {
    $("loginPassword").value =
      "123123";
  }
}


/* ==========================================================================
   QR / BARCODE
   ========================================================================== */

async function loadCardVisuals() {
  const data =
    await request(
      "/api/customer/card-visuals"
    );


  if (
    data.qrDataUrl &&
    $("qrImg")
  ) {
    $("qrImg").src =
      data.qrDataUrl;
  }


  if (
    data.barcodeDataUrl &&
    $("barcodeImg")
  ) {
    $("barcodeImg").src =
      data.barcodeDataUrl;
  }
}


/* ==========================================================================
   CUSTOMER DISPLAY
   ========================================================================== */

function renderCustomer() {
  const customer =
    state.customer;


  if (!customer) {
    return;
  }


  const name =
    customer.name ||
    "ARMS Customer";


  const membership =
    customer.membership ||
    customer.membership_number ||
    "";


  const points =
    Number(
      customer.points ??
      customer.pointsBalance ??
      0
    );


  const initials =
    name
      .trim()
      .split(/\s+/)
      .filter(Boolean)
      .map(function (part) {
        return part.charAt(0);
      })
      .join("")
      .slice(0, 2)
      .toUpperCase();


  [
    "sideName",
    "cardName",
    "welcomeName"
  ].forEach(function (id) {
    if ($(id)) {
      $(id).textContent =
        name;
    }
  });


  [
    "sideMember",
    "cardMember"
  ].forEach(function (id) {
    if ($(id)) {
      $(id).textContent =
        membership;
    }
  });


  if ($("sideAvatar")) {
    $("sideAvatar").textContent =
      initials || "A";
  }


  if ($("topAvatar")) {
    $("topAvatar").textContent =
      initials || "A";
  }


  if ($("dashPoints")) {
    $("dashPoints").textContent =
      points;
  }


  if ($("pointsBig")) {
    $("pointsBig").textContent =
      points;
  }


  if ($("pointsEarned")) {
    $("pointsEarned").textContent =
      points;
  }
}


/* ==========================================================================
   PURCHASE HELPERS
   ========================================================================== */

function purchaseReceipt(purchase) {
  return (
    purchase.receiptNo ??
    purchase.receipt_no ??
    "-"
  );
}


function purchaseDate(purchase) {
  return (
    purchase.date ??
    purchase.transaction_time ??
    "-"
  );
}


function purchaseBranch(purchase) {
  return (
    purchase.branch ??
    ""
  );
}


function purchaseCashier(purchase) {
  return (
    purchase.cashier ??
    ""
  );
}


function purchaseReference(purchase) {
  return (
    purchase.receiptRefNo ??
    purchase.receipt_ref_no ??
    ""
  );
}


function purchaseAmount(purchase) {
  const value =
    purchase.total ??
    purchase.payment_amount ??
    0;

  const number =
    Number(value);

  return Number.isFinite(number)
    ? number
    : 0;
}


function purchasePoints(purchase) {
  const value =
    purchase.points ??
    0;

  const number =
    Number(value);

  return Number.isFinite(number)
    ? number
    : 0;
}


/* ==========================================================================
   DASHBOARD
   ========================================================================== */

function renderDashboard() {
  const dashboard = state.dashboard;

  if (!dashboard) {
    return;
  }

  const purchases = Array.isArray(dashboard.purchases)
    ? dashboard.purchases
    : [];

  const totalSpend = purchases.reduce(function (sum, purchase) {
    return sum + purchaseAmount(purchase);
  }, 0);

  if ($("dashSpend")) {
    $("dashSpend").textContent =
      "RM " + totalSpend.toFixed(2);
  }

  if ($("dashTransactions")) {
    $("dashTransactions").textContent =
      String(purchases.length);
  }

  if ($("pointsSpend")) {
    $("pointsSpend").textContent =
      "RM " + totalSpend.toFixed(2);
  }


  /* ============================================================
     PURCHASE HISTORY
     ============================================================ */

  if ($("purchaseList")) {
    if (!purchases.length) {
      $("purchaseList").innerHTML =
        '<div class="empty-feature">' +
          '<h2>No ARMS purchases returned</h2>' +
          '<p>No purchase records were returned for this membership.</p>' +
        '</div>';
    } else {
      $("purchaseList").innerHTML =
        purchases.map(function (purchase) {
          const receipt =
            purchaseReceipt(purchase);

          const date =
            purchaseDate(purchase);

          const branch =
            purchaseBranch(purchase);

          const cashier =
            purchaseCashier(purchase);

          const reference =
            purchaseReference(purchase);

          const amount =
            purchaseAmount(purchase);

          const points =
            purchasePoints(purchase);

          return (
            '<div class="purchase-card">' +

              '<div class="purchase-main">' +

                '<b>Receipt #' +
                  esc(receipt) +
                '</b>' +

                '<span>' +
                  esc(date) +

                  (
                    branch
                      ? ' · ' + esc(branch)
                      : ''
                  ) +

                  (
                    cashier
                      ? ' · Cashier ' + esc(cashier)
                      : ''
                  ) +

                '</span>' +

                (
                  reference
                    ? '<span>Ref: ' +
                      esc(reference) +
                      '</span>'
                    : ''
                ) +

              '</div>' +

              '<div class="purchase-points">' +

                '<strong>RM ' +
                  amount.toFixed(2) +
                '</strong>' +

                '<small>+' +
                  esc(points) +
                  ' points</small>' +

              '</div>' +

            '</div>'
          );
        }).join("");
    }
  }


  /* ============================================================
     POINT HISTORY
     ============================================================ */

  if ($("pointsRows")) {
    if (!purchases.length) {
      $("pointsRows").innerHTML =
        '<div class="empty-feature">' +
          '<p>No point transactions returned by ARMS.</p>' +
        '</div>';
    } else {
      $("pointsRows").innerHTML =
        purchases.map(function (purchase) {
          return (
            '<div class="row">' +

              '<b>' +
                esc(
                  purchaseDate(purchase)
                ) +
              '</b>' +

              '<span>' +
                'RM ' +
                purchaseAmount(purchase).toFixed(2) +
              '</span>' +

              '<span>' +
                '+' +
                esc(
                  purchasePoints(purchase)
                ) +
                ' points' +
              '</span>' +

            '</div>'
          );
        }).join("");
    }
  }


  /* ============================================================
     REWARDS
     ============================================================ */

  const rewards =
    Array.isArray(dashboard.rewards)
      ? dashboard.rewards
      : [];

  if ($("rewardsGrid")) {
    if (!rewards.length) {
      $("rewardsGrid").innerHTML =
        '<div class="empty-feature">' +
          '<h2>Rewards</h2>' +
          '<p>No rewards are currently available.</p>' +
        '</div>';
    } else {
      $("rewardsGrid").innerHTML =
        rewards.map(function (item) {
          return (
            '<div class="feature-card">' +

              '<b>🎁 ' +
                esc(
                  item.title ||
                  "Reward"
                ) +
              '</b>' +

              '<span>' +
                esc(
                  item.description ||
                  ""
                ) +
              '</span>' +

            '</div>'
          );
        }).join("");
    }
  }


  /* ============================================================
     OFFERS
     ============================================================ */

  const offers =
    Array.isArray(dashboard.offers)
      ? dashboard.offers
      : [];

  if ($("offersGrid")) {
    if (!offers.length) {
      $("offersGrid").innerHTML =
        '<div class="empty-feature">' +
          '<h2>Offers</h2>' +
          '<p>No member offers are currently available.</p>' +
        '</div>';
    } else {
      $("offersGrid").innerHTML =
        offers.map(function (item) {
          return (
            '<div class="feature-card">' +

              '<b>🏷 ' +
                esc(
                  item.title ||
                  "Offer"
                ) +
              '</b>' +

              '<span>' +
                esc(
                  item.description ||
                  ""
                ) +
              '</span>' +

            '</div>'
          );
        }).join("");
    }
  }


  /* ============================================================
     ARMS STATUS
     ============================================================ */

  if ($("backendStatus")) {
    $("backendStatus").textContent =
      "ARMS session online";
  }
}
/* ==========================================================================
   LOGIN
   ========================================================================== */

async function loadPurchaseHistory() {
  const list = $("purchaseList");

  if (list) {
    list.innerHTML =
      '<div class="empty-feature">' +
      '<h2>Loading Purchase History…</h2>' +
      '<p>Fetching ARMS purchase history from 2020 onwards.</p>' +
      '</div>';
  }

  try {
    const result = await request(
      "/api/customer/purchases",
      { method: "GET" }
    );

    state.dashboard = state.dashboard || {};
    state.dashboard.purchases = Array.isArray(result.purchases)
      ? result.purchases
      : [];

    if (result.points !== undefined && state.customer) {
      state.customer.points = Number(result.points || 0);
    }

    if (result.pointsEarned !== undefined && state.customer) {
      state.customer.pointsEarned = Number(result.pointsEarned || 0);
    }

    renderCustomer();
    renderDashboard();

    if ($("backendStatus")) {
      $("backendStatus").textContent =
        "ARMS online · " +
        state.dashboard.purchases.length +
        " purchase records loaded";
    }
  } catch (error) {
    console.error(
      "HASANI CUSTOMER APP: PURCHASE HISTORY FAILED",
      error
    );

    if (list) {
      list.innerHTML =
        '<div class="empty-feature">' +
        '<h2>Purchase History</h2>' +
        '<p>Unable to load ARMS purchase history.</p>' +
        '<p>' + esc(error.message) + '</p>' +
        '<button class="primary" type="button" id="retryPurchasesBtn">Retry</button>' +
        '</div>';

      const retry = $("retryPurchasesBtn");
      if (retry) {
        retry.addEventListener("click", loadPurchaseHistory);
      }
    }
  }
}


async function login(event) {
  event.preventDefault();


  console.log(
    "HASANI CUSTOMER APP: LOGIN BUTTON CLICKED"
  );


  const membership =
    $("loginMembership")
      ? $("loginMembership")
          .value
          .trim()
      : "";


  const password =
    $("loginPassword")
      ? $("loginPassword")
          .value
      : "";


  if (!membership) {
    if ($("loginMessage")) {
      $("loginMessage").textContent =
        "Please enter your membership card number.";
    }

    return;
  }


  if (!password) {
    if ($("loginMessage")) {
      $("loginMessage").textContent =
        "Please enter your password.";
    }

    return;
  }


  if ($("loginMessage")) {
    $("loginMessage").textContent =
      "Signing in to ARMS…";
  }


  try {
    /*
     * Step 1:
     * Authenticate membership through Node.
     *
     * Node then logs into ARMS and validates
     * the membership against ARMS.
     */
    const loginData =
      await request(
        "/api/customer/login",
        {
          method: "POST",
          body: JSON.stringify({
            membership:
              membership,
            password:
              password
          })
        }
      );


    console.log(
      "HASANI CUSTOMER APP: LOGIN RESPONSE",
      loginData
    );


    if (
      !loginData ||
      !loginData.ok ||
      !loginData.authenticated
    ) {
      throw new Error(
        loginData &&
        loginData.error
          ? loginData.error
          : "Login was not accepted."
      );
    }


    /*
     * Store customer returned by backend.
     */
    state.customer =
      loginData.customer ||
      null;


    state.authenticated =
      true;


    /*
     * Step 2:
     * Verify that the browser can send
     * the newly-created customer session
     * cookie back to Node.
     */
    console.log(
      "HASANI CUSTOMER APP: VERIFYING SESSION"
    );


    const me =
      await request(
        "/api/customer/me",
        {
          method: "GET"
        }
      );


    console.log(
      "HASANI CUSTOMER APP: SESSION RESPONSE",
      me
    );


    if (
      !me ||
      !me.ok ||
      !me.authenticated
    ) {
      throw new Error(
        "Customer session was not created correctly."
      );
    }


    if (me.customer) {
      state.customer =
        me.customer;
    }


    /*
     * Step 3:
     * Load dashboard data from ARMS.
     */
    console.log(
      "HASANI CUSTOMER APP: LOADING DASHBOARD"
    );


    state.dashboard = {
      ok: true,
      source: "ARMS",
      customer: state.customer,
      purchases: [],
      rewards: [],
      offers: [],
      locations: [],
      integration: {
        armsAuthenticated: true,
        historyLoading: true,
        historyMessage: "Purchase history is loading in the background."
      }
    };


    console.log(
      "HASANI CUSTOMER APP: DASHBOARD RESPONSE",
      state.dashboard
    );


    /*
     * Render customer.
     */
    renderCustomer();

    renderDashboard();


    /*
     * QR / barcode.
     *
     * If this endpoint fails, don't prevent
     * the customer from entering dashboard.
     */
    try {
      await loadCardVisuals();
    } catch (error) {
      console.warn(
        "QR/barcode could not be loaded:",
        error
      );
    }


    /*
     * Show application.
     */
    showApp();

    showView(
      "dashboard"
    );


    loadPurchaseHistory();


    if ($("loginMessage")) {
      $("loginMessage").textContent =
        "";
    }


    console.log(
      "HASANI CUSTOMER APP: LOGIN SUCCESS"
    );

  } catch (error) {
    console.error(
      "HASANI CUSTOMER APP: LOGIN FAILED",
      error
    );


    if (
      error.code ===
      "CUSTOMER_SESSION_EXPIRED"
    ) {
      return;
    }


    clearState();


    if ($("loginMessage")) {
      $("loginMessage").textContent =
        error.message ||
        "Login failed.";
    }
  }
}


/* ==========================================================================
   RESTORE EXISTING SESSION
   ========================================================================== */

async function restoreSession() {
  console.log(
    "HASANI CUSTOMER APP: CHECKING EXISTING SESSION"
  );


  try {
    const me =
      await request(
        "/api/customer/me",
        {
          method: "GET"
        }
      );


    if (
      !me ||
      !me.ok ||
      !me.authenticated
    ) {
      showLogin("");
      return;
    }


    state.customer =
      me.customer ||
      null;


    state.authenticated =
      true;


    state.dashboard = {
      ok: true,
      source: "ARMS",
      customer: state.customer,
      purchases: [],
      rewards: [],
      offers: [],
      locations: [],
      integration: {
        armsAuthenticated: true,
        historyLoading: true,
        historyMessage: "Purchase history is loading in the background."
      }
    };


    renderCustomer();

    renderDashboard();


    try {
      await loadCardVisuals();
    } catch (error) {
      console.warn(
        "QR/barcode restore failed:",
        error
      );
    }


    showApp();

    showView(
      "dashboard"
    );


    loadPurchaseHistory();


    console.log(
      "HASANI CUSTOMER APP: EXISTING SESSION RESTORED"
    );

  } catch (error) {
    /*
     * No existing customer session.
     * This is normal when opening the app
     * for the first time.
     */
    if (
      error.code ===
      "CUSTOMER_SESSION_EXPIRED"
    ) {
      return;
    }


    clearState();

    showLogin("");
  }
}


/* ==========================================================================
   BACKEND HEALTH CHECK
   ========================================================================== */

async function checkBackend() {
  try {
    const base =
      API.replace(
        /\/api$/,
        ""
      );


    const response =
      await fetch(
        base + "/health",
        {
          method: "GET",
          credentials: "include"
        }
      );


    if (!response.ok) {
      throw new Error(
        "Health request failed."
      );
    }


    const data =
      await response.json();


    if ($("backendStatus")) {
      $("backendStatus").textContent =
        data.ok
          ? "Backend online"
          : "Backend error";
    }


    console.log(
      "HASANI CUSTOMER APP: BACKEND HEALTH",
      data
    );

  } catch (error) {
    console.error(
      "HASANI CUSTOMER APP: BACKEND HEALTH FAILED",
      error
    );


    if ($("backendStatus")) {
      $("backendStatus").textContent =
        "Backend offline";
    }
  }
}


/* ==========================================================================
   INITIALIZATION
   ========================================================================== */

function initializeApp() {
  console.log(
    "HASANI CUSTOMER APP: JavaScript loaded"
  );


  const loginForm =
    $("loginForm");


  if (!loginForm) {
    console.error(
      "HASANI CUSTOMER APP: loginForm not found"
    );

    return;
  }


  console.log(
    "HASANI CUSTOMER APP: loginForm found"
  );


  /*
   * Attach login event.
   */
  loginForm.addEventListener(
    "submit",
    login
  );


  /*
   * Navigation.
   */
  setupNavigation();


  /*
   * Backend status.
   */
  checkBackend();


  /*
   * Existing customer session.
   */
  restoreSession();
}


/* ==========================================================================
   START
   ========================================================================== */

if (
  document.readyState ===
  "loading"
) {
  document.addEventListener(
    "DOMContentLoaded",
    initializeApp
  );
} else {
  initializeApp();
}

