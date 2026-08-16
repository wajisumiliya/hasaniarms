/* ============================================================
   HASANI CUSTOMER WEB APP
   FINAL MEMBER 2 CSS VERSION
   ============================================================ */

const API = (
  new URLSearchParams(
    window.location.search
  ).get("api") ||
  `${window.location.protocol}//${window.location.hostname}:5000`
).replace(/\/$/, "");


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

      if (character === "&") return "&amp;";
      if (character === "<") return "&lt;";
      if (character === ">") return "&gt;";
      if (character === '"') return "&quot;";
      if (character === "'") return "&#39;";

      return character;

    }
  );

}


/* ============================================================
   SESSION
   ============================================================ */

function clearState() {

  state.customer = null;
  state.dashboard = null;
  state.authenticated = false;

}


function showLogin(message) {

  clearState();

  if ($("loginPage")) {

    $("loginPage")
      .classList
      .remove("hidden");

  }


  if ($("appShell")) {

    $("appShell")
      .classList
      .add("hidden");

  }


  if ($("loginMessage")) {

    $("loginMessage").textContent =
      message || "";

  }

}


function showApp() {

  if ($("loginPage")) {

    $("loginPage")
      .classList
      .add("hidden");

  }


  if ($("appShell")) {

    $("appShell")
      .classList
      .remove("hidden");

  }

}


/* ============================================================
   API
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


  fetchOptions.headers =
    config.headers
      ? {
          ...config.headers
        }
      : {};


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


  if (!response.ok) {

    throw new Error(
      data?.error ||
      data?.message ||
      `Request failed (${response.status}).`
    );

  }


  return data;

}


/* ============================================================
   CUSTOMER NAME CLEANING
   ============================================================ */

function cleanMemberName(
  value
) {

  let name =
    String(
      value ?? ""
    )
      .replace(
        /\u00a0/g,
        " "
      )
      .replace(
        /\s+/g,
        " "
      )
      .trim();


  if (!name) {

    return "";

  }


  if (
    /^arms\s+customer$/i.test(
      name
    )
  ) {

    return "";

  }


  /*
   * Remove prefixes repeatedly.
   *
   * Examples:
   *
   * MR: NAME
   * MRS: NAME
   * MR KB: NAME
   * MRS KG: NAME
   * S KB: NAME
   * S KG: NAME
   * KB: NAME
   * KG: NAME
   * : NAME
   */

  let previous = "";


  while (
    previous !== name
  ) {

    previous =
      name;


    name =
      name.replace(
        /^(?:MR|MRS|MS|MISS|DR|PROF)\.?\s*:?\s*/i,
        ""
      );


    name =
      name.replace(
        /^(?:S|MR|MRS|MS|MISS|DR|PROF)\s+(?:KB|KG)\s*:?\s*/i,
        ""
      );


    name =
      name.replace(
        /^(?:KB|KG)\s*:?\s*/i,
        ""
      );


    name =
      name.replace(
        /^:\s*/i,
        ""
      );


    name =
      name.trim();

  }


  /*
   * Remove prefixes occurring after another
   * title such as:
   *
   * S KB:
   * S KG:
   */

  name =
    name.replace(
      /^(?:S\s+)?(?:KB|KG)\s*:?\s*/i,
      ""
    );


  name =
    name.replace(
      /^:\s*/,
      ""
    );


  return name.trim();

}


/* ============================================================
   PERSONAL INFORMATION
   ============================================================ */

function getPersonalInformation() {

  return (
    state.customer?.personalInformation ||
    {}
  );

}


function getBestCustomerName(
  customer,
  personal
) {

  customer =
    customer ||
    {};


  personal =
    personal ||
    {};


  const candidates = [

    personal.fullName,

    personal.name,

    customer.fullName,

    customer.full_name,

    customer.name,

    customer.customerName,

    customer.customer_name,

    customer.memberName,

    customer.member_name,

    customer.displayName,

    customer.display_name

  ];


  for (
    const candidate of candidates
  ) {

    const cleaned =
      cleanMemberName(
        candidate
      );


    if (
      cleaned
    ) {

      return cleaned;

    }

  }


  return "";

}


/* ============================================================
   CARD DATA
   ============================================================ */

function getCustomerExpiry() {

  const customer =
    state.customer ||
    {};


  const personal =
    getPersonalInformation();


  return (

    customer.expiryDate ||

    customer.expiry_date ||

    customer.expiry ||

    personal.expiryDate ||

    personal.expiry_date ||

    personal.expiry ||

    ""

  );

}


function getCustomerIssueBranch() {

  const customer =
    state.customer ||
    {};


  const personal =
    getPersonalInformation();


  return (

    customer.issueBranch ||

    customer.issue_branch ||

    customer.issuedBranch ||

    customer.issued_branch ||

    personal.issueBranch ||

    personal.issue_branch ||

    personal.issuedBranch ||

    personal.issued_branch ||

    personal.lastRenewBranch ||

    ""

  );

}


/* ============================================================
   MEMBERSHIP TYPE
   ============================================================ */

function getCustomerMembershipType() {

  const customer =
    state.customer ||
    {};


  const personal =
    getPersonalInformation();


  return String(

    customer.membershipType ||

    customer.membership_type ||

    customer.memberType ||

    customer.member_type ||

    personal.membershipType ||

    personal.membership_type ||

    personal.memberType ||

    personal.member_type ||

    ""

  )
    .replace(
      /\u00a0/g,
      " "
    )
    .replace(
      /\s+/g,
      " "
    )
    .trim();

}


function isMember2() {

  const value =
    getCustomerMembershipType()
      .toUpperCase()
      .replace(
        /\s+/g,
        " "
      )
      .trim();


  return (

    value === "2" ||

    value === "MEMBER2" ||

    value === "MEMBER 2" ||

    value === "MEMBERSHIP2" ||

    value === "MEMBERSHIP 2" ||

    /\bMEMBER\s*2\b/.test(
      value
    ) ||

    /\bMEMBERSHIP\s*2\b/.test(
      value
    )

  );

}


/* ============================================================
   MEMBER 2 CSS
   ============================================================ */

function installMember2CardStyles() {

  if (
    $("member2CardStyles")
  ) {

    return;

  }


  const style =
    document.createElement(
      "style"
    );


  style.id =
    "member2CardStyles";


  style.textContent = `

    /* ========================================================
       COMMON
       ======================================================== */

    .discount-card.member2-active {

      position: relative !important;

      overflow: hidden !important;

      background-image: none !important;

      background-color: transparent !important;

      box-sizing: border-box !important;

    }


    .discount-card.member2-active
    > * {

      visibility: hidden !important;

    }


    .discount-card.member2-active
    .member2-css-card {

      visibility: visible !important;

    }


    .member2-css-card {

      position: absolute !important;

      inset: 0 !important;

      width: 100% !important;

      height: 100% !important;

      overflow: hidden !important;

      border-radius: inherit !important;

      box-sizing: border-box !important;

      font-family:
        Arial,
        Helvetica,
        sans-serif !important;

    }


    /* ========================================================
       FRONT
       ======================================================== */

    .member2-css-front {

      color: #ffffff;

      background:
        linear-gradient(
          115deg,
          #302c54 0%,
          #47456d 48%,
          #77789b 100%
        );

    }


    .member2-front-top {

      position: absolute;

      left: 0;

      right: 0;

      top: 0;

      height: 60%;

      background:
        linear-gradient(
          115deg,
          #29254c 0%,
          #454267 50%,
          #68698e 100%
        );

    }


    .member2-front-bottom {

      position: absolute;

      left: 0;

      right: 0;

      bottom: 0;

      height: 47%;

      background:
        linear-gradient(
          100deg,
          #d7d7e1 0%,
          #efeff4 100%
        );

      clip-path:
        polygon(
          0 25%,
          40% 25%,
          46% 0,
          100% 0,
          100% 100%,
          0 100%
        );

    }


    .member2-front-transition {

      position: absolute;

      left: 0;

      right: 0;

      top: 51%;

      height: 9%;

      background:
        rgba(
          201,
          201,
          220,
          .75
        );

      clip-path:
        polygon(
          0 0,
          41% 0,
          47% 100%,
          0 100%
        );

    }


    /* ========================================================
       FRONT LOGO
       ======================================================== */

    .member2-front-logo {

      position: absolute;

      left: 5%;

      top: 7%;

      line-height: .82;

      letter-spacing: -2px;

      white-space: nowrap;

      font-weight: 900;

    }


    .member2-logo-hasani {

      color: #ffffff;

      font-size:
        clamp(
          22px,
          4.1vw,
          58px
        );

    }


    .member2-logo-books {

      color: #ffffff;

      font-size:
        clamp(
          22px,
          4.1vw,
          58px
        );

    }


    .member2-front-title {

      position: absolute;

      left: 5%;

      top: 29%;

      color: #ffffff;

      font-size:
        clamp(
          11px,
          1.45vw,
          21px
        );

      font-weight: 800;

      letter-spacing: .2px;

      white-space: nowrap;

    }


    /* ========================================================
       FRONT DATA
       ======================================================== */

    .member2-front-info {

      position: absolute;

      left: 7%;

      right: 7%;

      bottom: 7%;

      height: 31%;

      display: grid;

      grid-template-columns:
        1.5fr
        .75fr
        .85fr;

      grid-template-rows:
        auto
        auto
        auto;

      column-gap: 4%;

      row-gap: 7%;

      align-items: end;

      color: #171a36;

    }


    .member2-field {

      min-width: 0;

    }


    .member2-field-name {

      grid-column:
        1 / 3;

      grid-row:
        1;

    }


    .member2-field-expiry {

      grid-column:
        3;

      grid-row:
        1;

    }


    .member2-field-id {

      grid-column:
        1;

      grid-row:
        2;

    }


    .member2-field-branch {

      grid-column:
        1 / 3;

      grid-row:
        3;

    }


    .member2-field label {

      display: block;

      margin-bottom: 2px;

      color: #57586b;

      font-size:
        clamp(
          6px,
          .78vw,
          10px
        );

      line-height: 1;

      font-weight: 800;

      letter-spacing: .3px;

    }


    .member2-field strong {

      display: block;

      color: #161a35;

      font-size:
        clamp(
          9px,
          1.12vw,
          15px
        );

      line-height: 1.05;

      font-weight: 900;

      white-space: nowrap;

      overflow: hidden;

      text-overflow: ellipsis;

    }


    .member2-field-name strong {

      font-size:
        clamp(
          12px,
          1.45vw,
          20px
        );

    }


    /* ========================================================
       FRONT BARCODE
       ======================================================== */

    .member2-front-barcode {

      position: absolute;

      right: 6.5%;

      bottom: 6.5%;

      width: 24%;

      height: 24%;

      background: #ffffff;

      border-radius: 3px;

      padding: 3px;

      box-sizing: border-box;

      display: flex;

      align-items: center;

      justify-content: center;

    }


    .member2-front-barcode img {

      width: 100%;

      height: 100%;

      object-fit: contain;

    }


    /* ========================================================
       BACK
       ======================================================== */

    .member2-css-back {

      color: #ffffff;

      background:
        linear-gradient(
          115deg,
          #403b5d 0%,
          #575477 48%,
          #74799e 100%
        );

    }


    .member2-back-gradient {

      position: absolute;

      inset: 0;

      background:
        radial-gradient(
          circle at 90% 5%,
          rgba(
            121,
            150,
            211,
            .42
          ),
          transparent 43%
        ),
        linear-gradient(
          115deg,
          #403b5d 0%,
          #575477 48%,
          #74799e 100%
        );

    }


    /* ========================================================
       BACK SOCIAL
       ======================================================== */

    .member2-back-social {

      position: absolute;

      left: 5.5%;

      top: 5%;

      display: flex;

      align-items: center;

      gap: 3px;

      color: #ffffff;

      font-size:
        clamp(
          6px,
          .7vw,
          10px
        );

      font-weight: 700;

      white-space: nowrap;

    }


    .member2-social-box {

      display: inline-flex;

      align-items: center;

      justify-content: center;

      width:
        clamp(
          11px,
          1.2vw,
          16px
        );

      height:
        clamp(
          11px,
          1.2vw,
          16px
        );

      border:
        1px solid
        rgba(
          255,
          255,
          255,
          .85
        );

      border-radius: 2px;

      font-size:
        clamp(
          6px,
          .65vw,
          9px
        );

    }


    .member2-phone {

      margin-left: 3px;

    }


    /* ========================================================
       BACK LOGO
       ======================================================== */

    .member2-back-logo {

      position: absolute;

      right: 5%;

      top: 4%;

      width: 25%;

      height: 14%;

      display: flex;

      align-items: center;

      justify-content: center;

      background: #ffffff;

      border-radius: 2px;

    }


    .member2-back-logo-text {

      white-space: nowrap;

      font-size:
        clamp(
          10px,
          1.45vw,
          20px
        );

      font-weight: 900;

      letter-spacing: -1px;

    }


    .member2-back-logo-text
    .hasani {

      color: #283c91;

    }


    .member2-back-logo-text
    .books {

      color: #ed2636;

    }


    /* ========================================================
       BACK TERMS
       ======================================================== */

    .member2-back-terms {

      position: absolute;

      left: 5.5%;

      right: 10%;

      top: 21%;

      bottom: 17%;

      display: flex;

      flex-direction: column;

      justify-content: space-between;

    }


    .member2-back-rule {

      padding-bottom: 3px;

      border-bottom:
        1px dotted
        rgba(
          255,
          255,
          255,
          .78
        );

      color: #ffffff;

      font-size:
        clamp(
          6px,
          .78vw,
          10px
        );

      line-height: 1.15;

      font-weight: 500;

    }


    /* ========================================================
       BACK VERTICAL STRIP
       ======================================================== */

    .member2-back-strip {

      position: absolute;

      right: 0;

      top: 23%;

      bottom: 17%;

      width: 6.5%;

      background: #e76b79;

      color: #ffffff;

      display: flex;

      align-items: center;

      justify-content: center;

      writing-mode: vertical-rl;

      transform:
        rotate(180deg);

      font-size:
        clamp(
          6px,
          .72vw,
          10px
        );

      font-weight: 800;

      letter-spacing: .2px;

    }


    /* ========================================================
       BACK FOOTER
       ======================================================== */

    .member2-back-footer {

      position: absolute;

      left: 0;

      right: 0;

      bottom: 0;

      min-height: 14%;

      padding:
        3px 8% 3px 5.5%;

      box-sizing: border-box;

      border-top:
        1px solid
        rgba(
          255,
          255,
          255,
          .45
        );

      display: flex;

      flex-direction: column;

      justify-content: center;

      color: #ffffff;

      font-size:
        clamp(
          5.5px,
          .68vw,
          9px
        );

      line-height: 1.1;

      font-weight: 700;

    }


    /* ========================================================
       MOBILE
       ======================================================== */

    @media (
      max-width: 700px
    ) {

      .member2-front-logo {

        top: 7%;

      }


      .member2-front-title {

        top: 30%;

      }


      .member2-front-info {

        left: 7%;

        right: 7%;

        bottom: 7%;

      }


      .member2-field label {

        font-size: 6px;

      }


      .member2-field strong {

        font-size: 8px;

      }


      .member2-field-name strong {

        font-size: 10px;

      }


      .member2-back-rule {

        font-size: 5.5px;

      }


      .member2-back-social {

        font-size: 5.5px;

      }


      .member2-back-logo-text {

        font-size: 8px;

      }


      .member2-back-footer {

        font-size: 5.5px;

      }

    }

  `;


  document.head.appendChild(
    style
  );

}


/* ============================================================
   CREATE MEMBER 2 FRONT
   ============================================================ */

function createMember2Front(
  card
) {

  let element =
    card.querySelector(
      ".member2-css-card"
    );


  if (element) {

    return element;

  }


  element =
    document.createElement(
      "div"
    );


  element.className =
    "member2-css-card member2-css-front";


  element.innerHTML = `

    <div
      class="member2-front-top"
    ></div>


    <div
      class="member2-front-bottom"
    ></div>


    <div
      class="member2-front-transition"
    ></div>


    <div
      class="member2-front-logo"
    >

      <span
        class="member2-logo-hasani"
      >
        hasani
      </span>

      <span
        class="member2-logo-books"
      >
        BOOKS
      </span>

    </div>


    <div
      class="member2-front-title"
    >
      TEACHER PRIVILEGE CARD
    </div>


    <div
      class="member2-front-info"
    >

      <div
        class="member2-field
               member2-field-name"
      >

        <label>
          MEMBER NAME
        </label>

        <strong
          id="member2CardName"
        >
          —
        </strong>

      </div>


      <div
        class="member2-field
               member2-field-expiry"
      >

        <label>
          EXPIRY DATE
        </label>

        <strong
          id="member2CardExpiry"
        >
          —
        </strong>

      </div>


      <div
        class="member2-field
               member2-field-id"
      >

        <label>
          MEMBER ID
        </label>

        <strong
          id="member2CardMember"
        >
          —
        </strong>

      </div>


      <div
        class="member2-field
               member2-field-branch"
      >

        <label>
          ISSUE BRANCH
        </label>

        <strong
          id="member2CardIssueBranch"
        >
          —
        </strong>

      </div>

    </div>


    <div
      class="member2-front-barcode"
    >

      <img
        id="member2BarcodeImg"
        alt="Membership barcode"
      >

    </div>

  `;


  card.appendChild(
    element
  );


  return element;

}


/* ============================================================
   CREATE MEMBER 2 BACK
   ============================================================ */

function createMember2Back(
  card
) {

  let element =
    card.querySelector(
      ".member2-css-card"
    );


  if (element) {

    return element;

  }


  element =
    document.createElement(
      "div"
    );


  element.className =
    "member2-css-card member2-css-back";


  element.innerHTML = `

    <div
      class="member2-back-gradient"
    ></div>


    <div
      class="member2-back-social"
    >

      <span
        class="member2-social-box"
      >
        f
      </span>

      <span
        class="member2-social-box"
      >
        ◎
      </span>

      <span
        class="member2-social-box"
      >
        ♪
      </span>

      <span
        class="member2-social-box"
      >
        ☎
      </span>

      <strong>
        hasaniBOOKS
      </strong>

      <span>
        |
      </span>

      <strong
        class="member2-phone"
      >
        +60 19-475 7733
      </strong>

    </div>


    <div
      class="member2-back-logo"
    >

      <span
        class="member2-back-logo-text"
      >

        <span
          class="hasani"
        >
          hasani
        </span>

        <span
          class="books"
        >
          BOOKS
        </span>

      </span>

    </div>


    <div
      class="member2-back-terms"
    >

      <div
        class="member2-back-rule"
      >
        Kad ini bukan kad kredit.
      </div>


      <div
        class="member2-back-rule"
      >
        Kad ini tidak boleh ditunaikan.
      </div>


      <div
        class="member2-back-rule"
      >
        Pemilik kad ini boleh mendapat diskaun bagi buku dan alat tulis yang terpilih sahaja.
      </div>


      <div
        class="member2-back-rule"
      >
        Sila gunakan kad ini di semua cawangan Hasani Books untuk menikmati potongan diskaun.
      </div>


      <div
        class="member2-back-rule"
      >
        Kad ini hak milik Hasani Books.
      </div>


      <div
        class="member2-back-rule"
      >
        Kegunaannya adalah tertakluk kepada syarat &amp; peraturan yang lazim digunakan. Jika terjumpa, sila kembalikan kad ini kepada Hasani Books.
      </div>

    </div>


    <div
      class="member2-back-strip"
    >
      TEACHER PRIVILEGE CARD
    </div>


    <div
      class="member2-back-footer"
    >

      <strong>
        Hasani Edar Sdn. Bhd.
      </strong>

      <span>
        41A–47A, Jalan Pengkalan,
        Taman Pekan Baru,
      </span>

      <span>
        08000 Sungai Petani,
        Kedah Darul Aman.
      </span>

    </div>

  `;


  card.appendChild(
    element
  );


  return element;

}


/* ============================================================
   APPLY MEMBER 2
   ============================================================ */

function applyMember2CardDesign() {

  const front =
    document.querySelector(
      ".discount-card.discount-front"
    );


  const back =
    document.querySelector(
      ".discount-card.discount-back"
    );


  if (
    !front ||
    !back
  ) {

    return;

  }


  installMember2CardStyles();


  const active =
    isMember2();


  /*
   * MEMBER 1
   */

  if (!active) {

    front.classList.remove(
      "member2-active"
    );

    back.classList.remove(
      "member2-active"
    );


    front.style.backgroundImage =
      "";


    back.style.backgroundImage =
      "";


    const oldFront =
      front.querySelector(
        ".member2-css-card"
      );


    if (oldFront) {

      oldFront.remove();

    }


    const oldBack =
      back.querySelector(
        ".member2-css-card"
      );


    if (oldBack) {

      oldBack.remove();

    }


    return;

  }


  /*
   * MEMBER 2
   */

  front.classList.add(
    "member2-active"
  );


  back.classList.add(
    "member2-active"
  );


  /*
   * Absolutely no Member 2
   * image backgrounds.
   */

  front.style.backgroundImage =
    "none";


  back.style.backgroundImage =
    "none";


  const frontCard =
    createMember2Front(
      front
    );


  const backCard =
    createMember2Back(
      back
    );


  const customer =
    state.customer ||
    {};


  const personal =
    getPersonalInformation();


  const name =
    getBestCustomerName(
      customer,
      personal
    ) ||
    "Member";


  const membership =
    customer.membership ||
    customer.membership_number ||
    customer.cardNo ||
    personal.cardNo ||
    "—";


  const expiry =
    getCustomerExpiry() ||
    "—";


  const issueBranch =
    getCustomerIssueBranch() ||
    "—";


  const nameElement =
    frontCard.querySelector(
      "#member2CardName"
    );


  const memberElement =
    frontCard.querySelector(
      "#member2CardMember"
    );


  const expiryElement =
    frontCard.querySelector(
      "#member2CardExpiry"
    );


  const branchElement =
    frontCard.querySelector(
      "#member2CardIssueBranch"
    );


  if (nameElement) {

    nameElement.textContent =
      name;

  }


  if (memberElement) {

    memberElement.textContent =
      membership;

  }


  if (expiryElement) {

    expiryElement.textContent =
      expiry;

  }


  if (branchElement) {

    branchElement.textContent =
      issueBranch;

  }


  /*
   * Synchronize barcode generated by backend.
   */

  const normalBarcode =
    $("barcodeImg");


  const member2Barcode =
    frontCard.querySelector(
      "#member2BarcodeImg"
    );


  if (
    normalBarcode &&
    member2Barcode &&
    normalBarcode.src
  ) {

    member2Barcode.src =
      normalBarcode.src;

  }

}


/* ============================================================
   RENDER CUSTOMER
   ============================================================ */

function renderCustomer() {

  const customer =
    state.customer;


  if (
    !customer
  ) {

    return;

  }


  const personal =
    getPersonalInformation();


  const actualName =
    getBestCustomerName(
      customer,
      personal
    );


  const name =
    actualName ||
    "Member";


  const membership =
    customer.membership ||
    customer.membership_number ||
    personal.cardNo ||
    "";


  const points =
    Number(
      customer.points ??
      customer.pointsBalance ??
      personal.points ??
      0
    );


  const expiry =
    getCustomerExpiry();


  const issueBranch =
    getCustomerIssueBranch();


  if (
    $("sideName")
  ) {

    $("sideName").textContent =
      name;

  }


  if (
    $("sideMember")
  ) {

    $("sideMember").textContent =
      membership;

  }


  if (
    $("welcomeName")
  ) {

    $("welcomeName").textContent =
      name;

  }


  if (
    $("discountCardName")
  ) {

    $("discountCardName").textContent =
      name;

  }


  if (
    $("discountCardMember")
  ) {

    $("discountCardMember").textContent =
      membership;

  }


  if (
    $("discountCardExpiry")
  ) {

    $("discountCardExpiry").textContent =
      expiry ||
      "—";

  }


  if (
    $("discountCardIssueBranch")
  ) {

    $("discountCardIssueBranch").textContent =
      issueBranch ||
      "—";

  }


  if (
    $("dashPoints")
  ) {

    $("dashPoints").textContent =
      String(points);

  }


  if (
    $("pointsBig")
  ) {

    $("pointsBig").textContent =
      String(points);

  }


  if (
    $("pointsEarned")
  ) {

    $("pointsEarned").textContent =
      String(
        Number(
          customer.pointsEarned ||
          0
        )
      );

  }


  const firstLetter =
    name.charAt(0)
      .toUpperCase() ||
    "M";


  if (
    $("sideAvatar")
  ) {

    $("sideAvatar").textContent =
      firstLetter;

  }


  if (
    $("topAvatar")
  ) {

    $("topAvatar").textContent =
      firstLetter;

  }


  /*
   * Member 2 must always be refreshed
   * after customer information changes.
   */

  applyMember2CardDesign();

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
        esc(label) +
      '</span>' +

      '<strong class="personal-info-value">' +
        esc(display) +
      '</strong>' +

    '</div>'

  );

}


function renderPersonalInformation(
  info
) {

  const grid =
    $("personalInfoGrid");


  if (
    !grid
  ) {

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


  if (
    grid
  ) {

    grid.innerHTML =
      '<div class="empty-feature">' +
        '<h2>Loading Personal Information...</h2>' +
        '<p>Fetching your member information from ARMS.</p>' +
      '</div>';

  }


  try {

    const result =
      await request(
        "/api/customer/personal-information",
        {
          method:
            "GET"
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


    if (
      !state.customer
    ) {

      state.customer =
        {};

    }


    state.customer.personalInformation =
      information;


    const realName =
      getBestCustomerName(
        state.customer,
        information
      );


    if (
      realName
    ) {

      state.customer.name =
        realName;

    }


    if (
      information.expiryDate
    ) {

      state.customer.expiryDate =
        information.expiryDate;

    }


    if (
      information.issueBranch
    ) {

      state.customer.issueBranch =
        information.issueBranch;

    }


    if (
      information.membershipType ||
      information.memberType
    ) {

      state.customer.membershipType =
        information.membershipType ||
        information.memberType;

    }


    renderCustomer();


    renderPersonalInformation(
      information
    );


  } catch (error) {

    console.error(
      "PERSONAL INFORMATION FAILED",
      error
    );


    if (
      grid
    ) {

      grid.innerHTML =
        '<div class="empty-feature">' +

          '<h2>Unable to load Personal Information</h2>' +

          '<p>' +
            esc(
              error?.message ||
              "Unable to load information from ARMS."
            ) +
          '</p>' +

          '<button class="primary" type="button" id="retryPersonalInformation">' +
            'Retry' +
          '</button>' +

        '</div>';


      const retry =
        $("retryPersonalInformation");


      if (
        retry
      ) {

        retry.addEventListener(
          "click",
          loadPersonalInformation
        );

      }

    }

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

    purchase.receipt ??

    purchase.receiptRefNo ??

    purchase.receipt_ref_no ??

    "-"

  );

}


function purchaseDate(
  purchase
) {

  return (

    purchase.date ??

    purchase.transaction_time ??

    purchase.transactionDate ??

    "-"

  );

}


function purchaseBranch(
  purchase
) {

  return (

    purchase.branch ??

    purchase.branch_name ??

    ""

  );

}


function purchaseCashier(
  purchase
) {

  return (

    purchase.cashier ??

    purchase.cashier_name ??

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

    purchase.amount ??

    0;


  const number =
    Number(value);


  return Number.isFinite(
    number
  )
    ? number
    : 0;

}


function purchasePoints(
  purchase
) {

  const value =
    purchase.points ??
    0;


  const number =
    Number(value);


  return Number.isFinite(
    number
  )
    ? number
    : 0;

}


/* ============================================================
   DASHBOARD
   ============================================================ */

function renderDashboard() {

  const dashboard =
    state.dashboard;


  if (
    !dashboard
  ) {

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


  if (
    $("dashSpend")
  ) {

    $("dashSpend").textContent =
      "RM " +
      totalSpend.toFixed(2);

  }


  if (
    $("dashTransactions")
  ) {

    $("dashTransactions").textContent =
      String(
        purchases.length
      );

  }


  if (
    $("pointsSpend")
  ) {

    $("pointsSpend").textContent =
      "RM " +
      totalSpend.toFixed(2);

  }


  if (
    $("purchaseList")
  ) {

    if (
      !purchases.length
    ) {

      $("purchaseList").innerHTML =
        '<div class="empty-feature">' +
          '<h2>No ARMS purchases returned</h2>' +
          '<p>No purchase records were returned for this membership.</p>' +
        '</div>';

    } else {

      $("purchaseList").innerHTML =

        purchases
          .map(
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

                  'class="purchase-card" ' +

                  'data-purchase-index="' +
                    index +
                  '"' +

                '>' +

                  '<div class="purchase-main">' +

                    '<b>Receipt #' +
                      esc(receipt) +
                    '</b>' +

                    '<span>' +

                      esc(date) +

                      (
                        branch
                          ? " · " +
                            esc(branch)
                          : ""
                      ) +

                      (
                        cashier
                          ? " · Cashier " +
                            esc(cashier)
                          : ""
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

                '</button>'

              );

            }
          )
          .join("");

    }

  }


  if (
    $("pointsRows")
  ) {

    if (
      !purchases.length
    ) {

      $("pointsRows").innerHTML =
        '<div class="empty-feature">' +
          '<p>No point transactions returned by ARMS.</p>' +
        '</div>';

    } else {

      $("pointsRows").innerHTML =

        purchases
          .map(
            function (
              purchase
            ) {

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
          )
          .join("");

    }

  }


  const rewards =
    Array.isArray(
      dashboard.rewards
    )
      ? dashboard.rewards
      : [];


  if (
    $("rewardsGrid")
  ) {

    $("rewardsGrid").innerHTML =

      rewards.length

        ? rewards
            .map(
              function (
                item
              ) {

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

              }
            )
            .join("")

        :

          '<div class="empty-feature">' +
            '<h2>Rewards</h2>' +
            '<p>No rewards are currently available.</p>' +
          '</div>';

  }


  const offers =
    Array.isArray(
      dashboard.offers
    )
      ? dashboard.offers
      : [];


  if (
    $("offersGrid")
  ) {

    $("offersGrid").innerHTML =

      offers.length

        ? offers
            .map(
              function (
                item
              ) {

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

              }
            )
            .join("")

        :

          '<div class="empty-feature">' +
            '<h2>Offers</h2>' +
            '<p>No member offers are currently available.</p>' +
          '</div>';

  }


  if (
    $("backendStatus")
  ) {

    $("backendStatus").textContent =
      "ARMS session online";

  }

}


/* ============================================================
   PURCHASE DETAILS
   ============================================================ */

function showPurchaseDetail(
  purchase
) {

  const history =
    $("purchaseHistoryView");


  const detailView =
    $("purchaseDetailView");


  const detail =
    $("purchaseDetail");


  if (
    !detailView ||
    !detail
  ) {

    return;

  }


  const items =
    purchase?.items ||
    purchase?.details ||
    purchase?.products ||
    purchase?.lineItems ||
    [];


  if (
    history
  ) {

    history.classList.add(
      "hidden"
    );

  }


  detailView.classList.remove(
    "hidden"
  );


  if (
    !items.length
  ) {

    detail.innerHTML =

      '<div class="empty-feature">' +

        '<h2>Purchase Details</h2>' +

        '<p>Item details are not available for this receipt.</p>' +

        '<p>' +
          esc(
            purchaseReceipt(
              purchase
            )
          ) +
        '</p>' +

        '<button ' +
          'class="primary" ' +
          'type="button" ' +
          'id="backPurchaseHistoryBtn"' +
        '>' +
          'Back to Purchase History' +
        '</button>' +

      '</div>';


  } else {

    detail.innerHTML =

      '<div class="purchase-detail-card">' +

        '<div class="purchase-detail-header">' +

          '<h2>Receipt #' +
            esc(
              purchaseReceipt(
                purchase
              )
            ) +
          '</h2>' +

          '<span>' +
            esc(
              purchaseDate(
                purchase
              )
            ) +
          '</span>' +

        '</div>' +


        '<div class="purchase-items">' +

          items
            .map(
              function (
                item
              ) {

                const name =
                  item.name ||
                  item.description ||
                  item.product_name ||
                  item.item_name ||
                  "Item";


                const quantity =
                  item.quantity ??
                  item.qty ??
                  1;


                const price =
                  Number(
                    item.price ??
                    item.amount ??
                    item.total ??
                    0
                  );


                return (

                  '<div class="purchase-item">' +

                    '<div>' +

                      '<strong>' +
                        esc(name) +
                      '</strong>' +

                      '<small>' +
                        'Qty: ' +
                        esc(quantity) +
                      '</small>' +

                    '</div>' +

                    '<strong>' +

                      'RM ' +
                      price.toFixed(2) +

                    '</strong>' +

                  '</div>'

                );

              }
            )
            .join("")

        + '</div>' +


        '<button ' +
          'class="primary" ' +
          'type="button" ' +
          'id="backPurchaseHistoryBtn"' +
        '>' +
          'Back to Purchase History' +
        '</button>' +

      '</div>';

  }


  const backButton =
    $("backPurchaseHistoryBtn");


  if (
    backButton
  ) {

    backButton.addEventListener(
      "click",
      function () {

        if (
          detailView
        ) {

          detailView.classList.add(
            "hidden"
          );

        }


        if (
          history
        ) {

          history.classList.remove(
            "hidden"
          );

        }

      }
    );

  }

}


/* ============================================================
   PURCHASE CLICK HANDLER
   ============================================================ */

function setupPurchaseDetails() {

  document.addEventListener(
    "click",
    function (
      event
    ) {

      const card =
        event.target.closest(
          "[data-purchase-index]"
        );


      if (
        !card
      ) {

        return;

      }


      const index =
        Number(
          card.dataset.purchaseIndex
        );


      const purchases =
        state.dashboard?.purchases ||
        [];


      if (
        !Number.isInteger(index) ||
        !purchases[index]
      ) {

        return;

      }


      showPurchaseDetail(
        purchases[index]
      );

    }
  );

}


/* ============================================================
   PURCHASE HISTORY
   ============================================================ */

async function loadPurchaseHistory() {

  const list =
    $("purchaseList");


  if (
    list
  ) {

    list.innerHTML =
      '<div class="empty-feature">' +
        '<h2>Loading Purchase History…</h2>' +
        '<p>Fetching ARMS purchase history.</p>' +
      '</div>';

  }


  try {

    const result =
      await request(
        "/api/customer/purchases",
        {
          method:
            "GET"
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


    if (
      result.pointsEarned !== undefined &&
      state.customer
    ) {

      state.customer.pointsEarned =
        Number(
          result.pointsEarned ||
          0
        );

    }


    renderCustomer();

    renderDashboard();


  } catch (error) {

    console.error(
      "PURCHASE HISTORY FAILED",
      error
    );


    if (
      list
    ) {

      list.innerHTML =

        '<div class="empty-feature">' +

          '<h2>Purchase History</h2>' +

          '<p>Unable to load ARMS purchase history.</p>' +

          '<p>' +
            esc(
              error.message
            ) +
          '</p>' +

          '<button ' +
            'class="primary" ' +
            'type="button" ' +
            'id="retryPurchasesBtn"' +
          '>' +
            'Retry' +
          '</button>' +

        '</div>';


      const retry =
        $("retryPurchasesBtn");


      if (
        retry
      ) {

        retry.addEventListener(
          "click",
          loadPurchaseHistory
        );

      }

    }

  }

}


/* ============================================================
   CARD VISUALS
   ============================================================ */

async function loadCardVisuals() {

  try {

    const data =
      await request(
        "/api/customer/card-visuals",
        {
          method:
            "GET"
        }
      );


    if (
      data.barcodeDataUrl &&
      $("barcodeImg")
    ) {

      $("barcodeImg").src =
        data.barcodeDataUrl;

    }


    applyMember2CardDesign();


  } catch (error) {

    console.error(
      "CARD VISUALS FAILED",
      error
    );

  }

}


/* ============================================================
   MEMBERSHIP CARD SYNC
   ============================================================ */

async function syncMembershipCard() {

  try {

    const result =
      await request(
        "/api/customer/personal-information",
        {
          method:
            "GET"
        }
      );


    if (
      result?.personalInformation
    ) {

      const information =
        result.personalInformation;


      if (
        !state.customer
      ) {

        state.customer =
          {};

      }


      state.customer.personalInformation =
        information;


      const name =
        getBestCustomerName(
          state.customer,
          information
        );


      if (
        name
      ) {

        state.customer.name =
          name;

      }


      if (
        information.expiryDate
      ) {

        state.customer.expiryDate =
          information.expiryDate;

      }


      if (
        information.issueBranch
      ) {

        state.customer.issueBranch =
          information.issueBranch;

      }


      if (
        information.membershipType ||
        information.memberType
      ) {

        state.customer.membershipType =
          information.membershipType ||
          information.memberType;

      }


      renderCustomer();

    }

  } catch (error) {

    console.error(
      "MEMBERSHIP CARD SYNC FAILED",
      error
    );

  }

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
      function (
        section
      ) {

        section.classList.add(
          "hidden"
        );

      }
    );


  const selected =
    $(
      "view-" +
      view
    );


  if (
    selected
  ) {

    selected.classList.remove(
      "hidden"
    );

  }


  document
    .querySelectorAll(
      ".nav-item"
    )
    .forEach(
      function (
        item
      ) {

        item.classList.toggle(
          "active",
          item.dataset.view === view
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


  if (
    $("pageTitle")
  ) {

    $("pageTitle").textContent =
      titles[view] ||
      "Dashboard";

  }


  if (
    view === "personal" &&
    state.authenticated
  ) {

    loadPersonalInformation();

  }


  if (
    view === "dashboard" &&
    state.authenticated
  ) {

    syncMembershipCard();

  }


  if (
    $("sidebar")
  ) {

    $("sidebar")
      .classList
      .remove("open");

  }

}


/* ============================================================
   NAVIGATION SETUP
   ============================================================ */

function setupNavigation() {

  document
    .querySelectorAll(
      "[data-view]"
    )
    .forEach(
      function (
        element
      ) {

        element.addEventListener(
          "click",
          function () {

            const view =
              element.dataset.view;


            if (
              view === "store"
            ) {

              window.location.href =
                "https://hasanibooks.com/";

              return;

            }


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
              view === "purchases"
            ) {

              loadPurchaseHistory();

            }

          }
        );

      }
    );


  if (
    $("menuBtn")
  ) {

    $("menuBtn").addEventListener(
      "click",
      function () {

        if (
          $("sidebar")
        ) {

          $("sidebar")
            .classList
            .toggle("open");

        }

      }
    );

  }


  if (
    $("logoutBtn")
  ) {

    $("logoutBtn").addEventListener(
      "click",
      logout
    );

  }


  if (
    $("openStoreBtn")
  ) {

    $("openStoreBtn").addEventListener(
      "click",
      function () {

        window.location.href =
          "https://hasanibooks.com/";

      }
    );

  }


  if (
    $("openLocationsBtn")
  ) {

    $("openLocationsBtn").addEventListener(
      "click",
      function () {

        window.location.href =
          "https://hasanibooks.com/store-locator";

      }
    );

  }

}


/* ============================================================
   LOGIN
   ============================================================ */

async function login(
  event
) {

  event.preventDefault();


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


  if (
    !membership
  ) {

    if (
      $("loginMessage")
    ) {

      $("loginMessage").textContent =
        "Please enter your membership card number.";

    }

    return;

  }


  if (
    !password
  ) {

    if (
      $("loginMessage")
    ) {

      $("loginMessage").textContent =
        "Please enter your password.";

    }

    return;

  }


  if (
    $("loginMessage")
  ) {

    $("loginMessage").textContent =
      "Signing in to ARMS…";

  }


  try {

    const loginData =
      await request(
        "/api/customer/login",
        {
          method:
            "POST",

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


    const me =
      await request(
        "/api/customer/me",
        {
          method:
            "GET"
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


    if (
      me.customer
    ) {

      state.customer =
        me.customer;

    }


    state.dashboard = {

      ok:
        true,

      source:
        "ARMS",

      customer:
        state.customer,

      purchases:
        [],

      rewards:
        [],

      offers:
        [],

      locations:
        [],

      integration: {

        armsAuthenticated:
          true,

        historyLoading:
          true,

        historyMessage:
          "Purchase history is loading."

      }

    };


    showApp();


    renderCustomer();

    renderDashboard();


    await loadPersonalInformation();

    await loadCardVisuals();

    await loadPurchaseHistory();


    showView(
      "dashboard"
    );


    if (
      $("loginMessage")
    ) {

      $("loginMessage").textContent =
        "";

    }


  } catch (error) {

    console.error(
      "LOGIN FAILED",
      error
    );


    showLogin(
      error.message ||
      "Login failed."
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
        method:
          "POST"
      }
    );

  } catch (error) {

    /*
     * Clear local state even if
     * backend logout fails.
     */

  }


  clearState();

  showLogin(
    ""
  );


  if (
    $("loginPassword")
  ) {

    $("loginPassword").value =
      "123123";

  }

}


/* ============================================================
   INITIAL SESSION CHECK
   ============================================================ */

async function checkExistingSession() {

  try {

    const result =
      await request(
        "/api/customer/me",
        {
          method:
            "GET"
        }
      );


    if (
      result &&
      result.ok &&
      result.authenticated
    ) {

      state.customer =
        result.customer ||
        null;


      state.authenticated =
        true;


      state.dashboard = {

        ok:
          true,

        source:
          "ARMS",

        customer:
          state.customer,

        purchases:
          [],

        rewards:
          [],

        offers:
          [],

        locations:
          [],

        integration: {

          armsAuthenticated:
            true,

          historyLoading:
            true

        }

      };


      showApp();


      renderCustomer();

      renderDashboard();

      await loadPersonalInformation();

      await loadCardVisuals();

      await loadPurchaseHistory();

      showView(
        "dashboard"
      );


      return;

    }

  } catch (error) {

    console.log(
      "No existing customer session."
    );

  }


  showLogin(
    ""
  );

}


/* ============================================================
   START APPLICATION
   ============================================================ */

document.addEventListener(
  "DOMContentLoaded",
  function () {

    installMember2CardStyles();

    setupNavigation();

    setupPurchaseDetails();


    if (
      $("loginForm")
    ) {

      $("loginForm").addEventListener(
        "submit",
        login
      );

    }


    /*
     * Make sure Member 1 is shown
     * until customer data determines
     * that the member is Member 2.
     */

    applyMember2CardDesign();


    checkExistingSession();

  }
);