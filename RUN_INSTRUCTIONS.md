# 🚀 TaskTeddy - How to Run

## 📋 Prerequisites

### Required Software:
1. **Flutter SDK** (3.0.0 or higher)
   - Download: https://flutter.dev/docs/get-started/install
   
2. **Android Studio** or **VS Code** with Flutter plugin
   
3. **Android Emulator** or **Physical Android Device**

4. **Python 3.8+** (for backend)

5. **Docker Desktop** (recommended for PostgreSQL)

---

## 🎯 Quick Start Guide

### Step 1: Start Backend (Recommended: DB in Docker + Backend Local)

```bash
./start_backend.sh --db-docker
```

docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi $(docker images -aq)


### Alternate Step 1: Start Backend Manually

```bash
# Navigate to backend directory
cd backend

# Start the backend server (if not already running)
uvicorn server:app --host 0.0.0.0 --port 8000 --reload
```

**Backend will be running at:** `http://localhost:8000`

**API Documentation:** `http://localhost:8000/docs`

**Docker option (backend + PostgreSQL):**
```bash
./start_backend.sh --docker
```

**Local PostgreSQL option (no Docker DB):**
```bash
./start_backend.sh
```

---

### Step 2: Run the Customer App

```bash
# Navigate to customer app
cd taskteddy_customer

# Get Flutter dependencies
flutter pub get

# Check connected devices
flutter devices

# Run the app (choose your device)
flutter run
```

**Or specify a device:**
```bash
# For Android emulator
flutter run -d android

# For Chrome (web)
flutter run -d chrome

# For specific device ID
flutter run -d <device_id>
```

---

### Step 3: Run the Tasker App

```bash
# Open a new terminal
# Navigate to tasker app
cd taskteddy_tasker

# Get Flutter dependencies
flutter pub get

# Run the app
flutter run
```

---

## 🔐 Demo Login Credentials

### Customer App:
- **Email:** `harry@example.com`
- **Password:** `password`

### Tasker App:
- **Email:** `rajesh@example.com`
- **Password:** `password`
- **OR**
- **Email:** `priya@example.com`
- **Password:** `password`

---

## 🛠️ Troubleshooting

### Issue: "Can't connect to backend"

**Solution:** Update the backend URL in the API service file:

For **Android Emulator:**
```dart
// taskteddy_customer/lib/services/api_service.dart
const _base = 'http://10.0.2.2:8000';
```

For **Physical Device** (same WiFi network):
```dart
// Replace with your computer's IP address
const _base = 'http://192.168.x.x:8000';
```

For **iOS Simulator:**
```dart
const _base = 'http://localhost:8000';
```

### Issue: "Flutter command not found"

**Solution:** Add Flutter to your PATH:
```bash
export PATH="$PATH:/path/to/flutter/bin"
```

### Issue: "No devices found"

**Solutions:**
1. Start an Android emulator from Android Studio
2. Connect a physical device with USB debugging enabled
3. Use Chrome for web testing: `flutter run -d chrome`

### Issue: "Build failed"

**Solution:** Clean and rebuild:
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: "Backend not responding"

**Solution:** Check backend status:
```bash
# Check if backend is running
curl http://localhost:8000/api/health

# Restart backend if needed
cd backend
pkill -f uvicorn
uvicorn server:app --host 0.0.0.0 --port 8000 --reload
```

---

## 📱 Testing the Apps

### Customer App Features:
1. **Browse Services** - See all available services
2. **Post a Task** - Create custom task requests
3. **Book Services** - Schedule professional services
4. **Manage Tasks** - View and manage your posted tasks
5. **Messages** - Chat with taskers
6. **Notifications** - Get updates

### Tasker App Features:
1. **Browse Tasks** - Find available tasks
2. **Apply to Tasks** - Submit bids with cover letters
3. **Active Tasks** - Manage accepted tasks
4. **Dashboard** - View earnings and stats
5. **Complete Tasks** - Use OTP verification
6. **Wallet** - Track earnings and withdraw

---

## 🔄 Running Both Apps Simultaneously

To test the full flow, run both apps at the same time:

**Terminal 1 (Backend):**
```bash
cd backend
uvicorn server:app --host 0.0.0.0 --port 8000 --reload
```

**Terminal 2 (Customer App):**
```bash
cd taskteddy_customer
flutter run -d <device1>
```

**Terminal 3 (Tasker App):**
```bash
cd taskteddy_tasker
flutter run -d <device2>
```

---

## 📊 Backend Management

### View API Documentation:
```bash
# Open in browser
http://localhost:8000/docs
```

### Check Database:
```bash
# Connect to PostgreSQL (Docker-mapped port)
psql postgresql://postgres:postgres@localhost:5433/taskteddy

# List TaskTeddy tables
\\dt tt_*
```

### Reseed Database (if needed):
```bash
cd backend
python3 seed.py
```

---

## 🎨 Development Tips

### Hot Reload:
- Press `r` in the Flutter terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

### Debug Mode:
```bash
# Run with verbose logging
flutter run -v
```

### Build APK:
```bash
cd taskteddy_customer
flutter build apk --release
# APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📞 Support

If you encounter any issues:
1. Check the backend logs: `tail -f backend.log`
2. Check Flutter logs in the terminal
3. Verify PostgreSQL is running: `pg_isready -h localhost -p 5433 -U postgres -d taskteddy`
4. Test backend API: `curl http://localhost:8000/api/health`

---

## 🎉 You're All Set!

Enjoy testing TaskTeddy - the complete marketplace for services and tasks!
