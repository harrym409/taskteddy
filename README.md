# 🐻 TaskTeddy - Complete Service Marketplace

A comprehensive two-sided marketplace Flutter application connecting customers with service providers (taskers) for on-demand tasks and professional services.

## 🌟 Features

### Customer App
- 🏠 Browse & book professional services
- 📋 Post custom task requests
- 💬 Real-time chat with taskers
- 📅 Manage bookings & tasks
- ⭐ Rate & review taskers
- 🔔 Push notifications
- 🎁 Rewards & coins system

### Tasker App
- 🔍 Browse available tasks
- 💼 Apply to tasks with bids
- 📊 Dashboard with earnings
- 💰 Wallet & withdrawals
- ⭐ Build reputation with reviews
- 📈 Track performance stats
- 🔔 Task notifications

### Backend API
- 🔐 JWT authentication
- 👥 User management (Customer/Tasker roles)
- 🛍️ Services marketplace
- 📋 Task management system
- 💳 Bookings & applications
- 💬 Real-time messaging
- ⭐ Reviews & ratings
- 💰 Wallet & transactions
- 🔔 Notifications system
- 📤 Image upload handling

## 🚀 Quick Start

### 1. Start Backend (Recommended: Local FastAPI + PostgreSQL in Docker)
```bash
./start_backend.sh --db-docker
```

### 1b. Start Backend (Local FastAPI + Local PostgreSQL)
```bash
./start_backend.sh
```

### 1c. Start Backend + Database in Docker
```bash
./start_backend.sh --docker
```

### 2. Run Customer App
```bash
cd taskteddy_customer
flutter pub get
flutter run
```

### 3. Run Tasker App
```bash
cd taskteddy_tasker
flutter pub get
flutter run
```

## 🔐 Demo Credentials

| Role | Email | Password |
|------|-------|----------|
| Customer | harry@example.com | password |
| Tasker 1 | rajesh@example.com | password |
| Tasker 2 | priya@example.com | password |

## 📁 Project Structure

```
/app/
├── backend/                    # FastAPI Backend
│   ├── server.py              # Main API server
│   ├── models/                # Pydantic schemas
│   ├── routes/                # API endpoints
│   ├── utils/                 # Auth & uploads
│   └── seed.py                # Database seeder
│
├── taskteddy_customer/        # Customer Flutter App
│   ├── lib/
│   │   ├── main.dart         # Entry point
│   │   ├── models/           # Data models
│   │   ├── screens/          # UI screens
│   │   ├── services/         # API service
│   │   └── theme/            # App theme
│   └── pubspec.yaml
│
└── taskteddy_tasker/          # Tasker Flutter App
    ├── lib/
    │   ├── main.dart         # Entry point
    │   ├── models/           # Data models
    │   ├── screens/          # UI screens
    │   └── theme/            # App theme
    └── pubspec.yaml
```

## 🛠️ Technology Stack

### Frontend (Flutter)
- Flutter 3.0+
- Material Design 3
- Google Fonts
- HTTP client
- Shared Preferences

### Backend (Python)
- FastAPI
- PostgreSQL
- Psycopg
- JWT authentication
- Pydantic validation
- Uvicorn server

## 📚 API Documentation

Once the backend is running, visit:
- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc

## 🔧 Configuration

### Backend URL Setup

For **Android Emulator:**
```dart
const _base = 'http://10.0.2.2:8000';
```

For **Physical Device:**
```dart
const _base = 'http://YOUR_COMPUTER_IP:8000';
```

For **iOS Simulator:**
```dart
const _base = 'http://localhost:8000';
```

## 📋 Available Services

The platform includes 10+ pre-seeded services:
- 🧹 Home Deep Clean
- 🚿 Bathroom Cleaning
- ❄️ AC Service & Repair
- 🔧 Plumber Visit
- 💇 Women's Salon
- ⚡ Electrician
- 🍽️ Kitchen Cleaning
- 🦟 Pest Control
- 🧘 Yoga at Home
- 🪚 Carpenter

## 🎯 Key Workflows

### Customer Flow
1. Browse services or post a task
2. Book a service or receive task applications
3. Accept a tasker's application
4. Chat with tasker during task
5. Verify completion with OTP
6. Rate and review tasker

### Tasker Flow
1. Browse available tasks
2. Apply with bid and cover letter
3. Get accepted by customer
4. Complete the task
5. Get OTP from customer
6. Receive payment to wallet
7. Withdraw earnings

## 🔒 Security Features

- JWT token-based authentication
- Password hashing with bcrypt
- Secure API endpoints
- Role-based access control
- Input validation
- File upload restrictions

## 📱 Testing

### Test Complete Flow
1. Login as customer (harry@example.com)
2. Post a new task
3. Login as tasker (rajesh@example.com) on different device
4. Apply to the task
5. Accept application as customer
6. Complete task as tasker
7. Verify with OTP
8. Leave a review

## 🐛 Troubleshooting

See `RUN_INSTRUCTIONS.md` for detailed troubleshooting guide.

## 📄 License

This is a demo project for TaskTeddy marketplace platform.

## 🤝 Support

For issues or questions, check:
- Backend logs: `tail -f backend.log`
- PostgreSQL status: `pg_isready`
- API health: `curl http://localhost:8000/api/health`

---

Made with ❤️ using Flutter & FastAPI
