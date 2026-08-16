import axios from 'axios';

let armsClient = null;
let loggedIn = false;
let loginAt = 0;

const base = process.env.ARMS_BASE_URL || 'https://hasani.arms.com.my';
const sessionMaxAgeMs = Number(process.env.ARMS_SESSION_MAX_AGE_MS || 20 * 60 * 1000);

function makeClient() {
  const jar = new Map();

  const client = axios.create({
    baseURL: base,
    timeout: Number(process.env.ARMS_TIMEOUT_MS || 20000),
    maxRedirects: 5,
    validateStatus: () => true
  });

  client.interceptors.request.use(config => {
    const cookie = [...jar.entries()].map(([k, v]) => `${k}=${v}`).join('; ');
    if (cookie) config.headers.Cookie = cookie;
    config.headers['User-Agent'] = config.headers['User-Agent'] ||
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/151.0 Safari/537.36';
    config.headers.Accept = config.headers.Accept ||
      'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
    return config;
  });

  client.interceptors.response.use(response => {
    const setCookie = response.headers['set-cookie'] || [];
    for (const item of setCookie) {
      const first = item.split(';')[0];
      const eq = first.indexOf('=');
      if (eq > 0) jar.set(first.slice(0, eq), first.slice(eq + 1));
    }
    return response;
  });

  client.getCookieNames = () => [...jar.keys()];
  return client;
}

function hasSessionCookie(client) {
  const names = client?.getCookieNames?.() || [];
  return names.some(x => x.toUpperCase() === 'PHPSESSID');
}

function looksLikeLoginPage(response) {
  const html = String(response?.data ?? '');
  return /<form[^>]+(?:action=["'][^"']*login\.php|action=["']?[^ >]*login\.php)/i.test(html) &&
         /name=["']?u["']?/i.test(html) &&
         /name=["']?p["']?/i.test(html);
}

function looksAuthenticatedPage(response) {
  const html = String(response?.data ?? '');
  return /Membership\s+No\./i.test(html) ||
         /Transaction\s+Time/i.test(html) ||
         /membership\.php\?t=history/i.test(html);
}

export async function loginToArms(force = false) {
  if (!force && loggedIn && armsClient && (Date.now() - loginAt) < sessionMaxAgeMs) {
    return armsClient;
  }

  if (!process.env.ARMS_USERNAME || !process.env.ARMS_PASSWORD) {
    throw new Error('ARMS_USERNAME / ARMS_PASSWORD are not configured in backend/.env');
  }

  armsClient = makeClient();

  // ARMS establishes important cookies on the login page before accepting
  // the POST. A browser does this automatically; Node must do it explicitly.
  const loginPage = await armsClient.get('/login.php', {
    headers: {
      Referer: `${base}/login.php`
    }
  });

  if (loginPage.status >= 400) {
    throw new Error(`Unable to open ARMS login page: HTTP ${loginPage.status}`);
  }

  const response = await armsClient.post('/login.php', new URLSearchParams({
    login_branch: process.env.ARMS_LOGIN_BRANCH || 'HQ',
    u: process.env.ARMS_USERNAME,
    p: process.env.ARMS_PASSWORD,
    tnc: process.env.ARMS_TNC || '1'
  }).toString(), {
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Accept: 'text/html,application/xhtml+xml'
    },
    Referer: `${base}/login.php`
  });

  if (response.status >= 400) {
    throw new Error(`ARMS login failed with HTTP ${response.status}`);
  }

  // A successful ARMS login has been observed to set both arms_login and
  // PHPSESSID. Do not accept a login that did not establish a session.
  if (!hasSessionCookie(armsClient)) {
    throw new Error('ARMS login did not establish a PHP session. Check ARMS username/password/branch and login form fields.');
  }

  if (looksLikeLoginPage(response) && !looksAuthenticatedPage(response)) {
    throw new Error('ARMS returned the login page after credentials were submitted. Check ARMS username/password/branch.');
  }

  loggedIn = true;
  loginAt = Date.now();
  return armsClient;
}

export async function armsRequest(config) {
  let client = await loginToArms();
  let response = await client.request(config);

  if (response.status === 401 || response.status === 403 || looksLikeLoginPage(response)) {
    loggedIn = false;
    loginAt = 0;
    armsClient = null;

    client = await loginToArms(true);
    response = await client.request(config);
  }

  if (response.status >= 400) {
    const error = new Error(`ARMS request failed with HTTP ${response.status}`);
    error.response = response;
    throw error;
  }

  if (looksLikeLoginPage(response) && !looksAuthenticatedPage(response)) {
    const error = new Error('ARMS returned the login page instead of the requested authenticated page.');
    error.response = response;
    throw error;
  }

  return response;
}

export function getArmsSessionStatus() {
  return {
    authenticated: Boolean(loggedIn && armsClient),
    ageMs: loggedIn ? Date.now() - loginAt : null,
    cookieNames: armsClient?.getCookieNames?.() || []
  };
}

export function clearArmsSession() {
  armsClient = null;
  loggedIn = false;
  loginAt = 0;
}
