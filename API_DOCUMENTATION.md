# HerDoor Multi-Role API Documentation Reference

Complete REST API specification for HerDoor - Flour Mill & Grain Processing platform supporting:
1. 👤 **Customer / Consumer** (Flutter Mobile App)
2. 🏪 **Merchant / Mill Owner** (Flutter Mobile & Tablet App)
3. 🛵 **Delivery Partner / Rider** (Flutter Mobile App)
4. 🛡️ **Admin Web Console** (React / Vite Admin Dashboard)

- **Base URL**: `http://localhost:5000/api/v1`
- **Interactive Swagger UI**: [http://localhost:5000/api-docs](http://localhost:5000/api-docs)
- **OpenAPI JSON Spec**: `http://localhost:5000/api-docs.json`
- **Authentication**: JWT Bearer Token via HTTP Header `Authorization: Bearer <token>`

---

## 🔐 1. Authentication APIs (`/api/v1/auth`)

| Method | Endpoint | Auth | Role | Purpose | Request Body |
|---|---|---|---|---|---|
| `POST` | `/api/v1/auth/register` | None | Any | Register user account | `{ "name", "email", "phone", "password", "role" }` |
| `POST` | `/api/v1/auth/login` | None | Any | User/Admin login & token | `{ "email" / "phone", "password" }` |
| `GET` | `/api/v1/auth/me` | Bearer | Any | Get current session profile | None |
| `POST` | `/api/v1/auth/forgot-password` | None | Any | Request reset OTP | `{ "email" / "phone" }` |
| `POST` | `/api/v1/auth/reset-password` | None | Any | Reset password with OTP | `{ "otp", "newPassword" }` |
| `PUT` | `/api/v1/auth/change-password` | Bearer | Any | Update password | `{ "currentPassword", "newPassword" }` |

---

## 👤 2. Customer / Consumer APIs (`/api/v1/orders`, `/api/v1/mills`, `/api/v1/users`)

| Method | Endpoint | Auth | Purpose | Request Body / Query |
|---|---|---|---|---|
| `GET` | `/api/v1/mills/nearby` | None | Geospatial mill discovery | `?latitude=23.0225&longitude=72.5714&radius=10` |
| `GET` | `/api/v1/grain-types` | None | List available grain types | None |
| `GET` | `/api/v1/grain-sources` | None | List grain source options | None |
| `POST` | `/api/v1/orders` | Bearer | Place custom milling order | `{ "millId": 101, "grainSource": "CUSTOMER", "grainTypeId": 1, "quantityKg": 10, "serviceType": "GRINDING", "fulfillmentType": "DELIVERY", "addressId": 25, "paymentMethod": "UPI" }` |
| `GET` | `/api/v1/orders` | Bearer | List customer's orders | `?page=1&limit=20&status=PROCESSING` |
| `GET` | `/api/v1/orders/active` | Bearer | List active orders | None |
| `GET` | `/api/v1/orders/completed` | Bearer | List order history | None |
| `GET` | `/api/v1/orders/{orderId}` | Bearer | Order detail breakdown | None |
| `GET` | `/api/v1/orders/{orderId}/tracking` | Bearer | Live tracking timeline & ETA | None |
| `POST` | `/api/v1/orders/{orderId}/cancel` | Bearer | Cancel order before packing | `{ "reason": "Customer cancellation" }` |
| `POST` | `/api/v1/orders/{orderId}/repeat` | Bearer | 1-Tap repeat re-order | None |
| `POST` | `/api/v1/orders/{orderId}/confirm-receipt` | Bearer | Confirm delivery receipt | None |
| `POST` | `/api/v1/orders/{orderId}/review` | Bearer | Submit 5-star rating & review | `{ "rating": 5, "review": "Fresh and fine!" }` |
| `GET` | `/api/v1/users/me/addresses` | Bearer | Get saved addresses | None |
| `POST` | `/api/v1/users/me/addresses` | Bearer | Save new address | `{ "addressLine1", "city", "pincode", "latitude", "longitude" }` |

---

## 🏪 3. Merchant / Mill Owner APIs (`/api/v1/shopkeeper`)

| Method | Endpoint | Auth | Purpose | Request Body |
|---|---|---|---|---|
| `GET` | `/api/v1/shopkeeper/dashboard` | Bearer | Real-time KPIs & daily revenue | None |
| `GET` | `/api/v1/shopkeeper/profile` | Bearer | Get mill & owner details | None |
| `PUT` | `/api/v1/shopkeeper/profile` | Bearer | Update mill & owner profile | `{ "name", "phone", "address", "services" }` |
| `GET` | `/api/v1/shopkeeper/orders/pending` | Bearer | Incoming orders queue | None |
| `GET` | `/api/v1/shopkeeper/orders/active` | Bearer | Active milling jobs | None |
| `GET` | `/api/v1/shopkeeper/orders/completed` | Bearer | Completed orders | None |
| `POST` | `/api/v1/shopkeeper/orders/{id}/accept` | Bearer | Accept order & set completion ETA | `{ "estimatedCompletionMinutes": 30 }` |
| `POST` | `/api/v1/shopkeeper/orders/{id}/reject` | Bearer | Decline order with reason | `{ "reason": "Store busy" }` |
| `PUT` | `/api/v1/shopkeeper/orders/{id}/completion-time` | Bearer | Adjust completion time | `{ "estimatedCompletionMinutes": 40 }` |
| `POST` | `/api/v1/shopkeeper/orders/{id}/start` | Bearer | Start milling / grinding | None |
| `POST` | `/api/v1/shopkeeper/orders/{id}/packing` | Bearer | Start flour packing | None |
| `POST` | `/api/v1/shopkeeper/orders/{id}/ready` | Bearer | Mark ready for pickup / delivery | None |
| `POST` | `/api/v1/shopkeeper/orders/{id}/handover` | Bearer | Handover order to driver with PIN | `{ "pin": "4821" }` |
| `POST` | `/api/v1/shopkeeper/orders/{id}/complete` | Bearer | Complete self-pickup order | None |
| `GET` | `/api/v1/shopkeeper/inventory` | Bearer | List grain & flour stock items | None |
| `GET` | `/api/v1/shopkeeper/inventory/low-stock` | Bearer | Get low-stock items | None |
| `POST` | `/api/v1/shopkeeper/inventory` | Bearer | Add new inventory item | `{ "name", "productType", "stockKg", "minimumStockKg", "pricePerKg" }` |
| `PUT` | `/api/v1/shopkeeper/inventory/{id}` | Bearer | Update inventory item | Inventory fields |
| `DELETE` | `/api/v1/shopkeeper/inventory/{id}` | Bearer | Remove inventory item | None |
| `POST` | `/api/v1/shopkeeper/inventory/{id}/stock-in` | Bearer | Add stock in kg | `{ "kg": 50 }` |
| `POST` | `/api/v1/shopkeeper/inventory/{id}/stock-out` | Bearer | Deduct stock in kg | `{ "kg": 20 }` |
| `GET` | `/api/v1/shopkeeper/availability` | Bearer | Get Open/Closed status | None |
| `PUT` | `/api/v1/shopkeeper/availability` | Bearer | Toggle Open/Closed status | `{ "isOpen": true }` |
| `PUT` | `/api/v1/shopkeeper/working-hours` | Bearer | Update mill working hours | `{ "workingHours": "08:00 AM - 08:00 PM" }` |

---

## 🛵 4. Delivery Partner / Rider APIs (`/api/v1/delivery`)

| Method | Endpoint | Auth | Purpose | Request Body |
|---|---|---|---|---|
| `POST` | `/api/v1/delivery/auth/login` | None | Rider login | `{ "email" / "phone", "password" }` |
| `GET` | `/api/v1/delivery/profile` | Bearer | Get rider vehicle & ratings | None |
| `PUT` | `/api/v1/delivery/status` | Bearer | Toggle online/offline status | `{ "isOnline": true }` |
| `GET` | `/api/v1/delivery/available-trips` | Bearer | List orders waiting for pickup | None |
| `GET` | `/api/v1/delivery/assigned` | Bearer | Current active assigned trips | None |
| `GET` | `/api/v1/delivery/completed` | Bearer | Rider delivered trip history | None |
| `POST` | `/api/v1/delivery/orders/{id}/accept` | Bearer | Accept delivery task | None |
| `POST` | `/api/v1/delivery/orders/{id}/pickup` | Bearer | Confirm pickup from mill | `{ "pin": "4821" }` |
| `POST` | `/api/v1/delivery/orders/{id}/out-for-delivery` | Bearer | En route to customer | None |
| `POST` | `/api/v1/delivery/orders/{id}/location` | Bearer | Stream live GPS coordinates | `{ "latitude": 23.0245, "longitude": 72.5708 }` |
| `POST` | `/api/v1/delivery/orders/{id}/deliver` | Bearer | Complete delivery with OTP | `{ "otp": "7391" }` |
| `GET` | `/api/v1/delivery/earnings` | Bearer | Daily & weekly earnings summary | None |

---

## 🛡️ 5. Admin Web Console APIs (`/api/v1/admin`)

| Method | Endpoint | Auth | Purpose | Request Body / Query |
|---|---|---|---|---|
| `GET` | `/api/v1/admin/dashboard` | Bearer | Platform wide KPIs & active fleets | None |
| `GET` | `/api/v1/admin/mills` | Bearer | Master flour mills list | None |
| `POST` | `/api/v1/admin/mills` | Bearer | Register new mill on platform | `{ "name", "address", "phone", "capacityKgPerDay" }` |
| `PUT` | `/api/v1/admin/mills/{id}` | Bearer | Update mill information | Mill fields |
| `DELETE` | `/api/v1/admin/mills/{id}` | Bearer | Remove/deactivate mill | None |
| `GET` | `/api/v1/admin/riders` | Bearer | List delivery fleet partners | None |
| `PUT` | `/api/v1/admin/riders/{id}/status` | Bearer | Activate/suspend driver | `{ "isOnline": true }` |
| `GET` | `/api/v1/admin/wholesalers` | Bearer | List grain wholesalers & stock | None |
| `POST` | `/api/v1/admin/wholesalers` | Bearer | Register grain supplier | `{ "name", "phone", "city", "grainsSupplied" }` |
| `GET` | `/api/v1/admin/orders` | Bearer | Master orders ledger | `?status=PROCESSING&millId=101` |
| `PUT` | `/api/v1/admin/orders/{id}/status` | Bearer | Superadmin override order status | `{ "status": "COMPLETED", "note": "Admin override" }` |
| `GET` | `/api/v1/admin/security` | Bearer | Platform security & audit logs | None |
| `GET` | `/api/v1/admin/fraud` | Bearer | Fraud monitor alerts | None |
| `GET` | `/api/v1/admin/withdrawals` | Bearer | Merchant/Rider payout records | None |
| `GET` | `/api/v1/admin/refunds` | Bearer | Customer refund requests | None |

---

## 🔔 6. Notifications & FCM Devices (`/api/v1/notifications`)

| Method | Endpoint | Auth | Purpose | Request Body |
|---|---|---|---|---|
| `GET` | `/api/v1/notifications` | Bearer | Get user notifications | None |
| `GET` | `/api/v1/notifications/unread` | Bearer | Get unread notification count | None |
| `PUT` | `/api/v1/notifications/{id}/read` | Bearer | Mark notification as read | None |
| `PUT` | `/api/v1/notifications/read-all` | Bearer | Mark all notifications as read | None |
| `POST` | `/api/v1/notifications/devices/register` | Bearer | Register mobile FCM token | `{ "fcmToken", "deviceType": "ANDROID" }` |

---

## 🧪 Quick Test Credentials

| Role | Email | Password | Phone |
|---|---|---|---|
| **Customer** | `ramesh@example.com` | `Password123!` | `+919876543210` |
| **Merchant** | `shop@shreeganesh.com` | `Password123!` | `+919876543211` |
| **Delivery Rider** | `delivery@herdoor.com` | `Password123!` | `+919876543212` |
| **Admin** | `admin@herdoor.com` | `Password123!` | `+919876543200` |
