# TaskTeddy — AWS Deployment & Security Handoff

This is the guide for deploying the TaskTeddy backend (FastAPI) + admin panel
(Next.js) to AWS. The two Flutter apps are built and shipped separately (Play
Store / App Store) and only need the backend's public HTTPS URL.

> **Stage:** testing/pilot. Real-money payments and company registration are
> intentionally deferred, so no payment gateway is wired yet. Everything below
> is for a secure, working pilot.

---

## 1. Architecture

```
 Flutter apps ─┐
 Admin (Next)  ├─► HTTPS (ALB / nginx, TLS)  ─►  FastAPI backend (Docker, port 8000)
               ┘                                    │
                                                    ├─► PostgreSQL   (RDS)
                                                    ├─► Redis        (ElastiCache)  — OTP store, rate limits, token revocation
                                                    └─► S3           — uploads (avatars, task photos, chat images)
```

Two supported shapes:
- **Simple (single EC2):** `docker compose up -d` on one EC2 box (backend + admin + Postgres + Redis in containers). Fine for the pilot. Put nginx or an ALB in front for TLS.
- **Managed (recommended for scale):** backend + admin on ECS/Fargate (or EC2), **RDS** for Postgres, **ElastiCache** for Redis, **S3 + CloudFront** for uploads, **ALB** for TLS + routing.

The backend container **runs DB migrations automatically on startup** (`alembic upgrade head` in `docker-entrypoint.sh`) — no manual migration step.

---

## 2. Required configuration (production)

Copy `backend/.env.example` → `backend/.env` and set these. The backend
**fails closed** — it refuses to start or authenticate if the security-critical
ones are missing/weak.

| Variable | Required in prod | Notes |
|---|---|---|
| `ENVIRONMENT` | ✅ | Must be `production` — this locks CORS, hides `/docs`, hides error internals, enables HSTS. |
| `JWT_SECRET` | ✅ | ≥32 chars, random, **stable** across restarts/workers. Generate below. |
| `DATABASE_URL` | ✅ | Point at RDS. Use a strong DB password (not `postgres`). |
| `REDIS_URL` | ✅ | ElastiCache endpoint. Required for OTP, rate limiting, token revocation. |
| `ADMIN_EMAIL` + `ADMIN_PASSWORD_HASH` | ✅ | Bootstrap super-admin. Use a **bcrypt hash**, never a default password (rejected in prod). |
| `CORS_ORIGINS` | ✅ | Comma-separated admin origin(s), e.g. `https://admin.taskteddy.com`. `*` is ignored in prod. |
| `SMS_PROVIDER` + creds | ✅ | `msg91` or `twilio` (not `console`). Without it OTP login can't send codes. |
| `SENDGRID_API_KEY` + `EMAIL_FROM` | ✅ | Email OTP / welcome-bonus verification. Use a **fresh** key (see §5). |
| `USE_S3=true` + S3 creds | ✅ | Otherwise uploads write to the container's local disk and are lost on redeploy. |
| `FRONTEND_URL` | ✅ | Public admin URL, used in email links. |

Generate a JWT secret:
```bash
python3 -c "import secrets,string; print(''.join(secrets.choice(string.ascii_letters+string.digits) for _ in range(64)))"
```
Generate the admin bcrypt hash:
```bash
python3 -c "from passlib.context import CryptContext; print(CryptContext(schemes=['bcrypt']).hash('YOUR_STRONG_PASSWORD'))"
```

Store `.env` / secrets in **AWS Secrets Manager or SSM Parameter Store**, not in
the image and not in git (`.env` is gitignored).

---

## 3. Deploy — simple EC2 path

```bash
# On an Amazon Linux / Ubuntu EC2 box with Docker + docker compose installed
git clone https://github.com/harrym409/taskteddy.git
cd taskteddy
cp backend/.env.example backend/.env      # then edit with the values from §2
docker compose build
docker compose up -d
docker compose logs -f backend            # confirm "alembic upgrade head" ran and it's healthy
curl -s localhost:8080/api/health         # -> 200
```

**Do not expose Postgres/Redis to the internet.** In the EC2 security group open
only 443 (and 22 for SSH from your IP). Terminate TLS at an ALB or nginx and
proxy to the backend on 8000/8080. Point the mobile apps' API base URL at the
HTTPS domain.

---

## 4. Deploy — managed path (recommended)

1. **RDS PostgreSQL** (15+). Put it in a private subnet; security group allows
   the backend only. Set `DATABASE_URL` to its endpoint.
2. **ElastiCache Redis**. Private subnet; `REDIS_URL` to its endpoint.
3. **S3 bucket** for uploads + optional **CloudFront**. Set `USE_S3=true`,
   `S3_BUCKET`, `S3_REGION`, and give the task role S3 access (prefer an IAM
   **role**, not static `S3_ACCESS_KEY`/`S3_SECRET_KEY`).
4. **ECS/Fargate** service from the backend image; inject env from Secrets
   Manager. Same image also builds the admin (or host admin on Amplify/Vercel).
5. **ALB** with an ACM cert → HTTPS only; forward `/api/*` (and `/ws` for
   WebSockets) to the backend, admin to the admin service.
6. Health check path: `GET /api/health`.

---

## 5. Security checklist (do before going live)

- [ ] `ENVIRONMENT=production` set (this alone locks CORS, hides `/docs` & `/redoc`, hides error details, sends HSTS).
- [ ] Strong random `JWT_SECRET` (≥32 chars), stored in Secrets Manager, identical across all workers.
- [ ] `ADMIN_PASSWORD_HASH` set to a bcrypt hash of a strong password. Default/weak passwords are refused in prod. Change the pilot super-admin password after first login.
- [ ] `CORS_ORIGINS` = exact admin origin(s) over HTTPS. No `*`.
- [ ] RDS/ElastiCache in **private** subnets; not publicly reachable. Strong DB password.
- [ ] `USE_S3=true` with an IAM role (avoid long-lived S3 keys).
- [ ] **TLS everywhere** (ALB/ACM or nginx + certbot). The apps must talk HTTPS.
- [ ] **Rotate the SendGrid API key.** An old key was exposed in earlier git history — revoke it in the SendGrid dashboard and issue a new one for `SENDGRID_API_KEY`. (This is a manual action; it is not in the current code.)
- [ ] Real `SMS_PROVIDER` (msg91/twilio) configured — `console` only logs codes server-side.
- [ ] Rate limiting on (`RATE_LIMIT_ENABLED=true`, default) with Redis reachable.
- [ ] DB automated backups / RDS snapshots enabled.
- [ ] Log aggregation (CloudWatch) and an alarm on 5xx / health-check failures.

### Already handled in code (no action needed)
- JWT secret **fail-closed** in prod (won't boot with a missing/short secret).
- Admin login **fail-closed** in prod (rejects default/blank passwords).
- CORS disabled for `*` in prod; `/docs` & `/redoc` disabled in prod.
- Global error handler returns a safe 500 + request id — **never leaks stack traces** in prod.
- Security headers on every response: CSP, `X-Content-Type-Options`, `X-Frame-Options: DENY`, `Referrer-Policy`, `Permissions-Policy`, and **HSTS in production**.
- OTP: hashed, rate-limited, lockout on repeated failures; JWT revocation via Redis.
- Chat blocks phone numbers/emails (anti-disintermediation) at the API layer.
- Container runs as a **non-root** user.

---

## 6. After deploy — smoke test
```bash
curl -s https://<domain>/api/health           # 200
# From the app: request an OTP, verify, post a task, verify email → ₹500 bonus.
```
Admin panel: log in at the admin URL with `ADMIN_EMAIL` / your password, then
create the real admin/support accounts from the Team page (super-admin only).

Backend test suite (optional, in a staging container): see `backend/TESTING.md`.
