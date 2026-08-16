/**
 * Hasani ARMS Customer Integration
 *
 * Complete ES module.
 *
 * IMPORTANT:
 * server.js imports these named exports:
 *
 *   getTransactionDetail
 *   getMembershipHistory
 *   getCustomerDataFromArms
 *   getVerifiedTransactionForDemo
 *
 * ARMS member:
 *   /membership.php?t=history&a=i&nric={membership}
 *
 * ARMS sales history:
 *   /counter_collection.php
 *     ?a=sales_details
 *     &date=YYYY-MM-DD
 *     &card_no=MEMBERSHIP
 *     &branch_id=12
 *
 * ARMS transaction detail:
 *   /counter_collection.php
 *     ?a=print_tran_details
 *     &branch_id=...
 *     &date=...
 *     &counter_id=...
 *     &pos_id=...
 *
 * Credentials remain server-side in .env.
 */

const BASE_URL =
  process.env.ARMS_BASE_URL ||
  "https://hasani.arms.com.my";

const HISTORY_TEMPLATE =
  process.env.ARMS_HISTORY_URL_TEMPLATE ||
  "/membership.php?t=history&a=i&nric={membership}";

const TIMEOUT_MS =
  Number(process.env.ARMS_TIMEOUT_MS || 20000);

const MAX_TRANSACTIONS =
  Number(
    process.env.ARMS_TRANSACTION_DETAIL_LIMIT || 20
  );

const FETCH_TRANSACTION_DETAILS =
  String(
    process.env.ARMS_FETCH_TRANSACTION_DETAILS ||
      "true"
  ).toLowerCase() !== "false";

/*
 * IMPORTANT:
 *
 * The sales_details endpoint requires a DATE.
 *
 * Default:
 *   Search the latest 120 days.
 *
 * You can change this in .env:
 *
 *   ARMS_SALES_LOOKBACK_DAYS=180
 *
 * Or:
 *
 *   ARMS_SALES_START_DATE=2026-01-01
 *   ARMS_SALES_END_DATE=2026-08-15
 */
const SALES_LOOKBACK_DAYS =
  Number(
    process.env.ARMS_SALES_LOOKBACK_DAYS || 3650
  );

const SALES_START_DATE =
  process.env.ARMS_SALES_START_DATE ||
  "2016-08-15";

const SALES_END_DATE =
  process.env.ARMS_SALES_END_DATE || "";

const SALES_BRANCH_ID =
  process.env.ARMS_SALES_BRANCH_ID || "12";

const SALES_CONCURRENCY =
  Math.max(
    1,
    Number(
      process.env.ARMS_SALES_CONCURRENCY || 5
    )
  );

const SALES_MAX_RESULTS =
  Math.max(
    1,
    Number(
      process.env.ARMS_SALES_MAX_RESULTS || 200
    )
  );


/* ==========================================================================
   BASIC HELPERS
   ========================================================================== */

function cleanText(value) {
  return String(
    value === undefined || value === null
      ? ""
      : value
  )
    .replace(/\u00a0/g, " ")
    .replace(/\r/g, "")
    .replace(/\t/g, " ")
    .replace(/[ ]+/g, " ")
    .trim();
}


function decodeHtml(value) {
  return String(
    value === undefined || value === null
      ? ""
      : value
  )
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/gi, "'")
    .replace(/&#x27;/gi, "'")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(
      /&#(\d+);/g,
      function (_, number) {
        return String.fromCharCode(
          Number(number)
        );
      }
    )
    .replace(
      /&#x([0-9a-f]+);/gi,
      function (_, number) {
        return String.fromCharCode(
          parseInt(number, 16)
        );
      }
    );
}


function htmlToText(html) {
  return cleanText(
    String(
      html === undefined || html === null
        ? ""
        : html
    )
      .replace(
        /<script\b[^>]*>[\s\S]*?<\/script>/gi,
        " "
      )
      .replace(
        /<style\b[^>]*>[\s\S]*?<\/style>/gi,
        " "
      )
      .replace(/<[^>]+>/g, " ")
  );
}


/*
 * Manual implementation.
 *
 * This avoids the regex syntax problem that happened
 * previously in arms.js.
 */
function escapeRegExp(value) {
  const input = String(
    value === undefined || value === null
      ? ""
      : value
  );

  let output = "";

  for (
    let i = 0;
    i < input.length;
    i += 1
  ) {
    const character =
      input[i];

    if (
      character === "\\" ||
      character === "^" ||
      character === "$" ||
      character === "." ||
      character === "*" ||
      character === "+" ||
      character === "?" ||
      character === "(" ||
      character === ")" ||
      character === "[" ||
      character === "]" ||
      character === "{" ||
      character === "}" ||
      character === "|"
    ) {
      output += "\\" + character;
    } else {
      output += character;
    }
  }

  return output;
}


function normalizeMembership(value) {
  return String(
    value === undefined || value === null
      ? ""
      : value
  )
    .trim()
    .replace(/\s+/g, "");
}


function absoluteUrl(pathOrUrl) {
  if (!pathOrUrl) {
    return BASE_URL;
  }

  if (
    /^https?:\/\//i.test(
      pathOrUrl
    )
  ) {
    return pathOrUrl;
  }

  return new URL(
    pathOrUrl,
    BASE_URL
  ).toString();
}


function parseNumber(value) {
  const cleaned =
    String(
      value === undefined ||
      value === null
        ? ""
        : value
    )
      .replace(/,/g, "")
      .replace(/[^\d.-]/g, "")
      .trim();

  if (
    !cleaned ||
    cleaned === "-"
  ) {
    return 0;
  }

  const number =
    Number(cleaned);

  return Number.isFinite(number)
    ? number
    : 0;
}


function parseMoney(value) {
  const cleaned =
    String(
      value === undefined ||
      value === null
        ? ""
        : value
    )
      .replace(/,/g, "")
      .replace(/[^\d.-]/g, "")
      .trim();

  if (
    !cleaned ||
    cleaned === "-"
  ) {
    return 0;
  }

  const number =
    Number(cleaned);

  return Number.isFinite(number)
    ? number
    : 0;
}


/* ==========================================================================
   DATE HELPERS
   ========================================================================== */

function pad2(value) {
  return String(value).padStart(
    2,
    "0"
  );
}


function formatDate(date) {
  return (
    date.getFullYear() +
    "-" +
    pad2(date.getMonth() + 1) +
    "-" +
    pad2(date.getDate())
  );
}


function parseDateOnly(value) {
  const match =
    String(
      value || ""
    ).match(
      /^(\d{4})-(\d{2})-(\d{2})$/
    );

  if (!match) {
    return null;
  }

  const year =
    Number(match[1]);

  const month =
    Number(match[2]) - 1;

  const day =
    Number(match[3]);

  const date =
    new Date(
      year,
      month,
      day
    );

  if (
    date.getFullYear() !== year ||
    date.getMonth() !== month ||
    date.getDate() !== day
  ) {
    return null;
  }

  return date;
}


function getSalesDateRange() {
  let endDate;

  if (SALES_END_DATE) {
    endDate =
      parseDateOnly(
        SALES_END_DATE
      );
  }

  if (!endDate) {
    endDate =
      new Date();
  }

  let startDate;

  if (SALES_START_DATE) {
    startDate =
      parseDateOnly(
        SALES_START_DATE
      );
  }

  if (!startDate) {
    startDate =
      new Date(
        endDate.getTime()
      );

    startDate.setDate(
      startDate.getDate() -
        SALES_LOOKBACK_DAYS +
        1
    );
  }

  if (
    startDate > endDate
  ) {
    const temporary =
      startDate;

    startDate =
      endDate;

    endDate =
      temporary;
  }

  return {
    startDate,
    endDate
  };
}


function buildDateList() {
  const range =
    getSalesDateRange();

  const dates = [];

  const current =
    new Date(
      range.endDate.getTime()
    );

  while (
    current >= range.startDate
  ) {
    dates.push(
      formatDate(current)
    );

    current.setDate(
      current.getDate() - 1
    );
  }

  return dates;
}


/* ==========================================================================
   COOKIE JAR
   ========================================================================== */

function parseSetCookieHeaders(
  headers
) {
  if (
    headers &&
    typeof headers.getSetCookie ===
      "function"
  ) {
    const values =
      headers.getSetCookie();

    if (
      Array.isArray(values) &&
      values.length
    ) {
      return values;
    }
  }

  if (!headers) {
    return [];
  }

  const combined =
    headers.get(
      "set-cookie"
    );

  if (!combined) {
    return [];
  }

  return combined.split(
    /,(?=\s*[A-Za-z0-9_.-]+=)/
  );
}


function updateCookieJar(
  jar,
  headers
) {
  const cookies =
    parseSetCookieHeaders(
      headers
    );

  for (
    const cookie of cookies
  ) {
    const firstPart =
      String(cookie).split(
        ";"
      )[0];

    const separator =
      firstPart.indexOf("=");

    if (
      separator <= 0
    ) {
      continue;
    }

    const name =
      firstPart
        .slice(
          0,
          separator
        )
        .trim();

    const value =
      firstPart
        .slice(
          separator + 1
        )
        .trim();

    if (name) {
      jar.set(
        name,
        value
      );
    }
  }
}


function cookieHeader(jar) {
  const values = [];

  for (
    const entry of jar.entries()
  ) {
    values.push(
      String(entry[0]) +
        "=" +
        String(entry[1])
    );
  }

  return values.join(
    "; "
  );
}


/* ==========================================================================
   ARMS HTTP
   ========================================================================== */

async function armsFetch(
  url,
  options,
  jar
) {
  const requestOptions =
    options || {};

  const cookieJar =
    jar instanceof Map
      ? jar
      : new Map();

  const controller =
    new AbortController();

  const timeout =
    setTimeout(
      function () {
        controller.abort();
      },
      requestOptions.timeoutMs ||
        TIMEOUT_MS
    );

  try {
    const headers =
      new Headers(
        requestOptions.headers ||
          {}
      );

    if (
      !headers.has(
        "User-Agent"
      )
    ) {
      headers.set(
        "User-Agent",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/151 Safari/537.36"
      );
    }

    if (
      !headers.has(
        "Accept"
      )
    ) {
      headers.set(
        "Accept",
        "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
      );
    }

    const cookies =
      cookieHeader(
        cookieJar
      );

    if (cookies) {
      headers.set(
        "Cookie",
        cookies
      );
    }

    const response =
      await fetch(
        url,
        {
          method:
            requestOptions.method ||
            "GET",

          headers,

          body:
            requestOptions.body,

          redirect:
            requestOptions.redirect ||
            "manual",

          signal:
            controller.signal
        }
      );

    updateCookieJar(
      cookieJar,
      response.headers
    );

    return response;
  } finally {
    clearTimeout(
      timeout
    );
  }
}


async function readResponseBody(
  response
) {
  return response.text();
}


/* ==========================================================================
   ARMS LOGIN
   ========================================================================== */

function buildLoginBody() {
  const params =
    new URLSearchParams();

  params.set(
    "login_branch",
    process.env.ARMS_LOGIN_BRANCH ||
      "HQ"
  );

  params.set(
    "u",
    process.env.ARMS_USERNAME ||
      ""
  );

  params.set(
    "p",
    process.env.ARMS_PASSWORD ||
      ""
  );

  params.set(
    "tnc",
    process.env.ARMS_TNC ||
      "1"
  );

  return params;
}


function loginPageLooksPresent(
  html
) {
  const source =
    String(html || "");

  return (
    /name\s*=\s*["']u["']/i.test(
      source
    ) &&
    /name\s*=\s*["']p["']/i.test(
      source
    )
  );
}


function looksAuthenticated(
  html
) {
  const source =
    String(html || "");

  if (!source) {
    return false;
  }

  if (
    loginPageLooksPresent(
      source
    )
  ) {
    return false;
  }

  const text =
    htmlToText(
      source
    ).toLowerCase();

  const indicators = [
    "membership",
    "hasani",
    "arms",
    "retail management system"
  ];

  for (
    const indicator of indicators
  ) {
    if (
      text.includes(
        indicator
      )
    ) {
      return true;
    }
  }

  return false;
}


async function loginToArmsInternal() {
  const username =
    process.env.ARMS_USERNAME ||
    "";

  const password =
    process.env.ARMS_PASSWORD ||
    "";

  if (
    !username ||
    !password
  ) {
    const error =
      new Error(
        "ARMS_USERNAME and ARMS_PASSWORD are required."
      );

    error.code =
      "ARMS_CONFIGURATION_ERROR";

    throw error;
  }

  const jar =
    new Map();

  const loginUrl =
    absoluteUrl(
      "/login.php"
    );

  /*
   * Establish ARMS PHP session.
   */
  const loginPage =
    await armsFetch(
      loginUrl,
      {
        method: "GET",
        redirect: "manual"
      },
      jar
    );

  await readResponseBody(
    loginPage
  );

  /*
   * Submit ARMS credentials.
   */
  const loginResponse =
    await armsFetch(
      loginUrl,
      {
        method: "POST",

        headers: {
          "Content-Type":
            "application/x-www-form-urlencoded",

          "Referer":
            loginUrl,

          "Origin":
            BASE_URL
        },

        body:
          buildLoginBody(),

        redirect:
          "manual"
      },
      jar
    );

  let body =
    await readResponseBody(
      loginResponse
    );

  let finalUrl =
    loginUrl;

  let location =
    loginResponse.headers.get(
      "location"
    );

  let redirects = 0;

  while (
    location &&
    redirects < 8
  ) {
    redirects += 1;

    const nextUrl =
      new URL(
        location,
        finalUrl
      ).toString();

    const nextResponse =
      await armsFetch(
        nextUrl,
        {
          method: "GET",

          headers: {
            "Referer":
              finalUrl
          },

          redirect:
            "manual"
        },
        jar
      );

    body =
      await readResponseBody(
        nextResponse
      );

    finalUrl =
      nextUrl;

    location =
      nextResponse.headers.get(
        "location"
      );
  }

  if (
    !looksAuthenticated(
      body
    )
  ) {
    const error =
      new Error(
        "ARMS authentication failed. ARMS did not return an authenticated page."
      );

    error.code =
      "ARMS_LOGIN_FAILED";

    throw error;
  }

  return {
    jar,
    html: body,
    url: finalUrl
  };
}


/* ==========================================================================
   TABLE PARSING
   ========================================================================== */

function extractTableValue(
  html,
  label
) {
  const source =
    String(html || "");

  const safeLabel =
    escapeRegExp(
      label
    );

  const patterns = [
    new RegExp(
      "<tr[^>]*>\\s*" +
        "<td[^>]*>\\s*" +
        "(?:<[^>]+>\\s*)*" +
        safeLabel +
        "\\s*" +
        "(?:</[^>]+>\\s*)*" +
        "</td>\\s*" +
        "<td[^>]*>([\\s\\S]*?)</td>",
      "i"
    ),

    new RegExp(
      "<b>\\s*" +
        safeLabel +
        "\\s*</b>" +
        "\\s*</td>\\s*" +
        "<td[^>]*>([\\s\\S]*?)</td>",
      "i"
    )
  ];

  for (
    const pattern of patterns
  ) {
    const match =
      source.match(
        pattern
      );

    if (!match) {
      continue;
    }

    const value =
      cleanText(
        decodeHtml(
          htmlToText(
            match[1]
          )
        )
      );

    if (value) {
      return value;
    }
  }

  return null;
}


function extractFieldFromText(
  html,
  label
) {
  const text =
    htmlToText(
      html
    );

  const safeLabel =
    escapeRegExp(
      label
    );

  const pattern =
    new RegExp(
      safeLabel +
        "\\s*:?\\s*([^\\n]{1,200})",
      "i"
    );

  const match =
    text.match(
      pattern
    );

  if (!match) {
    return null;
  }

  return cleanText(
    match[1]
  );
}


/* ==========================================================================
   MEMBER PROFILE
   ========================================================================== */

function extractMemberName(
  html
) {
  const direct =
    extractTableValue(
      html,
      "Name"
    );

  if (direct) {
    return direct;
  }

  const fallback =
    extractFieldFromText(
      html,
      "Name"
    );

  if (fallback) {
    return fallback;
  }

  const labels = [
    "Customer Name",
    "Member Name",
    "Full Name"
  ];

  for (
    const label of labels
  ) {
    const value =
      extractTableValue(
        html,
        label
      ) ||
      extractFieldFromText(
        html,
        label
      );

    if (value) {
      return value;
    }
  }

  return null;
}


function extractMembershipNumber(
  html
) {
  const candidates = [
    extractTableValue(
      html,
      "Current Hasani Number"
    ),

    extractTableValue(
      html,
      "NRIC"
    ),

    extractTableValue(
      html,
      "Membership No."
    ),

    extractTableValue(
      html,
      "Membership Number"
    )
  ];

  for (
    const candidate of candidates
  ) {
    if (candidate) {
      return normalizeMembership(
        candidate
      );
    }
  }

  /*
   * ARMS pages can contain:
   *
   * var nric = '000101020212';
   */
  const jsMatch =
    String(
      html || ""
    ).match(
      /var\s+nric\s*=\s*['"]([^'"]+)['"]/i
    );

  if (
    jsMatch &&
    jsMatch[1]
  ) {
    return normalizeMembership(
      jsMatch[1]
    );
  }

  const text =
    htmlToText(
      html
    );

  const patterns = [
    /\bCurrent Hasani Number\s*:?\s*([A-Za-z0-9-]+)/i,
    /\bNRIC\s*:?\s*([A-Za-z0-9-]+)/i,
    /\bMembership\s+No\.?\s*:?\s*([A-Za-z0-9-]+)/i,
    /\bMembership\s+Number\s*:?\s*([A-Za-z0-9-]+)/i
  ];

  for (
    const pattern of patterns
  ) {
    const match =
      text.match(
        pattern
      );

    if (
      match &&
      match[1]
    ) {
      return normalizeMembership(
        match[1]
      );
    }
  }

  return null;
}


function extractPoints(
  html
) {
  const tableValue =
    extractTableValue(
      html,
      "Points Accumulated"
    );

  if (tableValue) {
    return parseNumber(
      tableValue
    );
  }

  const text =
    htmlToText(
      html
    );

  const match =
    text.match(
      /Points\s+Accumulated\s*:?\s*(-?\d+(?:\.\d+)?)/i
    );

  return match
    ? Number(
        match[1]
      )
    : 0;
}


function extractPointsUpdate(
  html
) {
  return (
    extractTableValue(
      html,
      "Points Update"
    ) ||
    extractTableValue(
      html,
      "Last Points Update"
    ) ||
    null
  );
}


function extractIssueBranch(
  html
) {
  return (
    extractTableValue(
      html,
      "Issue Branch"
    ) || null
  );
}


function extractIssueDate(
  html
) {
  return (
    extractTableValue(
      html,
      "Issue Date"
    ) || null
  );
}


function extractExpiryDate(
  html
) {
  return (
    extractTableValue(
      html,
      "Next Expiry Date"
    ) || null
  );
}


function extractMemberType(
  html
) {
  return (
    extractTableValue(
      html,
      "Member Type"
    ) || null
  );
}


function extractGender(
  html
) {
  return (
    extractTableValue(
      html,
      "Gender"
    ) || null
  );
}


function extractBirthday(
  html
) {
  return (
    extractTableValue(
      html,
      "Birthday"
    ) || null
  );
}


/* ==========================================================================
   MEMBERSHIP HISTORY URL
   ========================================================================== */

function buildHistoryUrl(
  membership
) {
  const normalized =
    normalizeMembership(
      membership
    );

  const encoded =
    encodeURIComponent(
      normalized
    );

  let path =
    HISTORY_TEMPLATE;

  path =
    path.replace(
      /\{membership(?:_no)?\}/gi,
      encoded
    );

  path =
    path.replace(
      /\{nric\}/gi,
      encoded
    );

  return absoluteUrl(
    path
  );
}


/* ==========================================================================
   TRANSACTION CALL PARSER
   ========================================================================== */

function extractTransDetailCalls(
  html
) {
  const results = [];

  const source =
    String(
      html || ""
    );

  const pattern =
    /trans_detail\s*\(\s*(['"])([^'"]+)\1\s*,\s*(['"])([^'"]+)\3\s*,\s*(['"])([^'"]+)\5\s*,\s*(['"])([^'"]+)\7\s*,\s*(['"])([^'"]+)\9\s*\)/gi;

  let match;

  while (
    (match =
      pattern.exec(
        source
      ))
  ) {
    results.push({
      counter_id:
        match[2],

      cashier_id:
        match[4],

      date:
        match[6],

      pos_id:
        match[8],

      branch_id:
        match[10]
    });
  }

  return results;
}


/* ==========================================================================
   OLD MEMBERSHIP-PAGE PURCHASE PARSER
   ========================================================================== */

function extractPurchaseRows(
  html
) {
  const rows = [];

  const source =
    String(
      html || ""
    );

  const rowPattern =
    /<tr\b[^>]*>([\s\S]*?)<\/tr>/gi;

  let rowMatch;

  while (
    (rowMatch =
      rowPattern.exec(
        source
      ))
  ) {
    const rowHtml =
      rowMatch[1];

    if (
      !/trans_detail\s*\(/i.test(
        rowHtml
      )
    ) {
      continue;
    }

    const cells = [];

    const cellPattern =
      /<td\b[^>]*>([\s\S]*?)<\/td>/gi;

    let cellMatch;

    while (
      (cellMatch =
        cellPattern.exec(
          rowHtml
        ))
    ) {
      cells.push(
        cleanText(
          decodeHtml(
            htmlToText(
              cellMatch[1]
            )
          )
        )
      );
    }

    if (
      cells.length < 5
    ) {
      continue;
    }

    const calls =
      extractTransDetailCalls(
        rowHtml
      );

    const detail =
      calls.length
        ? calls[0]
        : null;

    rows.push({
      transaction_time:
        cells[0] || null,

      receipt_no:
        cells[1] || null,

      receipt_ref_no:
        cells[2] || null,

      cashier:
        cells[3] || null,

      payment_amount:
        parseMoney(
          cells[4]
        ),

      points:
        parseNumber(
          cells[5]
        ),

      over:
        cells[6] || null,

      transaction_detail:
        detail
    });
  }

  return deduplicatePurchases(
    rows
  );
}


/* ==========================================================================
   SALES DETAILS - THE IMPORTANT NEW PART
   ========================================================================== */

/*
 * Build the exact endpoint you supplied:
 *
 * /counter_collection.php
 *   ?a=sales_details
 *   &date=2026-05-16
 *   &card_no=000101020212
 *   &branch_id=12
 */
function buildSalesDetailsUrl(
  date,
  membership,
  branchId
) {
  const params =
    new URLSearchParams();

  params.set(
    "a",
    "sales_details"
  );

  params.set(
    "date",
    date
  );

  params.set(
    "card_no",
    normalizeMembership(
      membership
    )
  );

  params.set(
    "branch_id",
    String(
      branchId ||
        SALES_BRANCH_ID
    )
  );

  return (
    absoluteUrl(
      "/counter_collection.php"
    ) +
    "?" +
    params.toString()
  );
}


/*
 * Parse one sales_details response.
 *
 * Confirmed ARMS columns:
 *
 * Transaction Time
 * Receipt No
 * Receipt Ref. No
 * Cashier
 * Payment Amount
 * Points
 * Over
 */
function extractSalesDetailRows(
  html,
  requestedDate,
  membership
) {
  const rows = [];

  const source =
    String(
      html || ""
    );

  const rowPattern =
    /<tr\b[^>]*>([\s\S]*?)<\/tr>/gi;

  let rowMatch;

  while (
    (rowMatch =
      rowPattern.exec(
        source
      ))
  ) {
    const rowHtml =
      rowMatch[1];

    const cells = [];

    const cellPattern =
      /<td\b[^>]*>([\s\S]*?)<\/td>/gi;

    let cellMatch;

    while (
      (cellMatch =
        cellPattern.exec(
          rowHtml
        ))
    ) {
      cells.push(
        cleanText(
          decodeHtml(
            htmlToText(
              cellMatch[1]
            )
          )
        )
      );
    }

    /*
     * Header row has TH, not TD.
     */
    if (
      cells.length < 5
    ) {
      continue;
    }

    /*
     * Ignore total row.
     */
    const joined =
      cells.join(
        " "
      );

    if (
      /^total$/i.test(
        cells[0] || ""
      ) ||
      /transaction time\s+receipt/i.test(
        joined
      )
    ) {
      continue;
    }

    /*
     * Ignore empty rows.
     */
    if (
      !cells[0] &&
      !cells[1] &&
      !cells[2]
    ) {
      continue;
    }

    /*
     * Sales detail has:
     *
     * 0 Transaction Time
     * 1 Receipt No
     * 2 Receipt Ref No
     * 3 Cashier
     * 4 Payment Amount
     * 5 Points
     * 6 Over
     */
    const transactionTime =
      cells[0] || null;

    const receiptNo =
      cells[1] || null;

    const receiptRefNo =
      cells[2] || null;

    /*
     * A genuine transaction must have
     * either receipt or transaction time.
     */
    if (
      !transactionTime &&
      !receiptNo
    ) {
      continue;
    }

    rows.push({
      transaction_time:
        transactionTime,

      receipt_no:
        receiptNo,

      receipt_ref_no:
        receiptRefNo,

      cashier:
        cells[3] || null,

      payment_amount:
        parseMoney(
          cells[4]
        ),

      points:
        parseNumber(
          cells[5]
        ),

      over:
        cells[6] || null,

      /*
       * sales_details itself does not expose
       * the trans_detail() arguments.
       *
       * We preserve the date and membership so
       * the frontend can identify the source.
       */
      sales_date:
        requestedDate,

      membership:
        normalizeMembership(
          membership
        ),

      branch_id:
        SALES_BRANCH_ID,

      source:
        "ARMS sales_details"
    });
  }

  return rows;
}


/*
 * One date -> ARMS sales_details.
 */
async function fetchSalesDetailsForDate(
  jar,
  membership,
  date
) {
  const url =
    buildSalesDetailsUrl(
      date,
      membership,
      SALES_BRANCH_ID
    );

  const response =
    await armsFetch(
      url,
      {
        method: "GET",

        headers: {
          "Referer":
            buildHistoryUrl(
              membership
            )
        },

        redirect:
          "manual"
      },
      jar
    );

  let html =
    await readResponseBody(
      response
    );

  let finalUrl =
    url;

  /*
   * Follow redirects.
   */
  let location =
    response.headers.get(
      "location"
    );

  let redirects = 0;

  while (
    location &&
    redirects < 5
  ) {
    redirects += 1;

    const nextUrl =
      new URL(
        location,
        finalUrl
      ).toString();

    const nextResponse =
      await armsFetch(
        nextUrl,
        {
          method: "GET",

          headers: {
            "Referer":
              finalUrl
          },

          redirect:
            "manual"
        },
        jar
      );

    html =
      await readResponseBody(
        nextResponse
      );

    finalUrl =
      nextUrl;

    location =
      nextResponse.headers.get(
        "location"
      );
  }

  if (
    response.status >= 400
  ) {
    return {
      date,
      url: finalUrl,
      purchases: [],
      status:
        response.status
    };
  }

  /*
   * If ARMS sends us back to login,
   * tell the caller to retry with a new session.
   */
  if (
    loginPageLooksPresent(
      html
    )
  ) {
    const error =
      new Error(
        "ARMS sales history session expired."
      );

    error.code =
      "ARMS_SESSION_EXPIRED";

    throw error;
  }

  return {
    date,
    url: finalUrl,
    purchases:
      extractSalesDetailRows(
        html,
        date,
        membership
      ),

    status:
      response.status
  };
}


/*
 * Search multiple dates.
 *
 * We use a small concurrency limit so ARMS
 * is not flooded with requests.
 */
async function fetchSalesHistory(
  jar,
  membership
) {
  const dates =
    buildDateList();

  const allRows = [];

  let nextIndex = 0;

  async function worker() {
    while (true) {
      const index =
        nextIndex;

      nextIndex += 1;

      if (
        index >= dates.length
      ) {
        return;
      }

      const date =
        dates[index];

      try {
        const result =
          await fetchSalesDetailsForDate(
            jar,
            membership,
            date
          );

        if (
          result.purchases &&
          result.purchases.length
        ) {
          allRows.push(
            ...result.purchases
          );
        }
      } catch (error) {
        /*
         * If one date fails because the ARMS
         * session expired, propagate it.
         */
        if (
          error &&
          error.code ===
            "ARMS_SESSION_EXPIRED"
        ) {
          throw error;
        }

        /*
         * Other individual-date failures should
         * not destroy the complete history search.
         */
        console.warn(
          "[ARMS SALES] Failed date " +
            date +
            ": " +
            (
              error instanceof Error
                ? error.message
                : String(error)
            )
        );
      }
    }
  }

  const workerCount =
    Math.min(
      SALES_CONCURRENCY,
      dates.length
    );

  const workers = [];

  for (
    let i = 0;
    i < workerCount;
    i += 1
  ) {
    workers.push(
      worker()
    );
  }

  await Promise.all(
    workers
  );

  const unique =
    deduplicatePurchases(
      allRows
    );

  /*
   * Sort newest first.
   */
  unique.sort(
    function (a, b) {
      const aTime =
        String(
          a.transaction_time ||
            ""
        );

      const bTime =
        String(
          b.transaction_time ||
            ""
        );

      return bTime.localeCompare(
        aTime
      );
    }
  );

  return unique.slice(
    0,
    SALES_MAX_RESULTS
  );
}


/* ==========================================================================
   PURCHASE NORMALIZATION
   ========================================================================== */

function deduplicatePurchases(
  rows
) {
  const unique = [];

  const seen =
    new Set();

  for (
    const row of rows || []
  ) {
    const key =
      [
        row.transaction_time ||
          "",

        row.receipt_no ||
          "",

        row.receipt_ref_no ||
          ""
      ].join(
        "|"
      );

    if (
      seen.has(key)
    ) {
      continue;
    }

    seen.add(
      key
    );

    unique.push(
      row
    );
  }

  return unique;
}


/* ==========================================================================
   FETCH MEMBER HISTORY
   ========================================================================== */

async function fetchMemberHistory(
  authenticatedSession,
  membership,
  options = {}
) {
  const requested =
    normalizeMembership(
      membership
    );

  if (!requested) {
    const error =
      new Error(
        "Membership number is required."
      );

    error.code =
      "MEMBERSHIP_REQUIRED";

    throw error;
  }

  const jar =
    authenticatedSession?.jar ||
    authenticatedSession;

  if (
    !(jar instanceof Map)
  ) {
    const error =
      new Error(
        "Invalid ARMS session."
      );

    error.code =
      "ARMS_SESSION_INVALID";

    throw error;
  }

  const url =
    buildHistoryUrl(
      requested
    );

  const response =
    await armsFetch(
      url,
      {
        method: "GET",

        headers: {
          Referer:
            absoluteUrl(
              "/login.php"
            )
        },

        redirect:
          "manual"
      },
      jar
    );

  let html =
    await readResponseBody(
      response
    );

  let finalUrl =
    url;

  let location =
    response.headers.get(
      "location"
    );

  let redirects = 0;

  while (
    location &&
    redirects < 5
  ) {
    redirects += 1;

    const nextUrl =
      new URL(
        location,
        finalUrl
      ).toString();

    const nextResponse =
      await armsFetch(
        nextUrl,
        {
          method: "GET",

          headers: {
            "Referer":
              finalUrl
          },

          redirect:
            "manual"
        },
        jar
      );

    html =
      await readResponseBody(
        nextResponse
      );

    finalUrl =
      nextUrl;

    location =
      nextResponse.headers.get(
        "location"
      );
  }

  /*
   * Session expired.
   */
  if (
    !looksAuthenticated(
      html
    )
  ) {
    const error =
      new Error(
        "ARMS session is not authenticated or has expired."
      );

    error.code =
      "ARMS_SESSION_EXPIRED";

    throw error;
  }

  const actualMembership =
    extractMembershipNumber(
      html
    );

  const requestedNormalized =
    normalizeMembership(
      requested
    );

  const actualNormalized =
    normalizeMembership(
      actualMembership
    );

  /*
   * AUTHORITATIVE MEMBERSHIP VALIDATION.
   */
  const membershipMatches =
    actualNormalized &&
    actualNormalized ===
      requestedNormalized;

  if (
    !membershipMatches
  ) {
    const escaped =
      escapeRegExp(
        requestedNormalized
      );

    const appearsInPage =
      new RegExp(
        "\\b" +
          escaped +
          "\\b",
        "i"
      ).test(
        html
      );

    if (
      !appearsInPage
    ) {
      const error =
        new Error(
          "Membership card number was not found in ARMS."
        );

      error.code =
        "ARMS_MEMBER_NOT_FOUND";

      throw error;
    }
  }

  const name =
    extractMemberName(
      html
    );

  const points =
    extractPoints(
      html
    );

  const includeSalesHistory =
    options.includeSalesHistory !== false;

  const includeTransactionDetails =
    options.includeTransactionDetails !== false;

  /*
   * Some ARMS versions expose transaction rows
   * directly on the membership history page.
   */
  let purchases =
    extractPurchaseRows(
      html
    );

  /*
   * IMPORTANT NEW LOGIC:
   *
   * The confirmed ARMS sales endpoint is the
   * authoritative purchase source when the
   * membership page itself has no rows.
   */
  let salesHistoryError =
    null;

  if (
    includeSalesHistory &&
    purchases.length === 0
  ) {
    console.log(
      "[ARMS SALES] No purchase rows on member history. Searching sales_details..."
    );

    try {
      purchases =
        await fetchSalesHistory(
          jar,
          requestedNormalized
        );

      console.log(
        "[ARMS SALES] Found " +
          purchases.length +
          " purchase(s)."
      );
    } catch (error) {
      salesHistoryError =
        error instanceof Error
          ? error.message
          : String(error);

      /*
       * Session expiry from sales search:
       *
       * Let outer getMembershipHistory()
       * retry the entire process.
       */
      if (
        error &&
        error.code ===
          "ARMS_SESSION_EXPIRED"
      ) {
        throw error;
      }

      console.error(
        "[ARMS SALES] Search failed:",
        salesHistoryError
      );
    }
  }

  /*
   * Attach transaction detail only when
   * the membership page supplied the
   * trans_detail() parameters.
   *
   * Sales_details rows do not provide all
   * transaction-detail parameters.
   */
  if (
    includeTransactionDetails &&
    FETCH_TRANSACTION_DETAILS &&
    purchases.length
  ) {
    const limited =
      purchases.slice(
        0,
        MAX_TRANSACTIONS
      );

    for (
      const purchase of limited
    ) {
      if (
        !purchase ||
        !purchase.transaction_detail
      ) {
        continue;
      }

      try {
        purchase.detail =
          await fetchTransactionDetail(
            jar,
            purchase.transaction_detail
          );
      } catch (error) {
        purchase.detail = {
          ok: false,

          error:
            error instanceof Error
              ? error.message
              : "Transaction detail unavailable"
        };
      }
    }
  }

  const pointsEarned =
    purchases.reduce(
      function (
        total,
        purchase
      ) {
        return (
          total +
          Number(
            purchase.points ||
              0
          )
        );
      },
      0
    );

  return {
    ok: true,

    membership:
      actualNormalized ||
      requestedNormalized,

    requestedMembership:
      requestedNormalized,

    name:
      name || null,

    points:
      points,

    pointsBalance:
      points,

    pointsEarned:
      pointsEarned,

    pointsUpdate:
      extractPointsUpdate(
        html
      ),

    issueBranch:
      extractIssueBranch(
        html
      ),

    issueDate:
      extractIssueDate(
        html
      ),

    expiryDate:
      extractExpiryDate(
        html
      ),

    memberType:
      extractMemberType(
        html
      ),

    gender:
      extractGender(
        html
      ),

    birthday:
      extractBirthday(
        html
      ),

    purchases:
      purchases,

    armsUrl:
      finalUrl,

    historyConfigured:
      true,

    historyMessage:
      salesHistoryError ||
      null,

    salesHistorySource:
      "counter_collection.php?a=sales_details",

    salesHistoryDateRange:
      {
        start:
          formatDate(
            getSalesDateRange()
              .startDate
          ),

        end:
          formatDate(
            getSalesDateRange()
              .endDate
          )
      },

    memberListing: {
      checked: false,
      found: null
    }
  };
}


/* ==========================================================================
   TRANSACTION DETAIL
   ========================================================================== */

function buildTransactionQuery(
  transaction
) {
  const params =
    new URLSearchParams();

  params.set(
    "a",
    "print_tran_details"
  );

  params.set(
    "branch_id",
    String(
      transaction.branch_id
    )
  );

  params.set(
    "date",
    String(
      transaction.date
    )
  );

  params.set(
    "counter_id",
    String(
      transaction.counter_id
    )
  );

  params.set(
    "pos_id",
    String(
      transaction.pos_id
    )
  );

  if (
    transaction.cashier_id !==
      undefined &&
    transaction.cashier_id !==
      null
  ) {
    params.set(
      "cashier_id",
      String(
        transaction.cashier_id
      )
    );
  }

  return params;
}


function parseTransactionItems(
  html
) {
  const items = [];

  const source =
    String(
      html || ""
    );

  const rowPattern =
    /<tr\b[^>]*>([\s\S]*?)<\/tr>/gi;

  let rowMatch;

  while (
    (rowMatch =
      rowPattern.exec(
        source
      ))
  ) {
    const cells = [];

    const cellPattern =
      /<td\b[^>]*>([\s\S]*?)<\/td>/gi;

    let cellMatch;

    while (
      (cellMatch =
        cellPattern.exec(
          rowMatch[1]
        ))
    ) {
      cells.push(
        cleanText(
          decodeHtml(
            htmlToText(
              cellMatch[1]
            )
          )
        )
      );
    }

    if (
      cells.length < 7
    ) {
      continue;
    }

    const joined =
      cells.join(
        " "
      );

    if (
      /description|selling|actual|barcode|mcode|arms code/i.test(
        joined
      )
    ) {
      continue;
    }

    if (
      !cells[0] &&
      !cells[1] &&
      !cells[2] &&
      !cells[3]
    ) {
      continue;
    }

    items.push({
      arms_code:
        cells[0] || null,

      mcode:
        cells[1] || null,

      barcode:
        cells[2] || null,

      description:
        cells[3] || null,

      qty:
        parseNumber(
          cells[4]
        ),

      actual_price:
        parseMoney(
          cells[5]
        ),

      discount:
        parseMoney(
          cells[6]
        ),

      selling_price:
        parseMoney(
          cells[7]
        )
    });
  }

  return items;
}


function parseTransactionDetailHtml(
  html
) {
  const source =
    String(
      html || ""
    );

  const text =
    htmlToText(
      source
    );

  return {
    ok: true,

    items:
      parseTransactionItems(
        source
      ),

    subtotal:
      parseMoney(
        extractTableValue(
          source,
          "Sub Total"
        )
      ),

    rounding:
      parseMoney(
        extractTableValue(
          source,
          "Rounding"
        )
      ),

    total:
      parseMoney(
        extractTableValue(
          source,
          "Total"
        )
      ),

    change:
      parseMoney(
        extractTableValue(
          source,
          "Change"
        )
      ),

    rawSummary:
      text.slice(
        0,
        2000
      )
  };
}


async function fetchTransactionDetail(
  jar,
  transaction
) {
  if (!transaction) {
    return null;
  }

  const params =
    buildTransactionQuery(
      transaction
    );

  const url =
    absoluteUrl(
      "/counter_collection.php"
    ) +
    "?" +
    params.toString();

  const response =
    await armsFetch(
      url,
      {
        method: "GET",

        headers: {
          Referer:
            absoluteUrl(
              "/membership.php?t=history"
            )
        },

        redirect:
          "manual"
      },
      jar
    );

  const html =
    await readResponseBody(
      response
    );

  if (
    response.status < 200 ||
    response.status >= 400
  ) {
    const error =
      new Error(
        "ARMS transaction detail returned HTTP " +
          response.status
      );

    error.response = {
      status:
        response.status
    };

    throw error;
  }

  if (
    loginPageLooksPresent(
      html
    )
  ) {
    const error =
      new Error(
        "ARMS transaction detail requires an authenticated session."
      );

    error.code =
      "ARMS_SESSION_EXPIRED";

    throw error;
  }

  return {
    ok: true,

    source:
      "ARMS",

    transaction:
      transaction,

    url:
      url,

    ...parseTransactionDetailHtml(
      html
    )
  };
}


/* ==========================================================================
   PUBLIC: GET MEMBERSHIP HISTORY
   ========================================================================== */

export async function getMembershipHistory(
  membership
) {
  let session =
    await loginToArmsInternal();

  try {
    return await getMembershipHistoryWithSession(
      session,
      membership,
      {
        includeSalesHistory: true,
        includeTransactionDetails: true
      }
    );
  } catch (error) {
    if (
      error &&
      error.code ===
        "ARMS_SESSION_EXPIRED"
    ) {
      console.log(
        "[ARMS] Session expired. Re-authenticating..."
      );

      session =
        await loginToArmsInternal();

      return getMembershipHistoryWithSession(
        session,
        membership,
        {
          includeSalesHistory: true,
          includeTransactionDetails: true
        }
      );
    }

    throw error;
  }
}


async function getMembershipHistoryWithSession(
  session,
  membership,
  options = {}
) {
  return fetchMemberHistory(
    session,
    membership,
    options
  );
}


/* ========================================================================== */
/* PUBLIC: FAST CUSTOMER PROFILE                                              */
/* ========================================================================== */

export async function getCustomerProfileFromArms(
  membership
) {
  let session =
    await loginToArmsInternal();

  const options = {
    includeSalesHistory: false,
    includeTransactionDetails: false
  };

  try {
    const result =
      await getMembershipHistoryWithSession(
        session,
        membership,
        options
      );

    if (!result.name) {
      const error =
        new Error(
          "ARMS verified the membership, but customer name was not found."
        );

      error.code =
        "ARMS_CUSTOMER_NAME_MISSING";

      throw error;
    }

    return {
      membership:
        result.membership,

      name:
        result.name,

      points:
        Number(
          result.points || 0
        ),

      pointsBalance:
        Number(
          result.pointsBalance ||
          result.points ||
          0
        ),

      pointsEarned:
        Number(
          result.pointsEarned || 0
        ),

      pointsUpdate:
        result.pointsUpdate,

      issueBranch:
        result.issueBranch,

      issueDate:
        result.issueDate,

      expiryDate:
        result.expiryDate,

      memberType:
        result.memberType,

      gender:
        result.gender,

      birthday:
        result.birthday,

      purchases: [],

      historyConfigured:
        result.historyConfigured,

      historyMessage:
        "Purchase history is loading separately.",

      memberListing:
        result.memberListing
    };
  } catch (error) {
    if (
      error &&
      error.code ===
        "ARMS_SESSION_EXPIRED"
    ) {
      session =
        await loginToArmsInternal();

      const result =
        await getMembershipHistoryWithSession(
          session,
          membership,
          options
        );

      if (!result.name) {
        const retryError =
          new Error(
            "ARMS verified the membership, but customer name was not found."
          );

        retryError.code =
          "ARMS_CUSTOMER_NAME_MISSING";

        throw retryError;
      }

      return {
        membership:
          result.membership,
        name:
          result.name,
        points:
          Number(result.points || 0),
        pointsBalance:
          Number(
            result.pointsBalance ||
            result.points ||
            0
          ),
        pointsEarned:
          Number(result.pointsEarned || 0),
        pointsUpdate:
          result.pointsUpdate,
        issueBranch:
          result.issueBranch,
        issueDate:
          result.issueDate,
        expiryDate:
          result.expiryDate,
        memberType:
          result.memberType,
        gender:
          result.gender,
        birthday:
          result.birthday,
        purchases: [],
        historyConfigured:
          result.historyConfigured,
        historyMessage:
          "Purchase history is loading separately.",
        memberListing:
          result.memberListing
      };
    }

    throw error;
  }
}


/* ==========================================================================
   PUBLIC: CUSTOMER DATA
   ========================================================================== */

export async function getCustomerDataFromArms(
  membership
) {
  const result =
    await getMembershipHistory(
      membership
    );

  if (
    !result.name
  ) {
    const error =
      new Error(
        "ARMS verified the membership, but customer name was not found in the ARMS history response."
      );

    error.code =
      "ARMS_CUSTOMER_NAME_MISSING";

    throw error;
  }

  return {
    membership:
      result.membership,

    name:
      result.name,

    points:
      Number(
        result.points ||
          0
      ),

    pointsBalance:
      Number(
        result.pointsBalance ||
          result.points ||
          0
      ),

    pointsEarned:
      Number(
        result.pointsEarned ||
          0
      ),

    pointsUpdate:
      result.pointsUpdate,

    issueBranch:
      result.issueBranch,

    issueDate:
      result.issueDate,

    expiryDate:
      result.expiryDate,

    memberType:
      result.memberType,

    gender:
      result.gender,

    birthday:
      result.birthday,

    purchases:
      result.purchases ||
      [],

    historyConfigured:
      result.historyConfigured,

    historyMessage:
      result.historyMessage,

    salesHistorySource:
      result.salesHistorySource,

    salesHistoryDateRange:
      result.salesHistoryDateRange,

    memberListing:
      result.memberListing
  };
}


/* ==========================================================================
   PUBLIC: TRANSACTION DETAIL
   ========================================================================== */

export async function getTransactionDetail(
  transaction
) {
  const required = [
    "branch_id",
    "counter_id",
    "pos_id",
    "cashier_id",
    "date"
  ];

  const missing = [];

  for (
    const field of required
  ) {
    if (
      transaction ===
        undefined ||
      transaction === null ||
      transaction[field] ===
        undefined ||
      transaction[field] ===
        ""
    ) {
      missing.push(
        field
      );
    }
  }

  if (
    missing.length
  ) {
    const error =
      new Error(
        "Missing transaction fields: " +
          missing.join(
            ", "
          )
      );

    error.code =
      "TRANSACTION_FIELDS_MISSING";

    throw error;
  }

  let session =
    await loginToArmsInternal();

  try {
    return await fetchTransactionDetail(
      session.jar,
      transaction
    );
  } catch (error) {
    if (
      error &&
      error.code ===
        "ARMS_SESSION_EXPIRED"
    ) {
      session =
        await loginToArmsInternal();

      return fetchTransactionDetail(
        session.jar,
        transaction
      );
    }

    throw error;
  }
}


/* ==========================================================================
   PUBLIC: VERIFIED TEST TRANSACTION
   ========================================================================== */

export async function getVerifiedTransactionForDemo() {
  const transaction = {
    branch_id:
      process.env.ARMS_TEST_BRANCH_ID ||
      "12",

    counter_id:
      process.env.ARMS_TEST_COUNTER_ID ||
      "46",

    pos_id:
      process.env.ARMS_TEST_POS_ID ||
      "202",

    cashier_id:
      process.env.ARMS_TEST_CASHIER_ID ||
      "48",

    date:
      process.env.ARMS_TEST_DATE ||
      "2026-05-16"
  };

  return getTransactionDetail(
    transaction
  );
}


/* ==========================================================================
   OPTIONAL NAMED EXPORTS
   ========================================================================== */

export {
  normalizeMembership,
  absoluteUrl,
  extractMemberName,
  extractMembershipNumber,
  extractPoints,
  extractPurchaseRows,
  extractTransDetailCalls,
  buildSalesDetailsUrl,
  fetchSalesDetailsForDate
};