# Web Test

1. Configure `backend/.env`.
2. Start Node:

```powershell
cd backend
npm install
npm start
```

3. Confirm:

```text
http://localhost:5000/health
```

4. Confirm ARMS authentication:

```text
http://localhost:5000/api/arms/session-status
```

5. Test the verified transaction-detail request:

```text
http://localhost:5000/api/arms/test-transaction
```

6. Start web:

```powershell
python -m http.server 8080 --directory web
```

7. Open:

```text
http://localhost:8080
```

8. Login:

```text
Membership: 000101020212
Password: 123123
```

If purchase history is empty, capture the exact `membership.php?t=history` Request URL from DevTools and set `ARMS_HISTORY_URL_TEMPLATE` in `.env`.


## Backend URL fix
The web frontend now uses `http://localhost:5000` as its API base. Health checks use `/health`; customer routes are under `/api/customer/...`.
