/*
 * ============================================================
 * HASANI BOOKS CUSTOMER WEB APP
 * ============================================================
 *
 * File:
 * C:\123\web\js\app.js
 *
 * Backend:
 * http://localhost:5000
 *
 * Features:
 * - Customer login
 * - ARMS session
 * - Customer dashboard
 * - Purchase history
 * - Click purchase to view item details
 * - Member points
 * - Personal information
 * - Hasani Books discount card
 * - Barcode
 * - Rewards
 * - Offers
 * - Online Store
 * - Locations
 * - Logout
 */


/* ============================================================
   API CONFIGURATION
   ============================================================ */

const API = (
  new URLSearchParams(
    window.location.search
  ).get("api") ||
  `${window.location.protocol}//${window.location.hostname}:5000`
).replace(/\/$/, "");


/* ============================================================
   APPLICATION STATE
   ============================================================ */

const state = {
  customer: null,

  dashboard: null,

  authenticated: false
};


/* ============================================================
   DOM HELPERS
   ============================================================ */

function $(id) {

  return document.getElementById(id);

}


function esc(value) {

  return String(
    value ?? ""
  ).replace(
    /[&<>"']/g,
    function (character) {

      if (character === "&") {
        return "&amp;";
      }

      if (character === "<") {
        return "&lt;";
      }

      if (character === ">") {
        return "&gt;";
      }

      if (character === '"') {
        return "&quot;";
      }

      if (character === "'") {
        return "&#39;";
      }

      return character;

    }
  );

}


/* ============================================================
   NUMBER HELPERS
   ============================================================ */

function money(value) {

  const number =
    Number(value);

  return Number.isFinite(number)
    ? number
    : 0;

}


function moneyText(value) {

  return money(value)
    .toFixed(2);

}


/* ============================================================
   SESSION STATE
   ============================================================ */

function clearState() {

  state.customer = null;

  state.dashboard = null;

  state.authenticated = false;

}


function showLogin(message) {

  clearState();


  const loginPage =
    $("loginPage");

  const appShell =
    $("appShell");


  if (loginPage) {

    loginPage.classList.remove(
      "hidden"
    );

  }


  if (appShell) {

    appShell.classList.add(
      "hidden"
    );

  }


  if ($("loginMessage")) {

    $("loginMessage").textContent =
      message || "";

  }

}


function showApp() {

  const loginPage =
    $("loginPage");

  const appShell =
    $("appShell");


  if (loginPage) {

    loginPage.classList.add(
      "hidden"
    );

  }


  if (appShell) {

    appShell.classList.remove(
      "hidden"
    );

  }

}


/* ============================================================
   API REQUEST
   ============================================================ */

async function request(
  path,
  options
) {

  const config =
    options || {};


  const fetchOptions = {

    method:
      config.method ||
      "GET",

    credentials:
      "include"

  };


  if (
    config.body !== undefined
  ) {

    fetchOptions.body =
      config.body;

  }


  if (config.headers) {

    fetchOptions.headers = {
      ...config.headers
    };

  } else {

    fetchOptions.headers = {};

  }


  if (
    config.body !== undefined &&
    config.body !== null &&
    typeof config.body === "string"
  ) {

    fetchOptions.headers[
      "Content-Type"
    ] =
      "application/json";

  }


  let response;


  try {

    response =
      await fetch(
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

      data =
        JSON.parse(text);

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


    error.status =
      401;


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
      data &&
      data.error
        ? data.error
        : "HTTP " +
          response.status;


    const error =
      new Error(message);


    error.status =
      response.status;


    error.code =
      data &&
      data.code
        ? data.code
        : null;


    throw error;

  }


  return data;

}


/* ============================================================
   NAVIGATION
   ============================================================ */

function showView(
  view
) {

  document
    .querySelectorAll(
      ".view"
    )
    .forEach(
      function (element) {

        element.classList.add(
          "hidden"
        );

      }
    );


  const target =
    $("view-" + view);


  if (target) {

    target.classList.remove(
      "hidden"
    );

  }


  document
    .querySelectorAll(
      ".nav-item"
    )
    .forEach(
      function (element) {

        element.classList.toggle(
          "active",
          element.dataset.view === view
        );

      }
    );


  const titles = {

    dashboard:
      "Dashboard",

    purchases:
      "Purchase History",

    points:
      "Member Points",

    personal:
      "Personal Information",

    rewards:
      "Rewards",

    offers:
      "Offers",

    store:
      "Online Store",

    locations:
      "Locations"

  };


  if ($("pageTitle")) {

    $("pageTitle").textContent =
      titles[view] ||
      "Dashboard";

  }


  if ($("sidebar")) {

    $("sidebar").classList.remove(
      "open"
    );

  }


  window.scrollTo({
    top: 0,
    behavior: "smooth"
  });


  if (
    view === "personal" &&
    state.authenticated
  ) {

    loadPersonalInformation();

  }

}


function setupNavigation() {

  document
    .querySelectorAll(
      "[data-view]"
    )
    .forEach(
      function (element) {

        element.addEventListener(
          "click",
          function () {

            const view =
              element.dataset.view;


            /*
             * Online Store.
             */

            if (
              view === "store"
            ) {

              window.location.href =
                "https://hasanibooks.com/";

              return;

            }


            /*
             * Locations.
             */

            if (
              view === "locations"
            ) {

              window.location.href =
                "https://hasanibooks.com/store-locator";

              return;

            }


            showView(
              view
            );


            if (
              view === "purchases" &&
              !(
                state.dashboard?.purchases ||
                []
              ).length
            ) {

              loadPurchaseHistory();

            }

          }
        );

      }
    );


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


/* ============================================================
   LOGOUT
   ============================================================ */

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
     * Session may already be gone.
     */

  }


  clearState();

  showLogin("");


  if ($("loginPassword")) {

    $("loginPassword").value =
      "123123";

  }

}


/* ============================================================
   BARCODE
   ============================================================ */

async function loadCardVisuals() {

  const data =
    await request(
      "/api/customer/card-visuals"
    );


  /*
   * QR intentionally not displayed.
   */

  if (
    data.barcodeDataUrl &&
    $("barcodeImg")
  ) {

    $("barcodeImg").src =
      data.barcodeDataUrl;

  }

}


/* ============================================================
   CUSTOMER DISPLAY
   ============================================================ */

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
      .map(
        function (part) {

          return part.charAt(0);

        }
      )
      .join("")
      .slice(0, 2)
      .toUpperCase();


  /*
   * Sidebar + welcome.
   */

  [
    "sideName",
    "welcomeName"
  ].forEach(
    function (id) {

      if ($(id)) {

        $(id).textContent =
          name;

      }

    }
  );


  /*
   * Sidebar membership.
   */

  if ($("sideMember")) {

    $("sideMember").textContent =
      membership;

  }


  /*
   * Discount card.
   */

  if ($("discountCardName")) {

    $("discountCardName").textContent =
      name;

  }


  if ($("discountCardMember")) {

    $("discountCardMember").textContent =
      membership;

  }


  /*
   * Expiry date.
   */

  const personal =
    customer.personalInformation ||
    {};


  const expiry =
    customer.expiryDate ||
    personal.expiryDate ||
    "—";


  if ($("discountCardExpiry")) {

    $("discountCardExpiry").textContent =
      expiry;

  }


  /*
   * Avatars.
   */

  if ($("sideAvatar")) {

    $("sideAvatar").textContent =
      initials ||
      "A";

  }


  if ($("topAvatar")) {

    $("topAvatar").textContent =
      initials ||
      "A";

  }


  /*
   * Points.
   */

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
      Number(
        customer.pointsEarned ||
        0
      );

  }

}


/* ============================================================
   PURCHASE HELPERS
   ============================================================ */

function purchaseReceipt(
  purchase
) {

  return (
    purchase.receiptNo ??
    purchase.receipt_no ??
    "-"
  );

}


function purchaseDate(
  purchase
) {

  return (
    purchase.date ??
    purchase.transaction_time ??
    "-"
  );

}


function purchaseBranch(
  purchase
) {

  return (
    purchase.branch ??
    ""
  );

}


function purchaseCashier(
  purchase
) {

  return (
    purchase.cashier ??
    ""
  );

}


function purchaseReference(
  purchase
) {

  return (
    purchase.receiptRefNo ??
    purchase.receipt_ref_no ??
    ""
  );

}


function purchaseAmount(
  purchase
) {

  const value =
    purchase.total ??
    purchase.payment_amount ??
    0;


  return money(value);

}


function purchasePoints(
  purchase
) {

  const value =
    purchase.points ??
    0;


  return money(value);

}


/* ============================================================
   PURCHASE DETAIL HELPERS
   ============================================================ */

function getPurchaseDetail(
  purchase
) {

  if (
    !purchase ||
    !purchase.detail
  ) {

    return null;

  }


  return purchase.detail;

}


function getPurchaseItems(
  purchase
) {

  const detail =
    getPurchaseDetail(
      purchase
    );


  if (
    !detail ||
    !Array.isArray(
      detail.items
    )
  ) {

    return [];

  }


  return detail.items;

}


/* ============================================================
   PURCHASE DETAIL MODAL
   ============================================================ */

function closePurchaseDetail() {

  const modal =
    $("purchaseDetailModal");


  if (modal) {

    modal.classList.remove(
      "open"
    );

  }

}


function ensurePurchaseDetailModal() {

  let modal =
    $("purchaseDetailModal");


  if (modal) {

    return modal;

  }


  modal =
    document.createElement(
      "div"
    );


  modal.id =
    "purchaseDetailModal";


  modal.className =
    "purchase-detail-modal";


  document.body.appendChild(
    modal
  );


  return modal;

}


function renderPurchaseDetails(
  purchase
) {

  const modal =
    ensurePurchaseDetailModal();


  const receipt =
    purchaseReceipt(
      purchase
    );


  const date =
    purchaseDate(
      purchase
    );


  const branch =
    purchaseBranch(
      purchase
    );


  const cashier =
    purchaseCashier(
      purchase
    );


  const reference =
    purchaseReference(
      purchase
    );


  const purchaseTotal =
    purchaseAmount(
      purchase
    );


  const detail =
    getPurchaseDetail(
      purchase
    );


  const items =
    getPurchaseItems(
      purchase
    );


  /*
   * No transaction detail.
   */

  if (
    !detail
  ) {

    modal.innerHTML =

      '<div class="purchase-detail-overlay">' +

        '<div class="purchase-detail-box">' +

          '<button ' +
            'type="button" ' +
            'class="purchase-detail-close" ' +
            'aria-label="Close">' +
            '×' +
          '</button>' +

          '<div class="eyebrow">' +
            'PURCHASE DETAILS' +
          '</div>' +

          '<h2>' +
            'Receipt #' +
            esc(receipt) +
          '</h2>' +

          '<div class="purchase-detail-summary">' +

            '<div>' +

              '<span>Date</span>' +

              '<strong>' +
                esc(date) +
              '</strong>' +

            '</div>' +

            '<div>' +

              '<span>Total</span>' +

              '<strong>' +
                'RM ' +
                purchaseTotal.toFixed(2) +
              '</strong>' +

            '</div>' +

          '</div>' +

          '<div class="purchase-detail-empty">' +

            '<div class="big-icon">🧾</div>' +

            '<h3>Item details unavailable</h3>' +

            '<p>' +

              'ARMS returned this purchase record, ' +
              'but transaction item details were not returned.' +

            '</p>' +

          '</div>' +

        '</div>' +

      '</div>';


    modal.classList.add(
      "open"
    );


    setupPurchaseDetailModalEvents(
      modal
    );


    return;

  }


  /*
   * Detail exists but contains no items.
   */

  if (
    !items.length
  ) {

    modal.innerHTML =

      '<div class="purchase-detail-overlay">' +

        '<div class="purchase-detail-box">' +

          '<button ' +
            'type="button" ' +
            'class="purchase-detail-close" ' +
            'aria-label="Close">' +
            '×' +
          '</button>' +

          '<div class="eyebrow">' +
            'PURCHASE DETAILS' +
          '</div>' +

          '<h2>' +
            'Receipt #' +
            esc(receipt) +
          '</h2>' +

          '<p class="purchase-detail-date">' +
            esc(date) +
          '</p>' +

          '<div class="purchase-detail-empty">' +

            '<div class="big-icon">🧾</div>' +

            '<h3>Item details unavailable</h3>' +

            '<p>' +

              'ARMS returned the transaction, ' +
              'but no item-level rows were returned.' +

            '</p>' +

          '</div>' +

        '</div>' +

      '</div>';


    modal.classList.add(
      "open"
    );


    setupPurchaseDetailModalEvents(
      modal
    );


    return;

  }


  /*
   * Build item rows.
   */

  const rows =
    items.map(
      function (item, index) {

        const description =
          item.description ||
          item.item_description ||
          item.name ||
          "Item";


        const barcode =
          item.barcode ||
          item.Barcode ||
          "";


        const quantity =
          money(
            item.qty ??
            item.quantity ??
            0
          );


        const actualPrice =
          money(
            item.actual_price ??
            item.actualPrice ??
            item.price ??
            0
          );


        const discount =
          money(
            item.discount ??
            0
          );


        const sellingPrice =
          money(
            item.selling_price ??
            item.sellingPrice ??
            item.selling ??
            0
          );


        /*
         * Prefer ARMS selling price.
         *
         * If not available, calculate
         * from actual price minus discount.
         */

        const unitPrice =
          sellingPrice ||
          Math.max(
            actualPrice -
            discount,
            0
          );


        const lineAmount =
          money(
            item.line_total ??
            item.lineTotal ??
            item.amount ??
            (
              unitPrice *
              quantity
            )
          );


        return (

          '<tr>' +

            '<td>' +

              '<div class="item-number">' +
                (index + 1) +
              '</div>' +

            '</td>' +

            '<td>' +

              '<strong>' +
                esc(description) +
              '</strong>' +

              (
                barcode
                  ? '<small>Barcode: ' +
                    esc(barcode) +
                    '</small>'
                  : ''
              ) +

            '</td>' +

            '<td class="item-center">' +

              esc(
                quantity
              ) +

            '</td>' +

            '<td class="item-money">' +

              'RM ' +
              unitPrice.toFixed(2) +

            '</td>' +

            '<td class="item-money">' +

              (
                discount > 0
                  ? '- RM ' +
                    discount.toFixed(2)
                  : '-'
              ) +

            '</td>' +

            '<td class="item-money">' +

              'RM ' +
              lineAmount.toFixed(2) +

            '</td>' +

          '</tr>'

        );

      }
    ).join("");


  /*
   * Totals.
   */

  const subtotal =
    money(
      detail.subtotal
    );


  const rounding =
    money(
      detail.rounding
    );


  const total =
    money(
      detail.total ||
      purchaseTotal
    );


  const change =
    money(
      detail.change
    );


  modal.innerHTML =

    '<div class="purchase-detail-overlay">' +

      '<div class="purchase-detail-box purchase-detail-large">' +

        '<button ' +
          'type="button" ' +
          'class="purchase-detail-close" ' +
          'aria-label="Close">' +
          '×' +
        '</button>' +

        '<div class="eyebrow">' +
          'PURCHASE DETAILS' +
        '</div>' +


        '<div class="purchase-detail-header">' +

          '<div>' +

            '<h2>' +
              'Receipt #' +
              esc(receipt) +
            '</h2>' +

            '<p>' +
              esc(date) +
            '</p>' +

            (
              branch
                ? '<span>Branch: ' +
                  esc(branch) +
                  '</span>'
                : ''
            ) +

            (
              cashier
                ? '<span> · Cashier: ' +
                  esc(cashier) +
                  '</span>'
                : ''
            ) +

            (
              reference
                ? '<span> · Ref: ' +
                  esc(reference) +
                  '</span>'
                : ''
            ) +

          '</div>' +


          '<div class="purchase-detail-total">' +

            '<span>Total</span>' +

            '<strong>' +

              'RM ' +
              total.toFixed(2) +

            '</strong>' +

          '</div>' +

        '</div>' +


        '<div class="purchase-items-wrapper">' +

          '<table class="purchase-items-table">' +

            '<thead>' +

              '<tr>' +

                '<th>#</th>' +

                '<th>Item</th>' +

                '<th>Qty</th>' +

                '<th>Price</th>' +

                '<th>Discount</th>' +

                '<th>Amount</th>' +

              '</tr>' +

            '</thead>' +

            '<tbody>' +

              rows +

            '</tbody>' +

          '</table>' +

        '</div>' +


        '<div class="purchase-totals">' +

          '<div>' +

            '<span>Subtotal</span>' +

            '<strong>' +

              'RM ' +
              subtotal.toFixed(2) +

            '</strong>' +

          '</div>' +


          '<div>' +

            '<span>Rounding</span>' +

            '<strong>' +

              'RM ' +
              rounding.toFixed(2) +

            '</strong>' +

          '</div>' +


          '<div class="grand-total">' +

            '<span>Total</span>' +

            '<strong>' +

              'RM ' +
              total.toFixed(2) +

            '</strong>' +

          '</div>' +


          (
            change > 0

              ? '<div>' +

                  '<span>Change</span>' +

                  '<strong>' +

                    'RM ' +
                    change.toFixed(2) +

                  '</strong>' +

                '</div>'

              : ''
          ) +

        '</div>' +

      '</div>' +

    '</div>';


  modal.classList.add(
    "open"
  );


  setupPurchaseDetailModalEvents(
    modal
  );

}


function setupPurchaseDetailModalEvents(
  modal
) {

  const close =
    modal.querySelector(
      ".purchase-detail-close"
    );


  if (close) {

    close.addEventListener(
      "click",
      closePurchaseDetail
    );

  }


  const overlay =
    modal.querySelector(
      ".purchase-detail-overlay"
    );


  if (overlay) {

    overlay.addEventListener(
      "click",
      function (event) {

        if (
          event.target ===
          overlay
        ) {

          closePurchaseDetail();

        }

      }
    );

  }

}


/* ============================================================
   KEYBOARD CLOSE
   ============================================================ */

document.addEventListener(
  "keydown",
  function (event) {

    if (
      event.key === "Escape"
    ) {

      closePurchaseDetail();

    }

  }
);


/* ============================================================
   DASHBOARD
   ============================================================ */

function renderDashboard() {

  const dashboard =
    state.dashboard;


  if (!dashboard) {

    return;

  }


  const purchases =
    Array.isArray(
      dashboard.purchases
    )
      ? dashboard.purchases
      : [];


  const totalSpend =
    purchases.reduce(
      function (
        sum,
        purchase
      ) {

        return (
          sum +
          purchaseAmount(
            purchase
          )
        );

      },
      0
    );


  if ($("dashSpend")) {

    $("dashSpend").textContent =
      "RM " +
      totalSpend.toFixed(2);

  }


  if ($("dashTransactions")) {

    $("dashTransactions").textContent =
      String(
        purchases.length
      );

  }


  if ($("pointsSpend")) {

    $("pointsSpend").textContent =
      "RM " +
      totalSpend.toFixed(2);

  }


  /*
   * PURCHASE HISTORY
   */

  if ($("purchaseList")) {

    if (
      !purchases.length
    ) {

      $("purchaseList").innerHTML =

        '<div class="empty-feature">' +

          '<h2>No ARMS purchases returned</h2>' +

          '<p>' +

            'No purchase records were returned for this membership.' +

          '</p>' +

        '</div>';

    } else {

      $("purchaseList").innerHTML =

        purchases.map(
          function (
            purchase,
            index
          ) {

            const receipt =
              purchaseReceipt(
                purchase
              );


            const date =
              purchaseDate(
                purchase
              );


            const branch =
              purchaseBranch(
                purchase
              );


            const cashier =
              purchaseCashier(
                purchase
              );


            const reference =
              purchaseReference(
                purchase
              );


            const amount =
              purchaseAmount(
                purchase
              );


            const points =
              purchasePoints(
                purchase
              );


            return (

              '<button ' +

                'type="button" ' +

                'class="purchase-card purchase-card-clickable" ' +

                'data-purchase-index="' +
                  index +
                '">' +


                '<div class="purchase-main">' +

                  '<b>' +

                    'Receipt #' +

                    esc(
                      receipt
                    ) +

                  '</b>' +


                  '<span>' +

                    esc(
                      date
                    ) +

                    (
                      branch
                        ? ' · ' +
                          esc(branch)
                        : ''
                    ) +

                    (
                      cashier
                        ? ' · Cashier ' +
                          esc(cashier)
                        : ''
                    ) +

                  '</span>' +


                  (
                    reference

                      ? '<span>' +

                          'Ref: ' +

                          esc(
                            reference
                          ) +

                        '</span>'

                      : ''
                  ) +

                '</div>' +


                '<div class="purchase-points">' +

                  '<strong>' +

                    'RM ' +

                    amount.toFixed(2) +

                  '</strong>' +


                  '<small>' +

                    '+' +

                    esc(
                      points
                    ) +

                    ' points' +

                  '</small>' +

                '</div>' +


                '<span class="purchase-view-arrow">' +

                  'View details →' +

                '</span>' +


              '</button>'

            );

          }
        ).join("");

    }


    /*
     * Attach click handlers.
     */

    document
      .querySelectorAll(
        ".purchase-card-clickable"
      )
      .forEach(
        function (card) {

          card.addEventListener(
            "click",
            function () {

              const index =
                Number(
                  card.dataset.purchaseIndex
                );


              const purchase =
                purchases[index];


              if (!purchase) {

                return;

              }


              renderPurchaseDetails(
                purchase
              );

            }
          );

        }
      );

  }


  /*
   * POINT HISTORY
   */

  if ($("pointsRows")) {

    if (
      !purchases.length
    ) {

      $("pointsRows").innerHTML =

        '<div class="empty-feature">' +

          '<p>' +

            'No point transactions returned by ARMS.' +

          '</p>' +

        '</div>';

    } else {

      $("pointsRows").innerHTML =

        purchases.map(
          function (purchase) {

            return (

              '<div class="row">' +

                '<b>' +

                  esc(
                    purchaseDate(
                      purchase
                    )
                  ) +

                '</b>' +

                '<span>' +

                  'RM ' +

                  purchaseAmount(
                    purchase
                  ).toFixed(2) +

                '</span>' +

                '<span>' +

                  '+' +

                  esc(
                    purchasePoints(
                      purchase
                    )
                  ) +

                  ' points' +

                '</span>' +

              '</div>'

            );

          }
        ).join("");

    }

  }


  /*
   * REWARDS
   */

  const rewards =
    Array.isArray(
      dashboard.rewards
    )
      ? dashboard.rewards
      : [];


  if ($("rewardsGrid")) {

    if (
      !rewards.length
    ) {

      $("rewardsGrid").innerHTML =

        '<div class="empty-feature">' +

          '<h2>Rewards</h2>' +

          '<p>' +

            'No rewards are currently available.' +

          '</p>' +

        '</div>';

    } else {

      $("rewardsGrid").innerHTML =

        rewards.map(
          function (item) {

            return (

              '<div class="feature-card">' +

                '<b>' +

                  '🎁 ' +

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

          }
        ).join("");

    }

  }


  /*
   * OFFERS
   */

  const offers =
    Array.isArray(
      dashboard.offers
    )
      ? dashboard.offers
      : [];


  if ($("offersGrid")) {

    if (
      !offers.length
    ) {

      $("offersGrid").innerHTML =

        '<div class="empty-feature">' +

          '<h2>Offers</h2>' +

          '<p>' +

            'No member offers are currently available.' +

          '</p>' +

        '</div>';

    } else {

      $("offersGrid").innerHTML =

        offers.map(
          function (item) {

            return (

              '<div class="feature-card">' +

                '<b>' +

                  '🏷️ ' +

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

          }
        ).join("");

    }

  }

}


/* ============================================================
   PERSONAL INFORMATION
   ============================================================ */

function personalField(
  label,
  value
) {

  const display =
    value === null ||
    value === undefined ||
    String(value).trim() === ""
      ? "Not available"
      : String(value);


  return (

    '<div class="personal-info-card">' +

      '<span class="personal-info-label">' +

        esc(
          label
        ) +

      '</span>' +

      '<strong class="personal-info-value">' +

        esc(
          display
        ) +

      '</strong>' +

    '</div>'

  );

}


function renderPersonalInformation(
  info
) {

  const grid =
    $("personalInfoGrid");


  if (!grid) {

    return;

  }


  info =
    info ||
    {};


  grid.innerHTML =

    personalField(
      "Membership Card No.",
      info.cardNo
    ) +

    personalField(
      "NRIC / Passport No.",
      info.nric
    ) +

    personalField(
      "Full Name",
      info.fullName ||
      info.name
    ) +

    personalField(
      "Title",
      info.title
    ) +

    personalField(
      "Membership Type",
      info.membershipType ||
      info.memberType
    ) +

    personalField(
      "Gender",
      info.gender
    ) +

    personalField(
      "D.O.B.",
      info.dob ||
      info.birthday
    ) +

    personalField(
      "Race",
      info.race
    ) +

    personalField(
      "Nationality",
      info.nationality
    ) +

    personalField(
      "Apply Branch",
      info.applyBranch
    ) +

    personalField(
      "Last Renew Branch",
      info.lastRenewBranch
    ) +

    personalField(
      "Last Purchase Branch",
      info.lastPurchaseBranch
    ) +

    personalField(
      "Points",
      info.points
    ) +

    personalField(
      "Points Update",
      info.pointsUpdate
    ) +

    personalField(
      "Issue Branch",
      info.issueBranch
    ) +

    personalField(
      "Issue Date",
      info.issueDate
    ) +

    personalField(
      "Expiry Date",
      info.expiryDate
    ) +

    personalField(
      "Terminated Date",
      info.terminatedDate
    ) +

    personalField(
      "Blocked Date",
      info.blockedDate
    ) +

    personalField(
      "Verified By",
      info.verifiedBy
    );

}


async function loadPersonalInformation() {

  const grid =
    $("personalInfoGrid");


  if (!grid) {

    return;

  }


  grid.innerHTML =

    '<div class="empty-feature">' +

      '<h2>Loading Personal Information...</h2>' +

      '<p>' +

        'Fetching your member information from ARMS.' +

      '</p>' +

    '</div>';


  try {

    console.log(
      "HASANI CUSTOMER APP: LOADING PERSONAL INFORMATION"
    );


    const result =
      await request(
        "/api/customer/personal-information",
        {
          method: "GET"
        }
      );


    if (
      !result ||
      !result.ok
    ) {

      throw new Error(
        result?.error ||
        "Unable to load personal information from ARMS."
      );

    }


    const information =
      result.personalInformation ||
      {};


    if (state.customer) {

      state.customer.personalInformation =
        information;

    }


    if (
      $("discountCardExpiry") &&
      information.expiryDate
    ) {

      $("discountCardExpiry").textContent =
        information.expiryDate;

    }


    renderPersonalInformation(
      information
    );


  } catch (error) {

    console.error(
      "HASANI CUSTOMER APP: PERSONAL INFORMATION FAILED",
      error
    );


    grid.innerHTML =

      '<div class="empty-feature">' +

        '<h2>Unable to load Personal Information</h2>' +

        '<p>' +

          esc(
            error?.message ||
            "Unable to load information from ARMS."
          ) +

        '</p>' +

        '<button ' +
          'class="primary" ' +
          'type="button" ' +
          'id="retryPersonalInformation">' +

          'Retry' +

        '</button>' +

      '</div>';


    const retry =
      $("retryPersonalInformation");


    if (retry) {

      retry.addEventListener(
        "click",
        loadPersonalInformation
      );

    }

  }

}


/* ============================================================
   PURCHASE HISTORY
   ============================================================ */

async function loadPurchaseHistory() {

  const list =
    $("purchaseList");


  if (list) {

    list.innerHTML =

      '<div class="empty-feature">' +

        '<h2>Loading Purchase History…</h2>' +

        '<p>' +

          'Fetching ARMS purchase history.' +

        '</p>' +

      '</div>';

  }


  try {

    const result =
      await request(
        "/api/customer/purchases",
        {
          method: "GET"
        }
      );


    state.dashboard =
      state.dashboard ||
      {};


    state.dashboard.purchases =
      Array.isArray(
        result.purchases
      )
        ? result.purchases
        : [];


    if (
      result.points !== undefined &&
      state.customer
    ) {

      state.customer.points =
        Number(
          result.points ||
          0
        );

    }


    renderCustomer();

    renderDashboard();


    /*
     * Update dashboard status.
     */

    if (
      state.dashboard.integration
    ) {

      state.dashboard.integration
        .historyLoading =
        false;

      state.dashboard.integration
        .historyMessage =
        "Purchase history loaded.";

    }


    if ($("backendStatus")) {

      $("backendStatus").textContent =
        "ARMS session online";

    }


  } catch (error) {

    console.error(
      "HASANI CUSTOMER APP: PURCHASE HISTORY FAILED",
      error
    );


    if (
      error.code ===
      "CUSTOMER_SESSION_EXPIRED"
    ) {

      return;

    }


    state.dashboard =
      state.dashboard ||
      {};


    state.dashboard.purchases =
      [];


    if ($("purchaseList")) {

      $("purchaseList").innerHTML =

        '<div class="empty-feature">' +

          '<h2>Unable to load Purchase History</h2>' +

          '<p>' +

            esc(
              error?.message ||
              "ARMS purchase history could not be loaded."
            ) +

          '</p>' +

          '<button ' +
            'class="primary" ' +
            'type="button" ' +
            'id="retryPurchaseHistory">' +

            'Retry' +

          '</button>' +

        '</div>';

    }


    const retry =
      $("retryPurchaseHistory");


    if (retry) {

      retry.addEventListener(
        "click",
        loadPurchaseHistory
      );

    }

  }

}


/* ============================================================
   LOGIN
   ============================================================ */

async function login(
  event
) {

  event.preventDefault();


  const membershipInput =
    $("loginMembership");


  const passwordInput =
    $("loginPassword");


  const membership =
    membershipInput
      ? membershipInput.value.trim()
      : "";


  const password =
    passwordInput
      ? passwordInput.value
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
     * Login through Node.
     */

    const loginData =
      await request(
        "/api/customer/login",
        {
          method: "POST",

          body:
            JSON.stringify({
              membership:
                membership,

              password:
                password
            })
        }
      );


    if (
      !loginData ||
      !loginData.ok ||
      !loginData.authenticated
    ) {

      throw new Error(
        loginData?.error ||
        "Login was not accepted."
      );

    }


    state.customer =
      loginData.customer ||
      null;


    state.authenticated =
      true;


    /*
     * Verify session.
     */

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

      throw new Error(
        "Customer session was not created correctly."
      );

    }


    if (me.customer) {

      state.customer =
        me.customer;

    }


    /*
     * Initial dashboard.
     */

    state.dashboard = {

      ok: true,

      source: "ARMS",

      customer:
        state.customer,

      purchases: [],

      rewards: [],

      offers: [],

      locations: [],

      integration: {

        armsAuthenticated:
          true,

        historyLoading:
          true,

        historyMessage:
          "Purchase history is loading."

      }

    };


    renderCustomer();

    renderDashboard();


    /*
     * Barcode.
     */

    try {

      await loadCardVisuals();

    } catch (error) {

      console.warn(
        "Barcode could not be loaded:",
        error
      );

    }


    showApp();

    showView(
      "dashboard"
    );


    loadPurchaseHistory();


    if ($("loginMessage")) {

      $("loginMessage").textContent =
        "";

    }


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


/* ============================================================
   RESTORE SESSION
   ============================================================ */

async function restoreSession() {

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

      customer:
        state.customer,

      purchases: [],

      rewards: [],

      offers: [],

      locations: [],

      integration: {

        armsAuthenticated:
          true,

        historyLoading:
          true,

        historyMessage:
          "Purchase history is loading."

      }

    };


    renderCustomer();

    renderDashboard();


    try {

      await loadCardVisuals();

    } catch (error) {

      console.warn(
        "Barcode restore failed:",
        error
      );

    }


    showApp();

    showView(
      "dashboard"
    );


    loadPurchaseHistory();


  } catch (error) {

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


/* ============================================================
   BACKEND HEALTH
   ============================================================ */

async function checkBackend() {

  try {

    const base =
      API.replace(
        /\/api$/,
        ""
      );


    const response =
      await fetch(
        base +
        "/health",
        {
          method: "GET",

          credentials:
            "include"
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


/* ============================================================
   INITIALIZATION
   ============================================================ */

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


  loginForm.addEventListener(
    "submit",
    login
  );


  setupNavigation();


  checkBackend();


  restoreSession();

}


/* ============================================================
   START
   ============================================================ */

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