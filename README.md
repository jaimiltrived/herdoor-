# 🌾 HerDoor API - Flour Mill & Grain Processing Platform

[![Node.js](https://img.shields.io/badge/Node.js-v18%2B-green.svg)](https://nodejs.org/)
[![Express.js](https://img.shields.io/badge/Express-v4.19-blue.svg)](https://expressjs.com/)
[![MySQL](https://img.shields.io/badge/MySQL-v8.0-orange.svg)](https://www.mysql.com/)
[![Swagger](https://img.shields.io/badge/Swagger-UI-brightgreen.svg)](http://localhost:5000/api-docs)
[![License](https://img.shields.io/badge/License-ISC-yellow.svg)](#license)

**HerDoor** is a comprehensive RESTful API backend platform designed to modernize local flour mills (*chakki*) and grain processing services. It seamlessly connects customers, flour mill owners (*shopkeepers*), and delivery partners to enable door-to-door grain grinding, fresh flour delivery, real-time order tracking, and inventory management.

---

## ✨ Key Features

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
  - Complete status workflow: `PENDING` ➔ `ACCEPTED` ➔ `GRINDING` ➔ `PACKING` ➔ `READY` ➔ `PICKED_UP` ➔ `OUT_FOR_DELIVERY` ➔ `DELIVERED`.
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
- **📖 Interactive OpenAPI Documentation**
  - Built-in Swagger UI and ready-to-use Postman collection.

---

## 🛠️ Technology Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MySQL 8.0 / MySQL2 with Connection Pooling & In-Memory Data Store Fallback
- **Authentication**: JSON Web Tokens (`jsonwebtoken`) & `bcryptjs`
- **API Documentation**: Swagger (`swagger-jsdoc` & `swagger-ui-express`)
- **Security & Utilities**: `helmet`, `cors`, `morgan`, `dotenv`

---

## 📁 Repository Structure

```
herdoor/
├── database/
│   └── seed.sql                     # MySQL database schema & sample data
├── scripts/
│   └── init-db.js                   # Database initialization script
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
├── test-endpoints.js                # API endpoint test suite
├── package.json
└── README.md
```

---

## 🚀 Quick Start Guide

### Prerequisites

- [Node.js](https://nodejs.org/) (v18 or higher)
- [npm](https://www.npmjs.com/)
- [MySQL Server](https://www.mysql.com/) (Optional - in-memory fallback enabled for testing)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/jaimiltrived/herdoor-.git
   cd herdoor-
   ```

2. **Install dependencies**:
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
   DB_USER=root
   DB_PASSWORD=yourpassword
   DB_NAME=herdoor_db
   ```

4. **Initialize Database** *(Optional)*:
   ```bash
   npm run db:init
   ```

5. **Start the Application**:
   - **Development Mode** (with Nodemon):
     ```bash
     npm run dev
     ```
   - **Production Mode**:
     ```bash
     npm start
     ```

6. **Run Endpoint Tests**:
   ```bash
   npm test
   ```

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
