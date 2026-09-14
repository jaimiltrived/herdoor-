# HerDoor — 2-Leg Order Workflow Specification

> **Created:** 2026-09-14
> **Scope:** Backend API (`src/`), Flutter Mobile App (`frontend/`), React Admin SPA (`admin/`), MySQL Database (`database/`)
> **Target Users:** CUSTOMER (Citizen), SHOPKEEPER (Mill Owner), DELIVERY (Rider)

---

## 1. Problem Statement

The current implementation has partial 2-leg delivery support but **critical workflow gaps** prevent the end-to-end flow from functioning as the product owner intends. Specifically:

| Step | User's Intended Flow | Current Code State | Gap |
|------|---------------------|--------------------|-----|
| 1 | Customer places order | ✅ PLACED status + packages created with QR | OK (status initial value hardcoded PAID needs review) |
| 2 | Shopkeeper Accepts | ✅ ACCEPTED + Leg 1 task created | OK, but packages not linked to rider QR assignment UI |
| 3 | Rider sees Leg 1 & goes to Customer Home | ⚠️ Shown in `getAvailableTrips()` but NO rider-select lock | 🚨 Race condition: 2+ riders can ACCEPT same trip |
| 4 | Rider assigns QR to individual product at home | ❌ No UI — packages auto-generated at Order Create only | 🚨 Rider needs to VERIFY bags match QR at pickup time |
| 5 | Rider drops at Mill, Shopkeeper SCANS & Accepts/Rejects per-item | ⚠️ `scanPackage(MILL_INTAKE)` exists but `intakeGrainInspection()` bypasses QR, sets whole order to READY directly | 🚨 Massive semantic gap: intake should mark RECEIVED_AT_MILL → PROCESSING, not READY |
| 6 | After user accepts → End Leg 1, HIDE order from Customer during milling | ❌ `getActiveOrders()` shows PROCESSING to Customer, no "hidden" flag | 🚨 Customer sees stale order for hours while milling |
| 7 | Shopkeeper Starts Milling | ✅ PROCESSING status API exists | OK (but called before intake, which is wrong order) |
| 8 | Shopkeeper completes → Order opens for ALL riders (Leg 2 pool) | ⚠️ `markReady()` → READY status + Leg 2 AVAILABLE task created | 🚨 No atomic race-safe claim mechanism |
| 9 | Rider SELECTS → Another rider CANNOT select | ❌ `acceptDelivery()` has no row-lock or conditional update | 🚨 DANGER: Double-bookings, 2 riders show same trip as "theirs" |
| 10 | Rider picks up from Mill (scan confirm) | ⚠️ `scanPackage(MILL_DISPATCH)` exists, `markPickedUp()` in delivery API | Integration gap — both exist but don't coordinate |
| 11 | Rider drops to Home, Customer confirms "I got it" | ⚠️ `confirmReceipt()` endpoint exists but NO Flutter UI popup | 🚨 Customer cannot complete loop |

---

## 2. Users & Goals

### 2.1 User Roles (Existing ROLES enum reused)
| Role | Primary Goal | Daily Frequency |
|------|-------------|-----------------|
| **CUSTOMER** | Place grain grinding order → receive finished flour with zero confusion about milling "black box" | 1-3 orders/week |
| **SHOPKEEPER** | Receive grain → quality-check per-bag → mill → post to rider pool → handover | 20-50 orders/day |
| **DELIVERY (Rider)** | See open Leg trips → claim with lock → pickup → scan drop → get paid | 10-25 legs/day |

### 2.2 Non-Goals (Out of Scope for this Spec)
- Payment gateway integration (kept as-is, UPI/PAID mock for now)
- Real-time WebSocket push (keep polling pattern, add ETag/Last-Mod headers)
- New user registration flow
- Accounting, commission calculations, Admin portal UX fixes (separate spec)

---

## 3. Functional Requirements

### 3.1 End-to-End Canonical Workflow (THE 11 STEPS)

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  CUSTOMER    │───▶│ SHOPKEEPER   │───▶│ DELIVERY     │───▶│ SHOPKEEPER   │───▶│ SHOPKEEPER   │
│  Places      │    │  Accepts     │    │  Leg1: Picks │    │  Intake      │    │  Start &     │
│  Order       │    │  Order       │    │  Up Grain    │    │  Scan+Accept │    │  Complete    │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       ▼                   ▼                   ▼                   ▼                   ▼
   [PLACED]           [ACCEPTED]          [ASSIGNED]         [RECEIVED_AT        [PROCESSING →
                      + LEG1 AVBL          + LEG1 PICKED     _MILL →             READY_FOR_
                                          UP_FROM_HOME       PROCESSING]          DISPATCH]
                                                                                       │
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  CUSTOMER    │◀───│  DELIVERY    │◀───│ DELIVERY     │◀───│ DELIVERY     │◀───│  ALL RIDERS  │
│  "I got it!" │    │ Completes    │    │ Rider Picks  │    │ Rider CLAIMS │    │  SEE Leg 2   │
│  Confirm ✅   │    │ Delivery     │    │ Up from Mill │    │ (LOCK 1st)   │    │  in Pool     │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
       ▲                   ▲                   ▲                   ▲                   ▲
 [COMPLETED ✓]       [OUT_FOR_          [PICKED_UP_       [ASSIGNED ←          [READY + LEG2
                    DELIVERY +          FROM_MILL]         CLAIM ROW LOCK]       AVAILABLE TASK
                    DELIVERED]
```

### 3.2 Leg 1 Deep Dive — Customer Home → Mill (Rider picks RAW grain)
| # | Actor | Action | Order Status | Delivery Task Status | Package Status | AC: rule |
|---|-------|--------|--------------|---------------------|----------------|----------|
| L1.1 | System | `POST /orders` → Order + packages created | `PLACED` | N/A | `CREATED` | rule: Every order with grainSource=CUSTOMER MUST create N=items packages with unique qr_token in DB. Evidence: MySQL packages table rows ≥1 for order. |
| L1.2 | Shopkeeper | `POST /shopkeeper/orders/:id/accept` | `ACCEPTED` | LEG_1 = `AVAILABLE` | `READY_FOR_PICKUP` | rule: acceptOrder MUST atomically INSERT/UPDATE delivery_tasks leg=LEG1 status=AVAILABLE and packages status=READY_FOR_PICKUP. Evidence: both rows changed in same transaction. |
| L1.3 | Rider A | Tap "Accept Trip" on Leg 1 (Leg1Claim) | `ASSIGNED` | LEG_1 = `ASSIGNED` + rider_id locked | — | **rule: Atomic Claim with row-lock**: acceptDelivery MUST do `UPDATE delivery_tasks SET status='ASSIGNED', delivery_person_id=? WHERE leg=LEG1 AND status='AVAILABLE' AND id=? LIMIT 1` AND return ROWS_AFFECTED. If rowsAffected=0 → HTTP 409 "Already claimed". Evidence: concurrent 2 POSTs → exactly one returns 200. |
| L1.4 | Rider | At Customer Home → Scan each package QR (type=PICKUP) | `ASSIGNED` | `IN_TRANSIT` | `PICKED_UP_FROM_CUSTOMER` | rule: scanPackage(scanType=PICKUP) must advance package to PICKED_UP_FROM_CUSTOMER. After ALL N packages PICKED_UP → automatically mark order.status = EN_ROUTE_TO_MILL (new) or transition delivery_task. Evidence: POST scan returns isAllScanned=true + nextAction=GO_TO_MILL. |
| L1.5 | Rider | Tap "Arrived at Mill" + Shopkeeper confirms | `RECEIVED_AT_MILL` (new explicit) | `AT_MILL` | — | rule: delivery task leg1 transitions AT_MILL only after Rider confirms arrival. Evidence: new POST route `/delivery/orders/:id/arrive-mill` sets status AT_MILL. |
| L1.6 | Shopkeeper | QR Scan MILL_INTAKE per bag → **Accept / Reject each** (bagDecisions) | `PROCESSING` (if all acc) OR `REJECTED_AT_MILL` (partial w/ note) | LEG_1 = `COMPLETED` | `RECEIVED_AT_MILL` (acc) / `REJECTED` (rej) | **rule: intakeGrainInspection MUST call scanPackage(MILL_INTAKE) internally per package BEFORE advancing order status.** After scan, if isAccepted=true → order=PROCESSING, leg1 task=COMPLETED, CREATE leg2 task=PENDING_DURING_MILLING (hidden from riders). If isAccepted=false → order=REJECTED_AT_MILL, create RETURN_LEG delivery task. Evidence: MySQL package_scan_events rows for each package with scan_type=MILL_INTAKE. |
| L1.7 | System (after intake Accept) | Hide order from Customer UI during milling | — | — | — | **rule: Customer getActiveOrders() MUST exclude orders WHERE status IN ('PROCESSING','PACKING','READY','RECEIVED_AT_MILL').** Customer should see 0 active orders until OUT_FOR_DELIVERY. Evidence: GET /orders/active for user returns 0 when order status=PROCESSING. |

### 3.3 Milling Phase (Shopkeeper actions)
| # | Actor | Action | Order Status | AC: rule |
|---|-------|--------|--------------|----------|
| M.1 | Shopkeeper | `POST /shopkeeper/orders/:id/start` (Start grinding) | `PROCESSING` → stays `PROCESSING` | rule: startProcessing is idempotent; can only be called AFTER intake (RECEIVED_AT_MILL state already transitioned). If intake not done → 400. |
| M.2 | Shopkeeper | `POST /shopkeeper/orders/:id/packing` | `PACKING` | rule: startPacking only allowed from PROCESSING. |
| M.3 | Shopkeeper | `POST /shopkeeper/orders/:id/ready` (Complete + open Leg 2) | `READY` | **rule: markReady MUST atomically:** (a) order.status=READY, (b) delivery_tasks leg2 UPDATE status=AVAILABLE (from PENDING_DURING_MILLING), (c) packages UPDATE status=READY_FOR_DELIVERY, current_leg=LEG_2. Evidence: 3 tables transitioned in single DB transaction. |

### 3.4 Leg 2 Deep Dive — Mill → Customer Home (Rider delivers MILLED flour)
| # | Actor | Action | Order Status | Delivery Leg 2 Status | AC: rule |
|---|-------|--------|--------------|----------------------|----------|
| L2.1 | System (after markReady) | Publish to rider pool | `READY` | `AVAILABLE` | rule: getAvailableTrips() MUST include READY orders with leg2 AVAILABLE. Evidence: response shows tripBadge="🍞 Flour Delivery". |
| L2.2 | Rider B (any) | Claim Leg 2 → **EXCLUSIVE LOCK** | `ASSIGNED` (or sub-status) | `ASSIGNED` | **rule: EXACT same atomic row-lock pattern as L1.3.** 2 concurrent acceptDelivery → one 200, one 409. Additionally, delivery_person_id in deliveries table SET to claimant. |
| L2.3 | Rider | Tap "Arrived at Mill" → Shopkeeper does handover | — | `AT_MILL` | rule: handoverDelivery (shopkeeper) only works AFTER rider arrival marker. |
| L2.4 | Shopkeeper + Rider | Handover QR scan (MILL_DISPATCH per package) | `OUT_FOR_DELIVERY` | `IN_TRANSIT` → after all scanned | rule: scanPackage(MILL_DISPATCH) per package → when all done → order.status=OUT_FOR_DELIVERY. Evidence: isAllScanned=true, nextAction=DELIVER_TO_HOME. |
| L2.5 | Rider | Tap "Arrived at Customer" + Customer gets push | `OUT_FOR_DELIVERY` | `ARRIVED` (new) | rule: Customer order tracking shows "Rider at your door" banner. Evidence: new GET /orders/:id/tracking includes arrivedAt timestamp. |
| L2.6 | **CUSTOMER** | Tap "✅ I got that" (Confirm Receipt POPUP) | `COMPLETED` | `DELIVERED` | **rule: confirmReceipt endpoint MUST be callable by CUSTOMER role, not just delivery/shopkeeper.** Must be the ONLY way to reach status COMPLETED (not by rider). Evidence: JWT with role=CUSTOMER POST /orders/:id/confirm-receipt → 200, order.status=COMPLETED. Rider attempting same call → 403. |
| L2.7 | System | Mark payment finalized + add to rider earnings | `COMPLETED` (paid) | `DELIVERED` | rule: After COMPLETED, payment_status=PAID (if not already), and rider total_trips increments. Evidence: users.total_trips column +1 for that delivery_person_id. |

---

## 4. Non-Functional Requirements

### 4.1 Race Conditions (TOP PRIORITY — data-correctness)
- **rule:** ALL "claim trip" acceptDelivery() and acceptGroupDelivery() MUST use conditional UPDATE with WHERE status='AVAILABLE'. Return affected-rows count. If 0 → 409 Conflict.
- **rule:** ALL scanPackage() use SELECT ... FOR UPDATE on packages row + transaction. (Already partially done, keep & extend.)
- **rubric:** Concurrent-claim resilience (0-2): `2` = 100% of 100 concurrent parallel acceptDelivery POSTs yield exactly 1 assignment, 99 409s. `1` = only 90% correct, occasional double-assign detected. `0` = frequent double-bookings observed. **Threshold: ≥2.**

### 4.2 Order Visibility (Customer experience)
- **rule:** Customer /orders/active returns orders ONLY where status ∈ {PLACED, ACCEPTED, ASSIGNED, OUT_FOR_DELIVERY, RETURN_TO_CUSTOMER}.
- **rule:** Customer /orders/history returns COMPLETED, DELIVERED, CANCELLED, REJECTED, REJECTED_AT_MILL, RETURNED_TO_CUSTOMER.
- **rubric:** Customer "hidden milling" clarity (0-2): `2` = 0 PROCESSING orders leak into active list + tracking page explicitly shows "🌾 Being ground at mill — we'll notify you when driver picks it up". `1` = hidden but no message. `0` = PROCESSING leaks to active, customer confused why ETA frozen. **Threshold: ≥2.**

### 4.3 Data Integrity & Auditability
- **rule:** Every state transition MUST create order_timeline row with title+description.
- **rule:** Every QR scan MUST create package_scan_events row (already partially done; extend to make scans from intakeGrainInspection go through this path, not bypass).
- **rule:** packages table → actual_weight column populated by shopkeeper at MILL_INTAKE accept time.

### 4.4 Performance
- **rule:** All list endpoints (available-trips, orders/active, shopkeeper/dashboard) support `?page=1&perPage=20` query params and return pagination metadata. (Partially done in getOrders only; enforce everywhere.)
- **rubric:** Cold rider dashboard load < 1.5s on 4G (0-2): `2` = list ≤ 20 items, ≤ 2 SQL queries, ETag headers returned. `1` = ≤ 3s. `0` = >5s. **Threshold: ≥1.**

### 4.5 Security & RBAC
- **rule:** `POST /orders/:id/confirm-receipt` requires role=CUSTOMER AND order.user_id == req.user.id. (Currently open to anyone.)
- **rule:** `POST /delivery/orders/:id/accept` requires role=DELIVERY AND rider isOnline=true.
- **rule:** scanPackage(MILL_INTAKE) only SHOPKEEPER + that mill's owner_user_id == req.user.id. (Already in packageController; extend shopkeeperController.intakeGrainInspection to add same check.)
- **rule:** acceptDelivery / rejectOrder for shopkeeper scoped to their own millId only (not header/query override in production - fix getShopkeeperMillId fallback).

---

## 5. Constraints, Dependencies, Assumptions

### 5.1 Hard Constraints
1. **No breaking API removal.** All existing routes keep working; new routes added or behavior augmented.
2. **MySQL + in-memory datastore dual-write pattern preserved.** Any SQL UPDATE mirrored to `store.*` arrays in the same request cycle (existing pattern).
3. **Packages table is the source of truth for QR state.** All intake/handover goes through packages row status + package_scan_events log.
4. **Role-based auth JWT middleware (auth.js) kept unchanged.**

### 5.2 Dependencies
- Depends on: `frontend/pubspec.yaml` has mobile_scanner or qr_code_scanner — if missing, add for rider QR scanning UI. (TBD during implementation; check existing `widgets/package_scanner_widget.dart`.)
- Depends on: `confirmReceipt` being restricted from Rider + Shopkeeper → UI adjustments in delivery/active_trip_screen.dart to remove "Mark delivered" button, replaced with "Waiting for customer confirmation".

### 5.3 Assumptions
- Customer order placement is single-order-single-customer; grouped runs are rider-side multi-stop pools (not customer batching).
- "Assign QR to individual product" at Rider home pickup = VERIFY + SCAN existing QR (already created at order time). NOT generating new QR codes by rider. (If user meant generating, we need separate spec for rider-generated stickers.)
- Reject at mill = return leg rider assignment follows same claim pattern.
- Customer confirm receipt popup is in Flutter: AlertDialog or bottom sheet with "Confirm you received all bags" checkbox.

---

## 6. Open Questions (Must resolve before full Implement)

| Q# | Question to User | Current Assumption | Impact if Wrong |
|----|-----------------|--------------------|------------------|
| OQ-1 | In step 4, "rider assign QR to individual product" — does rider physically stick QR stickers at home (print offline) OR is it verifying pre-generated QR by scanning? | Assumed: SCAN-ONLY (QR created at order create time). If sticker creation needed → new API + hardware dependency. | Wrong → need to build rider QR printer UI & regenerate QR endpoint. |
| OQ-2 | Step 6 "hide order from user during milling" — should tracking page say "Milling in progress (ETA 3h)" or completely remove from list? | Assumed: hide from active dashboard list; tracking page if user deep-links shows "🌾 Being ground — notification when ready". | Wrong → customer anxious "where is my order". |
| OQ-3 | Step 9 rider selection lock — what if rider goes offline after claiming? Auto-release timeout? | Assumed: NO auto-release in v1. Admin can unassign. | Wrong → dead orders stuck ASSIGNED forever. |
| OQ-4 | Step 11 "I got that" popup — do you want 4-digit delivery OTP entry first? | Assumed: Yes, delivery OTP (7391 currently hardcoded) entered by Customer in popup to prove it was them. | Wrong → security hole if anyone with phone can "confirm" for neighbor. |
| OQ-5 | Shopkeeper intake accept/reject per-bag: if 3 bags, 2 accepted 1 rejected — partial refund? Return that bag to customer in Leg 2? | Assumed: Whole order accepted OR whole order rejected. Per-bag tracked but no partial Leg 2 split. | Wrong → partial return flow, refund math, paymentController extension. |

---

## 7. Acceptance Criteria (rule / rubric only)

### 7.1 Core State Machine Coverage (rule)
- [ ] rule: Order can traverse PLACED→ACCEPTED→RECEIVED_AT_MILL→PROCESSING→PACKING→READY→OUT_FOR_DELIVERY→COMPLETED with valid JWT auth.
- [ ] rule: Order can traverse reject paths: PLACED→ACCEPTED→REJECTED_AT_MILL→RETURN_TO_CUSTOMER→RETURNED_TO_CUSTOMER.
- [ ] rule: Every state transition creates ≥1 order_timeline row.

### 7.2 Atomic Rider Claim (rule)
- [ ] rule: Concurrently POST `/delivery/orders/:id/accept` 100 times in parallel with 2 different rider JWTs. DB query shows exactly 1 delivery_person_id set, others return HTTP 409.

### 7.3 Customer Hidden Milling Phase (rule)
- [ ] rule: `GET /orders/active` for CUSTOMER returns 0 orders when order.status=PROCESSING.
- [ ] rule: Same order when status=OUT_FOR_DELIVERY reappears in customer active list.

### 7.4 Customer-Led Final Confirmation (rule)
- [ ] rule: CUSTOMER JWT calls `/orders/:id/confirm-receipt` → order.status=COMPLETED, 200.
- [ ] rule: DELIVERY JWT calls same endpoint → 403 Forbidden.
- [ ] rule: SHOPKEEPER JWT calls same endpoint → 403 Forbidden.

### 7.5 QR Scan Auditability (rule)
- [ ] rule: After intakeGrainInspection(isAccepted=true), package_scan_events contains N rows WHERE scan_type='MILL_INTAKE' for all N packages of order.
- [ ] rule: After handover, package_scan_events has N rows scan_type='MILL_DISPATCH'.

### 7.6 Intake → Processing Order (rubric)
- rubric: Workflow step order correctness (0-2): `2` = Shopkeeper cannot start processing button until intake scan done (API returns 400 if status not RECEIVED_AT_MILL). `1` = button shown but click shows warning toast. `0` = startProcessing callable before intake, state-machine scrambled. **Threshold: ≥2.**

### 7.7 Flutter Rider UI Availability (rubric)
- rubric: Rider dashboard shows 2 distinct sections "🌾 Grain Pickup (Home → Mill)" and "🍞 Flour Delivery (Mill → Home)" separately with status badges (0-2): `2` = separate tabs/cards + explicit Leg labels; `1` = mixed list with badges; `0` = single list no leg distinction. **Threshold: ≥1.**

### 7.8 Flutter Customer Confirm Popup (rubric)
- rubric: When order status=OUT_FOR_DELIVERY and arrivedAt set, order tracking screen shows interruptive confirmation card with OTP entry + "I received all packages" checkbox (0-2): `2` = interruptive modal with OTP gate; `1` = inline button + checkbox; `0` = no UI, auto-completed by rider. **Threshold: ≥2.**

---

*End of Specification. Approval needed before creating tasks.md implementation queue.*
