# Hasani Customer App — Production Integration Notes (v6)

## Confirmed from supplied ARMS captures

ARMS login:
- URL: https://hasani.arms.com.my/login.php
- login_branch: HQ
- authenticated cookies observed: `arms_login` and `PHPSESSID`

Transaction detail:
- URL: `/counter_collection.php`
- `a=item_details`
- `branch_id=12`
- `counter_id=46`
- `pos_id=202`
- `cashier_id=48`
- `date=2026-05-16`

Receipt sample:
- membership: `000101020212`
- receipt: `10201`
- reference: `001200469632010201`
- cashier: `wmj3`
- total: RM 91.70
- points: 45

## Current live history integration

Confirmed request:
`/membership.php?t=history&a=i&nric={membership}`

The backend uses the authenticated ARMS PHP session and parses the supplied transaction-history table.

## Strict membership validation

A customer session is created only when the requested membership number is returned by ARMS in the history response and matches the requested number. There is no local membership-number fallback.

## Customer name

The history page is the authenticated ARMS member page and should be treated as the source of truth. The parser now extracts the member name and live points balance from common ARMS labels (including `Points Accumulated`) when those fields are present in the returned HTML. No hard-coded customer name or points value is used.

Important session behavior:
- The backend first GETs `/login.php` to establish the initial cookies.
- It then POSTs `login_branch`, `u`, `p`, and `tnc`.
- It preserves every `Set-Cookie` returned by ARMS, including `arms_login` and `PHPSESSID`.
- The same authenticated cookie jar is used for `/membership.php?t=history&a=i&nric={membership}`.
- If ARMS returns the login page again, the backend discards the old session, logs in again, and retries once.
- A customer session is created only after ARMS returns the requested membership number.


## Security

Real ARMS credentials are intentionally excluded from this package. Put them only in `backend/.env` on the server.


## v6 — member listing + automatic receipt detail integration

Additional confirmed ARMS endpoints supplied by the project owner:
- `/membership.listing.php` — member listing/validation page.
- `/membership.php?t=history&a=i&nric={membership}` — member/points and purchase history.
- `/counter_collection.php?a=print_tran_details&branch_id=...&date=...&counter_id=...&pos_id=...` — receipt/transaction detail.

The backend now opens `membership.listing.php` during customer verification when available, while retaining the authenticated member-history response as the authoritative membership check because the listing page may be paginated.

The history parser now extracts the `trans_detail(counter_id, cashier_id, date, pos_id, branch_id)` values embedded in each receipt row. For each receipt (up to `ARMS_TRANSACTION_DETAIL_LIMIT`) the backend automatically calls `/counter_collection.php` with `a=item_details` and attaches the itemized receipt as `purchase.detail`.

No transaction branch/counter/POS/cashier values are hard-coded for normal customer history. The old `ARMS_TEST_*` values are retained only for the diagnostic test endpoint.
