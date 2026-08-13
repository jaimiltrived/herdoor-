# HerDoor API Documentation Reference

Complete REST API specification for HerDoor - Flour Mill & Grain Processing platform.

- **Base URL**: `http://localhost:5000/api/v1`
- **Interactive Swagger UI**: [http://localhost:5000/api-docs](http://localhost:5000/api-docs)
- **Authentication**: JWT Token via HTTP Header `Authorization: Bearer <token>`

---

## 🔐 1. Authentication APIs (`/api/v1/auth`)

| Method | Endpoint | Auth | Purpose | Request Body |
|---|---|---|---|---|
| `POST` | `/api/v1/auth/register` | None | Register new user | `{ "name", "email", "phone", "password", "role" }` |
| `POST` | `/api/v1/auth/login` | None | User login & token retrieval | `{ "email" / "phone", "password" }` |
| `POST` | `/api/v1/auth/logout` | None | Invalidate session | None |
| `POST` | `/api/v1/auth/refresh-token` | Bearer | Refresh JWT token | None |
| `POST` | `/api/v1/auth/forgot-password` | None | Request OTP for password reset | `{ "email" / "phone" }` |
| `POST` | `/api/v1/auth/reset-password` | None | Reset password with OTP | `{ "otp", "newPassword" }` |
| `POST` | `/api/v1/auth/verify-otp` | None | Verify OTP code | `{ "otp" }` |
| `POST` | `/api/v1/auth/resend-otp` | None | Resend OTP code | `{ "phone" }` |
| `GET` | `/api/v1/auth/me` | Bearer | Get current logged-in user profile | None |
| `PUT` | `/api/v1/auth/change-password` | Bearer | Change current password | `{ "currentPassword", "newPassword" }` |

---

## 👤 2. Main User / Customer Profile APIs (`/api/v1/users`)

| Method | Endpoint | Auth | Purpose | Request Body |
|---|---|---|---|---|
| `GET` | `/api/v1/users/me` | Bearer | Get user profile details | None |
| `PUT` | `/api/v1/users/me` | Bearer | Update user profile details | `{ "name", "phone" }` |
| `POST` | `/api/v1/users/me/profile-image` | Bearer | Upload/update profile image | `{ "imageUrl" }` |
| `GET` | `/api/v1/users/me/addresses` | Bearer | Get all saved addresses | None |
| `POST` | `/api/v1/users/me/addresses` | Bearer | Add new delivery address | `{ "addressLine1", "city", "pincode", "latitude", "longitude" }` |
| `PUT` | `/api/v1/users/me/addresses/{id}` | Bearer | Update saved address | Address fields |
| `DELETE` | `/api/v1/users/me/addresses/{id}` | Bearer | Delete address | None |
| `PUT` | `/api/v1/users/me/addresses/{id}/default` | Bearer | Set default delivery address | None |

---

## 🌾 3. Nearby Mill APIs (`/api/v1/mills`)

| Method | Endpoint | Auth | Purpose | Query / Request |
|---|---|---|---|---|
| `GET` | `/api/v1/mills/nearby` | None | Geospatial nearby mill locator | `?latitude=23.0225&longitude=72.5714&radius=5` |
| `GET` | `/api/v1/mills` | None | Search & filter mills | `?search=Ganesh&isOpen=true` |
| `GET` | `/api/v1/mills/{millId}` | None | Get specific mill details | None |
| `GET` | `/api/v1/mills/{millId}/services` | None | List available mill services | None |
| `GET` | `/api/v1/mills/{millId}/grains` | None | List available grain types | None |
| `GET` | `/api/v1/mills/{millId}/availability` | None | Check mill open/close state | None |
| `GET` | `/api/v1/mills/{millId}/working-hours` | None | Get mill working hours | None |
| `GET` | `/api/v1/mills/{millId}/ratings` | None | Get mill ratings & reviews | None |

---

## 🌽 4. Grain Catalog APIs (`/api/v1`)

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| `GET` | `/api/v1/grain-sources` | None | List grain sources (`CUSTOMER`, `MILL`, `VENDOR`) |
| `GET` | `/api/v1/grain-sources/{id}` | None | Get specific grain source details |
| `GET` | `/api/v1/grain-types` | None | List all grain types (Wheat, Rice, Bajra, etc.) |
| `GET` | `/api/v1/grain-types/{id}` | None | Get specific grain type details |

---

## 📦 5. Customer Order APIs (`/api/v1/orders`)

| Method | Endpoint | Auth | Purpose | Request Body |
|---|---|---|---|---|
| `POST` | `/api/v1/orders` | Bearer | Place a new order | `{ "millId": 101, "grainSource": "CUSTOMER", "grainTypeId": 1, "quantityKg": 10, "serviceType": "GRINDING", "fulfillmentType": "DELIVERY", "addressId": 25, "paymentMethod": "UPI" }` |
| `GET` | `/api/v1/orders` | Bearer | Get customer orders | `?page=1&limit=20&status=COMPLETED` |
| `GET` | `/api/v1/orders/active` | Bearer | Get active processing orders | None |
| `GET` | `/api/v1/orders/history` | Bearer | Get completed orders history | None |
| `GET` | `/api/v1/orders/cancelled` | Bearer | Get cancelled orders | None |
| `GET` | `/api/v1/orders/{orderId}` | Bearer | Get specific order details | None |
| `GET` | `/api/v1/orders/{orderId}/status` | Bearer | Get current order status | None |
| `GET` | `/api/v1/orders/{orderId}/timeline` | Bearer | Get full status history timeline | None |
| `GET` | `/api/v1/orders/{orderId}/estimated-time` | Bearer | Get estimated completion time | None |
| `GET` | `/api/v1/orders/{orderId}/tracking` | Bearer | Get real-time delivery tracking | None |
| `POST` | `/api/v1/orders/{orderId}/cancel` | Bearer | Cancel order (if before packing) | `{ "reason": "Changed mind" }` |
| `POST` | `/api/v1/orders/{orderId}/confirm-receipt` | Bearer | Confirm order received | None |
| `POST` | `/api/v1/orders/{orderId}/repeat` | Bearer | Reorder previous order | None |

---

## 💳 6. Payment APIs (`/api/v1/payments`)

| Method | Endpoint | Auth | Purpose | Request Body |
|---|---|---|---|---|
| `POST` | `/api/v1/payments/create` | Bearer | Create payment transaction | `{ "orderId": 501, "amount": 90, "paymentMethod": "UPI" }` |
| `POST` | `/api/v1/payments/verify` | Bearer | Verify payment gateway callback | `{ "paymentId": "PAY-1001", "transactionId": "TXN_123" }` |
| `GET` | `/api/v1/payments/{paymentId}` | Bearer | Get payment status details | None |
| `GET` | `/api/v1/payments/order/{orderId}` | Bearer | Get payment details for order | None |
| `POST` | `/api/v1/payments/{paymentId}/refund` | Bearer | Request payment refund | None |

---

## 🛵 7. Delivery Person APIs (`/api/v1/delivery`)

| Method | Endpoint | Auth | Purpose | Request Body |
|---|---|---|---|---|
| `POST` | `/api/v1/delivery/auth/login` | None | Delivery person login | `{ "email" / "phone", "password" }` |
| `GET` | `/api/v1/delivery/orders` | Bearer | List delivery orders | None |
| `GET` | `/api/v1/delivery/orders/assigned` | Bearer | Get assigned orders for logged agent | None |
| `POST` | `/api/v1/delivery/orders/{orderId}/accept` | Bearer | Accept delivery task | None |
| `POST` | `/api/v1/delivery/orders/{orderId}/picked-up` | Bearer | Mark picked up from mill | None |
| `POST` | `/api/v1/delivery/orders/{orderId}/out-for-delivery` | Bearer | Mark out for delivery | None |
| `POST` | `/api/v1/delivery/orders/{orderId}/delivered` | Bearer | Mark order delivered to customer | None |

---

## ⭐ 8. Ratings & Review APIs (`/api/v1`)

| Method | Endpoint | Auth | Purpose | Request Body |
|---|---|---|---|---|
| `POST` | `/api/v1/orders/{orderId}/review` | Bearer | Submit review for completed order | `{ "rating": 5, "review": "Great quality!" }` |
| `GET` | `/api/v1/orders/{orderId}/review` | Bearer | Get review for specific order | None |
| `PUT` | `/api/v1/reviews/{reviewId}` | Bearer | Update review | `{ "rating", "review" }` |
| `DELETE` | `/api/v1/reviews/{reviewId}` | Bearer | Delete review | None |

---

## 🔔 9. Notification APIs (`/api/v1`)

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| `GET` | `/api/v1/notifications` | Bearer | List all notifications |
| `GET` | `/api/v1/notifications/unread` | Bearer | List unread notifications |
| `PUT` | `/api/v1/notifications/{id}/read` | Bearer | Mark notification as read |
| `PUT` | `/api/v1/notifications/read-all` | Bearer | Mark all notifications read |
| `POST` | `/api/v1/devices/register` | Bearer | Register FCM push notification token |

---

## 🏪 10. Shopkeeper / Mill Dashboard APIs (`/api/v1/shopkeeper`)

| Method | Endpoint | Auth | Purpose | Request Body |
|---|---|---|---|---|
| `GET` | `/api/v1/shopkeeper/dashboard` | Bearer | Get dashboard metrics | None |
| `GET` | `/api/v1/shopkeeper/orders/pending` | Bearer | List new pending orders | None |
| `GET` | `/api/v1/shopkeeper/orders/active` | Bearer | List active processing orders | None |
| `GET` | `/api/v1/shopkeeper/revenue` | Bearer | Get total mill revenue | None |
| `POST` | `/api/v1/shopkeeper/orders/{orderId}/accept` | Bearer | Accept order & set completion ETA | `{ "estimatedCompletionMinutes": 45 }` |
| `POST` | `/api/v1/shopkeeper/orders/{orderId}/reject` | Bearer | Reject order | `{ "reason": "Machine maintenance" }` |
| `POST` | `/api/v1/shopkeeper/orders/{orderId}/start` | Bearer | Start grinding processing | None |
| `POST` | `/api/v1/shopkeeper/orders/{orderId}/packing` | Bearer | Start packing order | None |
| `POST` | `/api/v1/shopkeeper/orders/{orderId}/ready` | Bearer | Mark order ready for delivery/pickup | None |
| `POST` | `/api/v1/shopkeeper/orders/{orderId}/handover` | Bearer | Handover order to delivery agent | None |
| `GET` | `/api/v1/shopkeeper/inventory` | Bearer | Get flour & grain inventory | None |
| `POST` | `/api/v1/shopkeeper/inventory/{id}/stock-in` | Bearer | Add stock quantity | `{ "kg": 50 }` |
| `POST` | `/api/v1/shopkeeper/inventory/{id}/stock-out` | Bearer | Deduct stock quantity | `{ "kg": 20 }` |
| `PUT` | `/api/v1/shopkeeper/availability` | Bearer | Toggle mill open/close state | `{ "isOpen": true }` |
