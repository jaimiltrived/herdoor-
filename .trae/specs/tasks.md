# HerDoor Workflow — Implementation Task Queue

> **Spec Reference:** [spec.md](file:///d:/herdoor-/.trae/specs/spec.md)
> **Process Order:** T1 → T2 → T3 → T4 → T5 → T6 → T7 → T8 → T9 → T10 → T11 → T12 (dependencies encoded)
> **All tasks require dual-write: MySQL + in-memory store (`store.*`)**

---

## Legend
| Priority | Meaning |
|----------|---------|
| **high** | Blocks 7.1-7.4 core ACs; do first |
| **medium** | Needed for rubrics ≥ threshold score |
| **low** | Polish / UX / non-blocking enhancements |

| Status | Meaning |
|--------|---------|
| `pending` | Not started |
| `in_progress` | Currently working |
| `blocked` | Requires unblock condition |
| `completed` | All TRs self-verified with evidence |

---

## Task 1: Atomic Rider Claim Lock (Fix Double-Booking)
**Priority:** high
**Depends On:** (none — do first)
**Status:** pending

### Scope
Backend `deliveryController.acceptDelivery()` and `acceptGroupDelivery()` MUST use conditional UPDATE with row-affected check. Return HTTP 409 if rowsAffected=0.

### Files to Modify
- [deliveryController.js](file:///d:/herdoor-/src/controllers/deliveryController.js#L898-L964) — `acceptDelivery` function
- [deliveryController.js](file:///d:/herdoor-/src/controllers/deliveryController.js#L970-L1115) — `acceptGroupDelivery` function

### Implementation Notes
1. Replace `UPDATE deliveries SET status='ASSIGNED' WHERE order_id=?` with `UPDATE deliveries SET status='ASSIGNED', delivery_person_id=? WHERE order_id=? AND status IN ('CREATED','AVAILABLE') LIMIT 1`
2. Capture `result.affectedRows` (mysql2) or rows-changed count.
3. If affectedRows = 0 → `res.status(409).json({status:'error', code:'ALREADY_CLAIMED', message:'Another rider has already claimed this trip.'})`
4. Same pattern in `acceptGroupDelivery` for every target order ID.
5. Same pattern for `delivery_tasks` table: UPDATE leg1/leg2 with WHERE status='AVAILABLE'.

### Test Requirements (TR)
- **rule:** Concurrent POST 50× same order accept with 2 rider JWTs → `SELECT COUNT(DISTINCT delivery_person_id) FROM deliveries WHERE order_id=?` returns exactly 1.
- **rule:** Losing request returns HTTP 409 with code='ALREADY_CLAIMED'.

---

## Task 2: Rework Shopkeeper Intake Flow (Call scanPackage + fix statuses)
**Priority:** high
**Depends On:** T1
**Status:** pending

### Scope
`shopkeeperController.intakeGrainInspection()` MUST NOT skip QR scans and MUST NOT set order=READY directly. Must call `packageController.scanPackage` for each package with scanType=MILL_INTAKE. Then set order=PROCESSING if isAccepted=true, else REJECTED_AT_MILL. Also mark Leg 1 task=COMPLETED + create Leg 2 task in PENDING_DURING_MILLING state (not AVAILABLE yet).

### Files to Modify
- [shopkeeperController.js](file:///d:/herdoor-/src/controllers/shopkeeperController.js#L345-L429) — `intakeGrainInspection`
- [shopkeeperRoutes.js](file:///d:/herdoor-/src/routes/shopkeeperRoutes.js) — ensure route access (add mill-ownership check if missing)
- [enums.js](file:///d:/herdoor-/src/constants/enums.js) — add new DELIVERY_TASK status if needed: `PENDING_DURING_MILLING`

### Implementation Notes
1. Loop over bagDecisions or order package IDs → for each → `POST /packages/scan` internal call or direct call to `exports.scanPackage(req, res)` wrapper.
2. If any scan → code='INVALID_TRANSITION' → abort and rollback.
3. If `isAccepted=true`:
   - order.status = PROCESSING (not READY!)
   - Leg 1 delivery_task status = COMPLETED, completed_at=NOW()
   - INSERT or UPDATE Leg 2 task with status = PENDING_DURING_MILLING (hidden from riders until markReady)
   - delivery.order status = GRAIN_DROPPED (keep)
4. If `isAccepted=false`:
   - order.status = REJECTED_AT_MILL
   - Create RETURN LEG task for packages to go back to customer
5. Add mill ownership guard: `if (req.user.role === 'SHOPKEEPER' && order.millId !== req.user.millId) return 403`

### Test Requirements (TR)
- **rule:** `POST intake-inspection {isAccepted:true}` → order.status='PROCESSING', packages all status='RECEIVED_AT_MILL' or 'PROCESSING'.
- **rule:** package_scan_events table gets N rows for N packages where scan_type='MILL_INTAKE'.
- **rule:** delivery_tasks row WHERE leg=LEG_1 AND order_id=? → status='COMPLETED'.
- **rule:** delivery_tasks row WHERE leg=LEG_2 AND order_id=? → status='PENDING_DURING_MILLING'.

---

## Task 3: Restrict Customer getActiveOrders to Hide Milling Phase
**Priority:** high
**Depends On:** T2
**Status:** pending

### Scope
`orderController.getActiveOrders()` and `getOrders()` for CUSTOMER must EXCLUDE orders with status in PROCESSING, PACKING, READY, RECEIVED_AT_MILL from active list. (Show them only in tracking if user deep-links; hide from dashboard "Active Orders" carousel.)

### Files to Modify
- [orderController.js](file:///d:/herdoor-/src/controllers/orderController.js#L280-L323) — `getActiveOrders` SQL WHERE clause + memory filter
- [orderController.js](file:///d:/herdoor-/src/controllers/orderController.js#L205-L278) — `getOrders` default if user.role=CUSTOMER
- Flutter [dashboard_screen.dart](file:///d:/herdoor-/frontend/lib/screens/dashboard_screen.dart#L151-L167) — `isActive` status whitelist
- Flutter [orders_list_screen.dart](file:///d:/herdoor-/frontend/lib/screens/orders_list_screen.dart#L63-L76) — same isActive whitelist

### Implementation Notes
1. SQL WHERE for CUSTOMER active orders: `status IN ('PLACED','ACCEPTED','CONFIRMED','ASSIGNED','OUT_FOR_DELIVERY','RETURN_TO_CUSTOMER','REJECTED_AT_MILL')`
2. Explicitly exclude: PROCESSING, PACKING, READY, READY_FOR_PICKUP, READY_FOR_DELIVERY, RECEIVED_AT_MILL, PENDING_INSPECTION
3. Flutter: add message in orders list if all active are hidden → "🌾 You have X orders being milled — we'll notify you when a rider picks them up!" (count from separate endpoint or extra field)

### Test Requirements (TR)
- **rule:** `GET /orders/active` with customer JWT → data.orders has length=0 when order.status='PROCESSING'.
- **rule:** Same order later status='OUT_FOR_DELIVERY' → length=1 now.
- **rubric:** Customer "hidden milling" score. Evidence: OrdersPage JSON payload from test.

---

## Task 4: Secure confirmReceipt — CUSTOMER-Only + OTP Gate
**Priority:** high
**Depends On:** (independent)
**Status:** pending

### Scope
`orderController.confirmReceipt()` MUST check (a) role=CUSTOMER, (b) order.user_id==req.user.id, (c) optional OTP match with order.deliveryOtp. Currently this is callable by ANY authenticated role.

### Files to Modify
- [orderController.js](file:///d:/herdoor-/src/controllers/orderController.js#L568-L588) — `confirmReceipt`
- [orderRoutes.js](file:///d:/herdoor-/src/routes/orderRoutes.js#L26) — route-level role hint in comment / add authorizeRoles if needed (auth.js already has middleware)

### Implementation Notes
1. At top of confirmReceipt:
   ```
   if (req.user.role !== ROLES.CUSTOMER) return 403 'Only customers can confirm receipt'
   if (order.userId !== req.user.id) return 403 'This is not your order'
   ```
2. Add OTP body param: `{ deliveryOtp }`. If order.deliveryOtp set and provided otp !== order.deliveryOtp → 400 'Invalid delivery PIN'.
3. Only AFTER passing checks → order.status=COMPLETED + timeline row + payments finalize if needed.

### Test Requirements (TR)
- **rule:** CUSTOMER JWT + correct OTP → 200, status=COMPLETED.
- **rule:** DELIVERY JWT + same call → 403.
- **rule:** SHOPKEEPER JWT + same call → 403.
- **rule:** Customer JWT wrong OTP → 400 Invalid PIN.

---

## Task 5: Rewire markReady() to Activate Leg 2 Atomically
**Priority:** high
**Depends On:** T2 (for PENDING_DURING_MILLING state to exist)
**Status:** pending

### Scope
`shopkeeperController.markReady()` must change Leg 2 task from 'PENDING_DURING_MILLING' → 'AVAILABLE' atomically with READY status and package transitions. Single transaction.

### Files to Modify
- [shopkeeperController.js](file:///d:/herdoor-/src/controllers/shopkeeperController.js#L551-L613) — `markReady`

### Implementation Notes
1. Wrap in MySQL transaction (connection + beginTransaction + commit/rollback).
2. Steps in order:
   a. UPDATE orders status='READY' WHERE id=? AND status IN ('PACKING','PROCESSING') → check affectedRows
   b. UPDATE packages status='READY_FOR_DELIVERY', current_leg='LEG_2' WHERE order_id=?
   c. UPDATE delivery_tasks SET status='AVAILABLE' WHERE order_id=? AND leg='LEG_2_MILL_TO_CUSTOMER' AND status='PENDING_DURING_MILLING'
   d. timeline row
3. Rollback if any step fails; return 400.
4. Mirror to in-memory `store.*` only after commit success.

### Test Requirements (TR)
- **rule:** `POST /shopkeeper/orders/:id/ready` returns 200.
  - SELECT order.status → 'READY'
  - SELECT packages status → all 'READY_FOR_DELIVERY' and current_leg='LEG_2'
  - SELECT delivery_tasks WHERE leg=LEG_2 → status='AVAILABLE'
- **rule:** getAvailableTrips now shows Leg 2 entry for this order with badge "🍞 Flour Delivery".

---

## Task 6: Start Processing Guard (Pre-Intake Block)
**Priority:** medium
**Depends On:** T2
**Status:** pending

### Scope
`startProcessing()` and `startPacking()` must return HTTP 400 if order not yet RECEIVED_AT_MILL (i.e., intake not done). Currently no guard.

### Files to Modify
- [shopkeeperController.js](file:///d:/herdoor-/src/controllers/shopkeeperController.js#L471-L505) — `startProcessing`
- [shopkeeperController.js](file:///d:/herdoor-/src/controllers/shopkeeperController.js#L511-L545) — `startPacking`

### Implementation Notes
1. startProcessing valid states: `['RECEIVED_AT_MILL','CONFIRMED']`
2. startPacking valid states: `['PROCESSING']`
3. If in wrong state → `400 {code:'BAD_TRANSITION', message:'Cannot start processing until intake scan confirms grain has been received at mill.'}`

### Test Requirements (TR)
- **rule:** POST processing when order=ACCEPTED → 400 BAD_TRANSITION.
- **rule:** POST processing when order=RECEIVED_AT_MILL → 200, status='PROCESSING'.
- **rubric:** Workflow step order correctness score ≥ 2.

---

## Task 7: Rider Leg1 Pickup QR Scan + All-Scanned Trigger
**Priority:** medium
**Depends On:** T1
**Status:** pending

### Scope
Add endpoint or logic in scanPackage scanType=PICKUP so that when N/N packages are PICKED_UP_FROM_CUSTOMER for an order, it automatically sets delivery_task LEG_1 status='IN_TRANSIT' and order sub-status.

### Files to Modify
- [packageController.js](file:///d:/herdoor-/src/controllers/packageController.js#L8-L227) — `scanPackage` post-commit step
- [deliveryRoutes.js](file:///d:/herdoor-/src/routes/deliveryRoutes.js) — add new POST `/delivery/orders/:id/arrive-mill` route

### Implementation Notes
1. After scanPackage commit, if scanType=PICKUP and progress.isAllScanned:
   - UPDATE deliveries status='PICKED_UP_FROM_HOME' or 'IN_TRANSIT_TO_MILL'
   - UPDATE delivery_tasks leg1 → status='IN_TRANSIT'
2. Create POST `/delivery/orders/:id/arrive-mill` → sets delivery_tasks leg1='AT_MILL' + order.status='RECEIVED_AT_MILL' (pre-intake marker).

### Test Requirements (TR)
- **rule:** After N PICKUP scans → progress.isAllScanned=true, delivery_task leg1.status='IN_TRANSIT'.
- **rule:** POST arrive-mill → delivery_task.status='AT_MILL'.

---

## Task 8: Rider Leg2 Dispatch + Mill Handover Coordination
**Priority:** medium
**Depends On:** T5, T1
**Status:** pending

### Scope
After markReady → rider claims leg2 (T1 lock) → arrive at mill → shopkeeper handover triggers MILL_DISPATCH scans per package. When all scanned → OUT_FOR_DELIVERY.

### Files to Modify
- [shopkeeperController.js](file:///d:/herdoor-/src/controllers/shopkeeperController.js#L619-L668) — `handoverDelivery`
- [packageController.js](file:///d:/herdoor-/src/controllers/packageController.js#L119-L147) — MILL_DISPATCH branch

### Implementation Notes
1. In handoverDelivery: loop over packages → scanPackage(MILL_DISPATCH).
2. After all N dispatched → update order.status='OUT_FOR_DELIVERY'.
3. delivery.status='OUT_FOR_DELIVERY' + delivery_tasks leg2='IN_TRANSIT'.
4. PIN verification kept (pickupPin).

### Test Requirements (TR)
- **rule:** handover with valid PIN + scan all → OUT_FOR_DELIVERY, MILL_DISPATCH scan events N rows.

---

## Task 9: Flutter — Rider Delivery Dashboard Two-Leg Sections
**Priority:** medium
**Depends On:** Backend T1, T5 (data available)
**Status:** pending

### Scope
Flutter Rider screens show Leg1 (Grain Pickup) and Leg2 (Flour Delivery) as TWO distinct lists/tabs. Currently mixed.

### Files to Modify
- [delivery_dashboard_screen.dart](file:///d:/herdoor-/frontend/lib/screens/delivery/delivery_dashboard_screen.dart) — Add tabs: "Available Grain Pickups" / "Available Flour Deliveries" / "My Active Trips" / "History"
- [delivery_trip_sheet_screen.dart](file:///d:/herdoor-/frontend/lib/screens/delivery/delivery_trip_sheet_screen.dart) — Show clear leg badge + route A→B map header

### Implementation Notes
1. Split getAvailableTrips by legType in UI rendering.
2. Accept button per trip → on tap → POST accept → if 409 Conflict show SnackBar: "Oops, another rider claimed this trip first. Refresh queue."
3. Success → navigate to active_trip_screen immediately.

### Test Requirements (TR)
- **rubric:** Rider dashboard 2-leg separation. Evidence: screenshot or widget tree showing 2 sections with distinct labels.
- **rule:** Tap Accept twice rapidly with 2 rider accounts → 1 success 1 snackbar conflict.

---

## Task 10: Flutter — Rider Home Pickup QR Scan (Leg 1)
**Priority:** medium
**Depends On:** T7 (arrive-mill endpoint), T9
**Status:** pending

### Scope
In Rider Active Trip screen for Leg1: Show N package cards list + Scan QR button. Scan each (scanType=PICKUP). After all N scanned → "Proceed to Mill" CTA enabled.

### Files to Modify
- [active_trip_screen.dart](file:///d:/herdoor-/frontend/lib/screens/delivery/active_trip_screen.dart) — Add leg-aware UI branches
- [package_scanner_widget.dart](file:///d:/herdoor-/frontend/lib/widgets/package_scanner_widget.dart) — Ensure scanType param passed
- [delivery_api_service.dart](file:///d:/herdoor-/frontend/lib/services/delivery_api_service.dart) — Add scanPackage, arriveMill calls

### Implementation Notes
1. If trip leg=LEG_1_GRAIN_PICKUP → Show pickup address, "Scan N bags before leaving home"
2. QR scan call: POST packages/scan { qrToken, scanType:'PICKUP', lat, long }
3. After isAllScanned → show Success card + "Drive to Mill" button → calls arrive-mill when rider taps "I'm at mill"
4. If leg=LEG_2_FLOUR_DELIVERY → Show mill address, wait for shopkeeper handover flow.

### Test Requirements (TR)
- **rule:** Tap scan for each package → all N marked PICKED_UP_FROM_CUSTOMER.
- **rule:** "Drive to Mill" disabled until isAllScanned=true.

---

## Task 11: Flutter — Customer "I Got It" Confirm Receipt Popup
**Priority:** high
**Depends On:** T4 (backend secured endpoint), T8 (OUT_FOR_DELIVERY state reached)
**Status:** pending

### Scope
Order Tracking screen when status=OUT_FOR_DELIVERY and rider has marked "Arrived": show non-dismissible AlertDialog with:
- Title: "Confirm Delivery Received"
- Text: "Rider has arrived with your freshly ground flour. Please enter the 4-digit PIN shared with you by the rider."
- TextField: 4-digit OTP
- Checkbox: "I confirm I have received all bags and they are sealed correctly."
- Button: "✅ Confirm Receipt →" → calls POST /orders/:id/confirm-receipt { deliveryOtp }

### Files to Modify
- [order_tracking_screen.dart](file:///d:/herdoor-/frontend/lib/screens/order_tracking_screen.dart)
- [customer_api_service.dart](file:///d:/herdoor-/frontend/lib/services/customer_api_service.dart) — Add `confirmReceipt(orderId, otp)` method

### Implementation Notes
1. Check order status == 'OUT_FOR_DELIVERY' OR 'ARRIVED'.
2. If arrivedAt timestamp set → trigger showDialog on build (only once, state flag).
3. OTP TextField inputFormatters: FilteringTextInputFormatter.digitsOnly, length 4.
4. Checkbox must be checked before button enabled.
5. On success → SnackBar: "🎉 Delivery confirmed! Thank you for using HerDoor.", navigate to Orders History.

### Test Requirements (TR)
- **rubric:** Customer confirm popup score ≥ 2. Evidence: Widget inspector showing AlertDialog with TextField + Checkbox.
- **rule:** Call confirmReceipt wrong OTP → snackbar "Invalid PIN".
- **rule:** Call confirmReceipt correct OTP + checked → order.status=COMPLETED in API refresh.

---

## Task 12: Pagination + Rider isOnline Accept Guard
**Priority:** low
**Depends On:** (independent polish)
**Status:** pending

### Scope
- Add pagination everywhere it's missing: shopkeeper/dashboard, delivery/available-trips, delivery/assigned.
- Add isOnline guard in acceptDelivery: if rider isOnline=false → 400 "Go online first in Profile."

### Files to Modify
- [deliveryController.js](file:///d:/herdoor-/src/controllers/deliveryController.js#L898-L964) — isOnline check
- [shopkeeperController.js](file:///d:/herdoor-/src/controllers/shopkeeperController.js#L145-L180) — pagination params
- [deliveryController.js](file:///d:/herdoor-/src/controllers/deliveryController.js#L109-L282) — `getAvailableTrips` pagination

### Test Requirements (TR)
- **rule:** Rider isOnline=false → accept → 400.
- **rule:** ?page=1&perPage=3 on list endpoints → array length ≤3.

---

## Coverage Map — Acceptance Criteria → Tasks

| Spec AC | Implemented By Task(s) |
|---------|-------------------------|
| 7.1 Core state machine | T2, T5, T6, T7, T8 |
| 7.2 Atomic claim 409 tests | T1 |
| 7.3 Customer hidden milling | T3 |
| 7.4 Customer-only confirm receipt | T4, T11 |
| 7.5 QR scan audit trail per package | T2, T7, T8 |
| 7.6 Start processing before intake → 400 | T6 |
| 7.7 Rider 2-leg dashboard UI separation | T9 |
| 7.8 Customer OTP confirm popup | T11 |

---

## Queue Drain Order

```
T1 (claim lock) ──┐
T4 (confirm sec) ─┤
                  ├─▶ T2 (intake) ──▶ T3 (hide) ──▶ T5 (markReady) ──▶ T8 (handover)
                  │                     ▲                                    │
T6 (proc guard) ──┘                     │                                    ▼
                                        T7 (leg1 scan)                 T11 (customer popup)

T9 (rider dash) ──▶ T10 (rider qr scan)

T12 (polish/pag) — anytime after T1
```
