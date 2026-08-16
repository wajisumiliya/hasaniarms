# Hasani ARMS Customer Portal — Production 7.1 — ARMS Session + Frontend API Fix

This package contains the Web frontend, Flutter client, and Node.js ARMS integration backend.

## Important integration behavior

Customer login is **strictly ARMS-verified**:

1. Customer enters membership card number and the customer-app password (`123123` unless changed in `.env`).
2. Backend logs in to Hasani ARMS using the server-side ARMS credentials.
3. Backend requests the configured live membership-history URL with the authenticated ARMS PHP session.
4. The membership number returned by ARMS must match the requested membership.
5. No local/test membership fallback is used.
6. Purchase history is parsed from the live ARMS HTML.
7. ARMS cookies and credentials never go to the browser/mobile app.

### Name limitation from the supplied ARMS capture

The ARMS history HTML supplied during development contains the membership number and transaction data, but **does not contain a customer-name field**. The backend therefore does not invent or use `CUSTOMER_NAME`. It refuses customer login when ARMS verifies the membership but the name is absent from the captured response.

To make name display live, set `ARMS_PROFILE_URL_TEMPLATE` after capturing the actual ARMS member-profile request in DevTools, then map that page's name field in `src/arms.js`. Do not guess an ARMS URL.

## Backend setup

PowerShell:

```powershell
cd C:\hasani_customer_app\backend
copy .env.example .env
notepad .env
npm install
npm start
```

Set these values in `.env`:

```text
ARMS_BASE_URL=https://hasani.arms.com.my
ARMS_USERNAME=YOUR_ARMS_USERNAME
ARMS_PASSWORD=YOUR_ARMS_PASSWORD
ARMS_LOGIN_BRANCH=HQ
ARMS_TNC=1
ARMS_HISTORY_URL_TEMPLATE=/membership.php?t=history&a=i&nric={membership}
CUSTOMER_PASSWORD=123123
CUSTOMER_SESSION_SECRET=use-a-long-random-secret
COOKIE_SECURE=true
```

For **local HTTP testing only**, use `COOKIE_SECURE=false`. Use `true` behind HTTPS in production.

Never commit `.env`.

## Backend health

Open:

```text
http://localhost:5000/health
```

Expected:

```json
{"ok":true}
```

## Web frontend

Start the backend first, then:

```powershell
cd C:\hasani_customer_app
python -m http.server 8080 --directory web
```

Open:

```text
http://localhost:8080
```

The web client uses the backend session cookie and calls `/api/customer/dashboard` for live data.

## Flutter / Android

Flutter must be installed for Android builds.

```powershell
cd C:\hasani_customer_app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000
```

Android emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

The Flutter client stores the backend session cookie and sends it with subsequent requests.

## ARMS transaction detail

The supplied verified transaction mapping remains available for diagnostics:

```text
POST /counter_collection.php

a=item_details
branch_id=12
counter_id=46
pos_id=202
cashier_id=48
date=2026-05-16
```

Test endpoint:

```text
GET http://localhost:5000/api/arms/test-transaction
```

Do not expose diagnostic endpoints on a public production deployment. They are included for integration testing and should be disabled/restricted before internet exposure.

## Production checklist

- Put the Node backend behind HTTPS.
- Set `COOKIE_SECURE=true`.
- Use a long random `CUSTOMER_SESSION_SECRET`.
- Keep ARMS credentials only on the server.
- Restrict CORS to the real frontend origin before deployment.
- Disable or protect `/api/arms/*` diagnostic routes.
- Use a persistent session store instead of Express MemoryStore for multi-instance production deployment.
- Configure the actual ARMS member-profile request so the customer's name is read from ARMS.
- Test with one valid and one invalid membership number before going live.


## v7.1 API routing fix

The Web and Flutter clients use `http://localhost:5000` as the base URL and explicitly call `/api/customer/...`. This prevents accidental `/api/api/...` URLs and matches the Node routes.
