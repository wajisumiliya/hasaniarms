# Production v7 Frontend Backend URL Fix

The backend is confirmed reachable at http://localhost:5000/health.

The previous web frontend incorrectly used `http://localhost:5000/api` as its base URL while its request paths already contain `/customer/...`. This caused connectivity checks and requests to target the wrong URL.

Fixed:
- Web API base defaults to `http://localhost:5000`
- Health check targets `http://localhost:5000/health`
- Customer API requests target `http://localhost:5000/api/customer/...`
- Flutter ApiService default base URL is also `http://localhost:5000`

You can optionally override the web API with:
`?api=http://localhost:5000`

# v7.1 final routing correction

The web client previously called `/customer/...` while the Node server exposes `/api/customer/...`.
All web and Flutter calls now use `/api/customer/...` with a root backend base URL.
