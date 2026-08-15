# 🐻 TaskTeddy - Local Development Setup

## For Multiple Developers

Each developer runs their own local database via Docker - data is **not** shared.

---

## Quick Start (5 minutes)

### Step 1: One-time Setup

```powershell
# 1. Go to backend folder
cd backend

# 2. Copy example env (optional - defaults work)
copy .env.example .env

# 3. IMPORTANT: Change project name to avoid port conflicts
# Edit .env and change:
COMPOSE_PROJECT_NAME=taskteddy_ankit  # Use your name!
```

### Step 2: Start Docker Services

```powershell
# Start PostgreSQL only (recommended for dev)
docker compose up -d postgres

# Or start everything (PostgreSQL + Backend)
docker compose up -d
```

🚀 Run Commands

1 # Start all services
2 docker-compose up -d --build
3
4 # View logs
5 docker-compose logs -f
6
7 # Stop all
8 docker-compose down

### Step 3: Delete Docker Services

```powershell
# Delete all contanier 
docker stop $(docker ps -aq)
docker rm $(docker ps -aq) 

# Delete all images
docker rmi $(docker images -aq)

# Delete all Docker volums
docker volume rm $(docker volume ls -q)
docker volume prune -f
docker system prune -a --volumes -f
```

### Step 3: Run Backend Locally (Recommended)

```powershell
# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Or if no venv:
python -m venv .venv
.\venv\Scripts\pip install -r requirements.txt
.\venv\Scripts\Activate.ps1

# Run backend
uvicorn server:app --host 0.0.0.0 --port 8000 --reload
```

---

## What Each Developer Needs

| Requirement | Description |
|-------------|------------|
| Docker Desktop | Run PostgreSQL container |
| Python 3.10+ | Run backend locally |
| Git | Clone repository |

---

## Per-Developer Setup

### Option A: Using Docker for Database Only (Recommended)

```powershell
# 1. Start PostgreSQL container
docker compose up -d postgres

# 2. Run backend locally (in venv)
.\venv\Scripts\Activate.ps1
uvicorn server:app --host 0.0.0.0 --port 8000 --reload
```

**Advantages:**
- Backend auto-reloads on code changes
- Debug with print statements
- Use IDE debugger

### Option B: Full Docker Stack



```powershell
# Start everything in containers
docker compose up -d

# View logs
docker compose logs -f backend

# Stop
docker compose down
```

---

## Port Configuration

Each developer should use unique ports in `.env`:

```env
# Developer 1
COMPOSE_PROJECT_NAME=taskteddy_ankit
POSTGRES_PORT=5432
BACKEND_PORT=8000

# Developer 2  
COMPOSE_PROJECT_NAME=taskteddy_shubham
POSTGRES_PORT=5433
BACKEND_PORT=8001
```

---

## Testing Your Setup

```powershell
# Test database connection
docker compose ps

# Test backend
curl http://localhost:8000/docs

# Test login API
curl -X POST http://localhost:8000/customer/auth/send-otp -H "Content-Type: application/json" -d '{"phone": "9876543210"}'
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Port in use | Change POSTGRES_PORT in .env |
| Database exists | `docker compose down -v` to reset |
| Can't connect | Check Docker is running |
| Import errors | `.\venv\Scripts\pip install -r requirements.txt` |

---

## Important Notes

1. **Each developer has own database** - data is not shared
2. **Use unique COMPOSE_PROJECT_NAME** - avoids container name conflicts
3. **Run backend locally** - easier debugging than Docker
4. **Keep .env private** - add to .gitignore

```powershell
# Your .env is already gitignored if setup correctly
# Check: 