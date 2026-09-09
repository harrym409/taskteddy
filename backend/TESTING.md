# TaskTeddy — Testing Guide

This document describes the testing strategy across the platform and how to run
the backend test suite that ships in `backend/tests/`.

## The testing pyramid we target

| Layer | What it covers | Tooling | Status |
|-------|----------------|---------|--------|
| **Unit** | Pure business logic in isolation — money math, chat guards, OTP helpers | `pytest` | ✅ implemented |
| **Integration / API** | Real HTTP endpoints against a real Postgres DB, with auth & DB wired up | `pytest` + FastAPI `TestClient` | ✅ implemented |
| **Contract** | Response shapes the mobile apps depend on | (covered inside API tests via assertions on JSON) | ➕ partial |
| **Widget / unit (Flutter)** | Pure Dart helpers & isolated widgets | `flutter test` | ⏳ starter, see below |
| **End-to-end** | Full user journeys across app + backend | Manual / (future) integration_test + Patrol | 🔲 manual today |
| **Static analysis** | Type/lint issues | `flutter analyze`, `ruff`/`mypy` (optional) | ✅ `flutter analyze` in use |

The **money-critical paths get the deepest coverage** because a bug there costs
real cash: commission, the promo/signup-bonus engine (no-loss invariant), and
the anti-disintermediation chat guards.

## Backend suite (implemented)

Located in `backend/tests/`:

```
tests/
├── conftest.py                     # fixtures: isolated test DB, auth overrides, model factories
├── unit/
│   ├── test_chat_guard.py          # _contains_contact_info / _clean_location
│   ├── test_promo_math.py          # promo_cap_for / charge_commission / credit_earning invariants
│   └── test_otp_utils.py           # phone normalisation, OTP hashing
└── integration/
    ├── test_signup_bonus.py        # ₹500 granted to new customers only
    ├── test_promo_checkout.py      # apply / remove / balance-cap / cancel refund
    ├── test_task_completion.py     # OTP completion + no-loss settlement
    ├── test_chat_api.py            # message API blocks phone numbers, allows presets & location
    └── test_rbac.py                # Super Admin / Admin / Support gates
```

### How isolation works
- The suite redirects `DATABASE_URL` to a **separate `<db>_test` database** before
  the app is imported and **creates it if missing** — your real `taskteddy` data
  is never touched.
- Every table is **truncated before and after each test**, so tests are order-independent.
- Auth is injected via FastAPI `dependency_overrides`, so tests pick the acting
  user/role without needing real tokens (a couple of tests still exercise the real
  OTP login path).

### Running it

Docker must be running and the backend container up (`docker compose up -d backend`).

```bash
# from repo root — copies tests in, installs pytest, runs everything
./backend/run_tests.sh

# subsets
./backend/run_tests.sh -m unit          # only fast unit tests
./backend/run_tests.sh -k promo         # only promo tests
./backend/run_tests.sh --cov            # with coverage report
```

Or manually inside the container:

```bash
docker compose exec backend pip install -r requirements-dev.txt
docker compose exec -w /app backend pytest
```

> The suite runs **inside the backend container** on purpose: it uses the same
> Postgres (sequences, JSON columns) and Redis the app uses, so behaviour matches
> production rather than a SQLite stand-in.

## Flutter apps (starter + next steps)

`flutter analyze` already runs clean on both apps and is the first line of defence.
For unit/widget tests, the highest-value targets are the **pure helpers** — extract
them from the private (`_`) scope in `messages.dart` / `tasks.dart` into a small
`lib/utils/` file so they can be imported by `test/`, then cover:
- money/label formatting and the bonus **preview** math (`min(balance, 10% of bid)`),
- slot-preset message building (time/amount formatting),
- model `fromJson` (e.g. `TaskModel`, chat message location parsing).

Run with `flutter test` in each app directory.

## What to add next
- **Reviews & ratings** endpoints (double-review prevention).
- **Cash-dues browse gate** (tasker paused after N unsettled cash jobs, `settle` clears it).
- **Region notification** fan-out on new task.
- A **CI workflow** (GitHub Actions) that boots Postgres + Redis services and runs
  `pytest` on every push.
