# 🌾 HerDoor - Flour Mill & Grain Processing Platform

[![Flutter](https://img.shields.io/badge/Flutter-v3.29%2B-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-v3.11%2B-0175C2.svg)](https://dart.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-v18%2B-green.svg)](https://nodejs.org/)
[![Express.js](https://img.shields.io/badge/Express-v4.19-blue.svg)](https://expressjs.com/)
[![MySQL](https://img.shields.io/badge/MySQL-v8.0-orange.svg)](https://www.mysql.com/)
[![Jest](https://img.shields.io/badge/Jest-v29-red.svg)](https://jestjs.io/)
[![CI/CD Pipeline](https://github.com/jaimiltrived/herdoor-/actions/workflows/ci.yml/badge.svg)](https://github.com/jaimiltrived/herdoor-/actions)
[![Swagger](https://img.shields.io/badge/Swagger-UI-brightgreen.svg)](http://localhost:5000/api-docs)
[![License](https://img.shields.io/badge/License-ISC-yellow.svg)](#license)

**HerDoor** is a comprehensive full-stack mobile and web platform designed to modernize local flour mills (*chakki*) and grain processing services. It includes a cross-platform **Flutter Mobile App** and a robust **Node.js/Express RESTful API Backend**, seamlessly connecting customers, flour mill owners (*shopkeepers*), and delivery partners to enable door-to-door grain grinding, fresh flour delivery, real-time order tracking, and inventory management.

---

## ✨ Key Features

- **📱 Flutter Mobile App UI**
  - Cross-platform mobile & web client built with modern Material 3 design and Google Fonts (`Outfit`).
  - Interactive authentication flows (Splash, Login, Register, Forgot Password).
  - Main navigation dashboard with bottom navigation bar & drawer navigation.
  - Nearby flour mill discovery list & detailed mill profile screens (grinding rates, mill status, reviews, operating hours).
  - New Order creation screen with grain type selection, processing options, and address selection.
  - Live Order Tracking screen with step-by-step lifecycle timeline, ETA, and mill/driver contact triggers.
  - User Profile, Saved Delivery Addresses, Payment Methods management, Notification Feed, and Help & Support center.
- **🔐 Authentication & Access Control**
  - Secure JWT authentication with role-based authorization (`CUSTOMER`, `SHOPKEEPER`, `DELIVERY`).
  - Mobile & Email authentication, OTP generation, verification, and password reset flows.
- **📍 Nearby Mill Discovery**
  - Geospatial mill search based on latitude, longitude, and radius.
  - View mill working hours, operating state (Open/Closed), and available processing services.
- **🌽 Grain & Grinding Catalog**
  - Flexible grain sourcing options: Customer-provided grain vs. Mill-supplied grain.
  - Multi-grain processing support (Wheat, Rice, Bajra, Jowar, Pulses, Spices).
- **📦 End-to-End Order Lifecycle**
  - Complete status workflow: `PENDING` ➔ `ACCEPTED` ➔ `PROCESSING` ➔ `PACKING` ➔ `READY` ➔ `PICKED_UP` ➔ `OUT_FOR_DELIVERY` ➔ `DELIVERED`.
  - Real-time estimated completion time (ETA) and full order timeline history.
- **🏪 Shopkeeper / Mill Dashboard**
  - Manage incoming orders, set processing ETAs, accept/reject requests.
  - Real-time stock-in & stock-out inventory tracking and store availability toggle.
- **🛵 Delivery Agent Interface**
  - Order assignment, mill pickup confirmation, live status tracking, and delivery confirmation.
- **💳 Payments & Refunds**
  - Integrated transaction workflow for UPI, Card, Net Banking, and COD with refund handling.
- **⭐ Ratings, Reviews & Notifications**
  - Verified order reviews and ratings for flour mills.
  - Push notification token registration (FCM) and in-app notification center.
- **🌱 Automated JavaScript Database Seeder**
  - Standalone seeding script (`npm run seed`) to quickly initialize MySQL schema data and passwords.
- **🧪 Comprehensive Test Suite & CI/CD**
  - Modular unit and integration test suite with Jest & Supertest.
  - Continuous Integration pipeline via GitHub Actions.

---

## 🛠️ Technology Stack

### Frontend / Mobile App
- **Framework**: Flutter (v3.29+)
- **Language**: Dart (v3.11+)
- **Design & Typography**: Material Design 3 & Google Fonts (`Outfit`)
- **Icons**: `cupertino_icons`

### Backend API & Database
- **Runtime**: Node.js (v18+, v20+)
- **Framework**: Express.js
- **Database**: MySQL 8.0 / MySQL2 with Connection Pooling & In-Memory Data Store Fallback
- **Testing**: Jest & Supertest
- **CI/CD**: GitHub Actions (`.github/workflows/ci.yml`)
- **Authentication**: JSON Web Tokens (`jsonwebtoken`) & `bcryptjs`
- **API Documentation**: Swagger (`swagger-jsdoc` & `swagger-ui-express`)
- **Security & Utilities**: `helmet`, `cors`, `morgan`, `dotenv`

---

## 📁 Repository Structure

```
herdoor/
├── .github/
│   └── workflows/
│       └── ci.yml                   # GitHub Actions CI/CD workflow definition
├── database/
│   ├── schema.sql                   # MySQL DDL schema definitions
│   └── seed.sql                     # SQL seed script
├── frontend/                        # Flutter Mobile & Cross-Platform Application
│   ├── android/                     # Android platform configurations
│   ├── ios/                         # iOS platform configurations
│   ├── lib/                         # Application source code
│   │   ├── models/                  # Data models (Order, Mill, User, Notification)
│   │   ├── screens/                 # UI Screens (Auth, Dashboard, Mills, Orders, Tracking, Profile, etc.)
│   │   ├── theme/                   # Custom AppTheme, palette & typography
│   │   ├── widgets/                 # Reusable UI components & drawers
│   │   └── main.dart                # Flutter app entry point
│   ├── pubspec.yaml                 # Flutter dependencies & metadata
│   └── web/                         # Web platform files
├── scripts/
│   ├── init-db.js                   # Database initialization script
│   └── seed.js                      # JavaScript database seeder
├── tests/
│   ├── auth.test.js                 # Authentication & user tests
│   ├── health.test.js               # Health check & docs tests
│   ├── mills.test.js                # Flour mills & grain catalog tests
│   └── orders.test.js               # Order lifecycle & state machine tests
├── src/
│   ├── config/                      # Database & JWT configurations
│   ├── constants/                   # Roles, statuses, and response codes
│   ├── controllers/                 # Business logic and request handlers
│   ├── middleware/                  # Auth, validation, & error handling
│   ├── routes/                      # API endpoint routing modules
│   ├── store/                       # Data persistence abstractions
│   ├── utils/                       # Response formatters & helpers
│   ├── app.js                       # Express app configuration & middleware setup
│   └── server.js                    # Application entry point
├── API_DOCUMENTATION.md             # Detailed endpoint reference
├── herdoor_postman_collection.json  # Postman API Collection
├── test-endpoints.js                # E2E API test script
├── package.json
└── README.md
```

---

## 🚀 Quick Start Guide

### Prerequisites

- [Node.js](https://nodejs.org/) (v18 or higher)
- [npm](https://www.npmjs.com/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.29+ for running frontend)
- [MySQL Server](https://www.mysql.com/) (Optional - in-memory fallback enabled for testing)

### Backend API Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/jaimiltrived/herdoor-.git
   cd herdoor-
   ```

2. **Install API dependencies**:
   ```bash
   npm install
   ```

3. **Configure Environment Variables**:
   Create a `.env` file in the root directory (or copy from `.env.example`):
   ```env
   PORT=5000
   NODE_ENV=development
   JWT_SECRET=herdoor_super_secret_jwt_key_2026
   DB_HOST=localhost
   DB_PORT=3307
   DB_USER=root
   DB_PASSWORD=yourpassword
   DB_NAME=herdoor
   ```

4. **Initialize & Seed Database**:
   - Initialize schema:
     ```bash
     npm run db:init
     ```
   - Run JavaScript Seeder:
     ```bash
     npm run seed
     ```

5. **Start the API Server**:
   - **Development Mode**:
     ```bash
     npm run dev
     ```
   - **Production Mode**:
     ```bash
     npm start
     ```

6. **Run Backend Test Suites**:
   - **Unit & Integration Tests**:
     ```bash
     npm test
     ```
   - **Standalone End-to-End API Tests**:
     ```bash
     npm run test:e2e
     ```

### Frontend Mobile App Setup

1. **Navigate to the frontend folder**:
   ```bash
   cd frontend
   ```

2. **Install Flutter packages**:
   ```bash
   flutter pub get
   ```

3. **Run the Flutter Application**:
   ```bash
   # Run on connected mobile device or emulator
   flutter run

   # Or run in Chrome browser
   flutter run -d chrome
   ```


---

## 🔄 CI/CD Pipeline

This project uses **GitHub Actions** for Continuous Integration. Every `push` or `pull_request` to the `main`, `master`, or `develop` branch automatically runs:
1. Multi-version Node.js environment build matrix (`18.x`, `20.x`).
2. MySQL 8.0 service container startup.
3. Automated database initialization & JavaScript seeding.
4. Execution of the Jest test suite (`npm test`) and E2E verification (`npm run test:e2e`).

The workflow configuration file is located at [.github/workflows/ci.yml](file:///d:/herdoor/.github/workflows/ci.yml).

---

## 🌐 API Endpoint Overview

All endpoints are prefixed with `/api/v1`.

| Module | Route Prefix | Description |
|---|---|---|
| **Auth** | `/api/v1/auth` | User registration, login, OTP, password reset, token refresh |
| **Users** | `/api/v1/users` | Customer profile management, saved delivery addresses |
| **Mills** | `/api/v1/mills` | Nearby mill geospatial search, mill availability & details |
| **Grains** | `/api/v1/grain-sources`, `/api/v1/grain-types` | Grain catalogs and service definitions |
| **Orders** | `/api/v1/orders` | Place orders, active orders, history, tracking, cancellation |
| **Payments** | `/api/v1/payments` | Payment creation, verification, status check, refund |
| **Delivery** | `/api/v1/delivery` | Delivery driver app endpoints, order assignment & updates |
| **Reviews** | `/api/v1/orders/{id}/review`, `/api/v1/reviews` | Ratings & review management |
| **Notifications** | `/api/v1/notifications`, `/api/v1/devices` | Notification feed & FCM push token registration |
| **Shopkeeper** | `/api/v1/shopkeeper` | Mill owner dashboard, order management, inventory stock-in/out |

> 📑 For complete API specification, query parameters, and example payload details, see [API_DOCUMENTATION.md](file:///d:/herdoor/API_DOCUMENTATION.md) or open `http://localhost:5000/api-docs` when running the server.

---

## 📚 API Documentation & Postman

- **Swagger UI**: Visit `http://localhost:5000/api-docs` in your browser while the server is running.
- **Postman Collection**: Import [herdoor_postman_collection.json](file:///d:/herdoor/herdoor_postman_collection.json) into Postman to test all routes with pre-configured requests.

---

## 📄 License

This project is licensed under the ISC License.
