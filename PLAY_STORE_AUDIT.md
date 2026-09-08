# HerDoor — Google Play Store Submission Bug Audit

> Scope: Flutter Android app (`frontend/`) + backend (`src/`) + database
> Priority: **Ordered by Play Rejection likelihood first**, then Crash Rate (Android Vitals), then Security/Privacy policy, then UX

---

## ⚠️ Play Store Submission Readiness Summary

| Metric | Status |
|--------|:------:|
| **App will BUILD?** | ❌ **NO** — Dart syntax error blocks compilation |
| **Release APK/AAB signable for Play?** | ❌ **NO** — signed with DEBUG key (auto-rejection) |
| **Release runtime will CRASH?** | ❌ **YES** — missing INTERNET permission in main manifest |
| **Network calls work on real Android?** | ❌ **NO** — Cleartext HTTP blocked (Android 9+), no NS config |
| **Play Protect / Static security scan PASS?** | ❌ **NO** — hardcoded OTP + master passwords embedded |
| **Data Safety form can be filled honestly?** | ⚠️ WARNING — no privacy policy URL, no data retention disclosure |
| **Android Vitals crash-free estimate** | 🔴 **POOR** — < 70% session stability projected |

**Overall verdict: APP WILL BE REJECTED IN CURRENT STATE. Fix the top 6 blockers first before generating AAB.**

---

## 1. CONFIRMED BUGS (ordered by Play Store rejection priority)

### 🚫 TIER 0 — WILL 100% CAUSE REJECTION (Fix IMMEDIATELY before uploading AAB)

| ID | Severity | Category | File | Location | Bug | Play Store Rule Violated | How to Reproduce | Fix |
|----|----------|----------|------|----------|-----|--------------------------|------------------|-----|
| PLAY-001 | 🔴 CRITICAL | Build/Compile | `frontend/lib/services/auth_api_service.dart` | L277-L280 | **Invalid Dart syntax** inside `jsonEncode()`: `'name': ?name`, `'phone': ?phone`, `'email': ?email`, `'profileImage': ?profileImage`. In Dart, the conditional-null `?var` is not valid as a Map literal value; correct is `if (name != null) 'name': name`. Code does **NOT COMPILE** at all. | **Cannot generate APK/AAB** → cannot submit | Run `cd frontend && flutter build appbundle` → Dart compilation error in `auth_api_service.dart:277` | Replace the whole JSON body with: `{ if (name != null) 'name': name, if (phone != null) 'phone': phone, if (email != null) 'email': email, if (profileImage != null) 'profileImage': profileImage }` |
| PLAY-002 | 🔴 CRITICAL | App Signing | `frontend/android/app/build.gradle.kts` | L34-L38 | **Release build signed with DEBUG keystore**: `signingConfig = signingConfigs.getByName("debug")` in the `release` buildType. | **Play Console Policy**: "You uploaded an APK or Android App Bundle that was signed in debug mode. You need to sign your APK or Android App Bundle in release mode." (Automatic rejection with no human review) | Build a release AAB and upload to Play Console → instant rejection message on Upload page | Generate/upload Play App Signing key via Play Console → App signing, then create `signingConfigs.release` with keystore reference in `build.gradle.kts`, then: `signingConfig = signingConfigs.release` |
| PLAY-003 | 🔴 CRITICAL | Permissions | `frontend/android/app/src/main/AndroidManifest.xml` | L1-45 (entire file) | **Missing `INTERNET` permission in `main/AndroidManifest.xml`**. INTERNET is only present in `debug/` and `profile/` manifests — release build will not inherit. | Runtime crash on first network call → **Android Vitals** crash rate > 1% triggers automatic removal. Also Play reviewer opens the app → crash on login → manual rejection. | Install release build on real device, tap Login or any network action → crash, `SecurityException: Permission denied (missing INTERNET permission?)` in logcat. | Add `<uses-permission android:name="android.permission.INTERNET"/>` as child of `<manifest>` in **main** `AndroidManifest.xml` |
| PLAY-004 | 🔴 CRITICAL | Network Cleartext | All Flutter API services | `auth_api_service.dart` L12-15, `customer_api_service.dart` L15-18, `merchant_api_service.dart` L14-17 | **All services use `http://` (cleartext)** URLs: `10.0.2.2` and `localhost:5000`. Android 9+ (API 28) blocks cleartext HTTP by default. No `network_security_config.xml` exists. | Release build → ALL backend calls fail silently with `SocketException: Connection reset by peer` (or cleartext blocked). App appears broken, 100% login failure. Reviewer can't progress past login. | Run release APK on Android 9+, attempt login → spinner forever, then failure snackbar with "Unable to connect" (cached in offline). Also `flutter run --release` on physical device. | **Short term**: Create `frontend/android/app/src/main/res/xml/network_security_config.xml` allowing cleartext to specific host. **Long term (recommended for production)**: Deploy backend over HTTPS and use `https://` URLs only. |
| PLAY-005 | 🔴 CRITICAL | Security Static | `frontend/lib/services/auth_api_service.dart` L149-153, L179-181, L206-207, L236-239 + `backend authController.js` (BUG-002) | **Master OTP `123456` and `1234` baked into production Flutter app source code** (catch paths of `forgotPassword`, `verifyOtp`, `resendOtp`, `resetPassword` all return success=true offline). Same literal mirrored in backend. | Google Play Protect and **Play App Signing security review** flags "Backdoor / hardcoded credential in production code" = **MANUAL REMOVAL, possible strike against developer account** | Static scan of AAB by Google Play: finds strings "123456", "1234" in offline auth paths; or dynamic test: enable airplane mode, request forgot password → "OTP sent", enter 123456 → "Password reset successful" | **Delete every offline success branch**. If API call fails in release: return `success: false` only, never show valid OTP values in messages either. |
| PLAY-006 | 🔴 CRITICAL | Security Static / Data Safety | `frontend/lib/services/customer_api_service.dart` L37-45 and `frontend/lib/services/merchant_api_service.dart` L53-63 | **Hardcoded user credentials embedded in release app**: `ensureAuthenticated()` auto-signs-in as `ramesh@example.com : Password123!` (customer) or `shop@shreeganesh.com : Password123!` (merchant) when no token exists. | Play Data Safety violation (undisclosed automatic authentication + credential disclosure) + "Potentially harmful behavior" classification. Also any user opens app offline → becomes logged in as a random user, data leak. | Enable airplane mode, open app fresh → app silently logs in as `ramesh@example.com` → shows order history and profile data of Ramesh Patel (user #1) to **anyone who installs app**. | **Delete `ensureAuthenticated()` entirely.** If token missing, send user to Login screen, never auto-login. |

---

### 🚨 TIER 1 — VERY HIGH LIKELIHOOD OF REJECTION (Fix before Play upload after Tier 0)

| ID | Severity | Category | File | Location | Bug | Play Store Rule Violated | How to Reproduce | Fix |
|----|----------|----------|------|----------|-----|--------------------------|------------------|-----|
| PLAY-007 | 🟠 HIGH | Data Safety / Privacy | `frontend/` + backend | Multiple | **No Privacy Policy URL provided anywhere** and app clearly collects: email, phone, name, address, GPS location, payment methods. | **Play Console Data Safety policy**: Starting August 2024, ALL apps (even <10 downloads) must display a Privacy Policy URL in: (A) Play Console listing, AND (B) app Settings/About section accessible offline. | Play Console "App content" → Data Safety → unable to complete because no hosted privacy policy exists; or reviewer taps Settings in-app → no privacy link → manual rejection. | Host a real Privacy Policy page at your website HTTPS URL. Add a button in app settings page linking to it, fill Play Console Data Safety form honestly. |
| PLAY-008 | 🟠 HIGH | Payments Policy | `frontend/lib/screens/payment_methods_screen.dart` L52-64 + `paymentController.js` L1-89 | **Payment UI lists Apple Pay as payment option on Android** (hardcoded mock list). Also no Google Play Billing Library / Google Pay in-app purchases integration. Payments marked as UPI/Card/Apple Pay handled by backend dummy endpoint only. | **Google Play Payments Policy**: (1) Cannot promote Apple Pay on Android platform. (2) If the app accepts payments for physical goods/services, Play allows external payment gateways (Razorpay, UPI, Stripe) BUT you must still declare them accurately in Data Safety form and actually integrate them (not just mock UI). | Play reviewer taps Checkout → Payment methods → sees "Apple Pay" option in Android app → screenshot evidence → "Misleading UX" rejection. Also no real payment integration = app is a demo. | **Remove Apple Pay card entry from Android payment methods list** (it can remain in iOS builds only via Platform.isIOS). Integrate actual Android-compatible gateway (Google Pay / Razorpay / PhonePe UPI). |
| PLAY-009 | 🟠 HIGH | Session Persistence / UX Crash | `frontend/lib/services/auth_api_service.dart` L19-28 + entire lib directory | **`flutter_secure_storage` declared in `pubspec.yaml` but never imported/used**. Auth token `_token` is stored ONLY in in-memory static variable `AuthApiService._token` — it's lost every time the app is closed/restarted. Also no SharedPreferences storage. | Not a policy ban, but causes **100% of users logged out on cold app start** → massive uninstalls, poor rating, low engagement, and triggers **Android Vitals "Stuck on login screen" behavior warning.** Reviewer may also fail functionality testing. | Login to app → swipe-app-from-recents (kill it) → re-launch → splash screen then user is on Login screen again (must re-login every cold start). | Use `flutter_secure_storage` already in pubspec: `await storage.write(key:'jwt_token', value: token)` at login success; `read` it at app init in `main.dart` / splash; set `_token` before `runApp` to restore session. |
| PLAY-010 | 🟠 HIGH | Permissions Declared vs Used | `frontend/android/app/src/main/AndroidManifest.xml` (no ACCESS_FINE_LOCATION) + `lib/screens/mill_map_screen.dart` / `lib/screens/dashboard_screen.dart` | **App has map/location features** (mill map, nearby mills, pickup/drop addresses) — but no `ACCESS_FINE_LOCATION` or `ACCESS_COARSE_LOCATION` permissions declared in main manifest, and no `permission_handler` in `pubspec.yaml` either. | User opens map screen → app cannot get GPS position → displays mock coordinates only (Ahmedabad 23.0225, 72.5714 hardcoded defaults from customer_api_service.dart L60-61). Feature appears broken to reviewer. | Open Mill Map screen → permissions dialog never appears; map always shows default city instead of user's real location. | Add `<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />` to main AndroidManifest. Add `permission_handler` pub dep. Request permission from user BEFORE map screen renders. |
| PLAY-011 | 🟠 HIGH | Security / Backdoor in OTP Reset Flow | `frontend/lib/screens/auth/forgot_password_screen.dart` L15, L43, L77, L105 | **Multiple security issues in forgot password UI**: (L15) `_emailController = TextEditingController(text: 'ramesh@example.com')` — pre-populates target email with existing user info; (L43, L77) UI snackbars expose "Use 1234 or 123456" as working codes in toast messages when OTP fails; (L105) If OTP input empty, defaults to `'123456'` before sending. | Play Protect static scan finds these strings; reviewer can also follow the UI hints and successfully reset any account → trivially demonstrated account takeover → severe security violation ban. | Open app → "Forgot Password?" → email field already says `ramesh@example.com` → tap Send OTP (no internet) → toast says "OTP sent (Code: 123456)". Enter 123456, submit new password → "Password reset successful". | (1) Never pre-fill email/phone in forgot password form. (2) Remove all snackbar text that suggests valid OTP codes. (3) Never substitute empty OTP with a hardcoded value. |
| PLAY-012 | 🟠 HIGH | Content Review / Pre-filled Demo Data | `frontend/lib/screens/auth/login_screen.dart` / `forgot_password` / `register` and multiple `TextEditingController(text: ...)` with live user data | Login and Forgot Password screens default text fields to `'ramesh@example.com'`, `'shop@shreeganesh.com'`, `'+91 98765 43210'`, etc. that correspond to real seeded users in backend. | Misleading for end users, and exposes the personal-looking contact info of demo users to anyone who installs the app. Also reviewers consider this "Content that is not functional or contains placeholder data" warning. | Install app fresh → tap Sign In → login ID is pre-filled with `ramesh@example.com` / password field pre-filled with demo password (if implemented there). | Set ALL TextEditingController initial values to `''` empty in production. |

---

### ⚠️ TIER 2 — MEDIUM RISK (Fix after T0 + T1, cause crashes / policy strikes in edge cases)

| ID | Severity | Category | File | Location | Bug | Play Store Rule Violated | How to Reproduce | Fix |
|----|----------|----------|------|----------|-----|--------------------------|------------------|-----|
| PLAY-013 | 🟡 MEDIUM | Crash / Android Vitals | `frontend/lib/screens/location_selection_screen.dart` L113-119 | `ElevatedButton` onPressed calls `Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()))` with **no cart items, no total amount, no mill data** — PaymentMethods screen renders with defaults (0.00 total, millId=101 hardcoded). Also Checkout→Payment data not passed. | User places order successfully but Payment screen opens blank (total=$0.00), confusion → app considered buggy. Vitals crash if map/Address IDs don't match. | Go through flow: Select Grain → Location Screen → Proceed to Payment → PaymentMethods screen shows **Grand Total: $0.00** and millId defaults to Shree Ganesh even if user picked Navrang Mill (L37-40 `effectiveMillId` only matches name string). | Pass arguments through Navigator in constructor (or use a state manager like Provider/Riverpod). Don't depend on `effectiveMillId` string contains logic. |
| PLAY-014 | 🟡 MEDIUM | UX / Data Integrity | `frontend/lib/services/customer_api_service.dart` L165-169 | `placeOrder` defaults: `addressId: 25` hardcoded (integer ID may not exist for the user) + `deliveryAddress: '456 Heritage Block, District 9, NY'` hardcoded regardless of user selected address. | New orders always get delivered to "District 9 NY" regardless of what user picks in checkout UI. Reviewers notice and flag as: "Feature works incorrectly". | Pick address "Work: 123 Tech Park" in Checkout → submit order → call `/orders/{id}` details → deliveryAddress field still says NY. | Use the `widget.address` / `_selectedAddress` from CheckoutScreen instead of hardcoded strings. Also fetch real user addressId from `/addresses` endpoint first. |
| PLAY-015 | 🟡 MEDIUM | Null Safety / Crashes | `frontend/lib/services/auth_api_service.dart` L55, L104 | `final data = jsonDecode(response.body);` on **EVERY** API call with zero null/format error handling. If backend returns 500 / HTML error / empty body (e.g. during maintenance), cast to `Map<String, dynamic>` fails, throws `FormatException`, causes crash-to-home screen. | **Android Vitals "Excessive crashes" > 1.09% threshold** triggers auto-removal from Play. | Stop backend server (or change base URL to wrong port) → tap Login → app crashes instead of showing "Server unavailable" | Wrap EVERY `jsonDecode(response.body)` in try/catch; check `response.statusCode` before attempting parse; return `{success:false, message:"Server error"}` gracefully. |
| PLAY-016 | 🟡 MEDIUM | Backend Security (affects Data Safety claims) | Root README BUG-001 through BUG-032 entire backend issues | Backend has already-audited 32 bugs including: shopkeepers=admins, JWT secret hardcoded fallback, register allows ADMIN role, reset-password accepts master OTP. | If a security researcher or bot finds these, they can exfiltrate user data → **Play User Data policy violation** → forced suspension + 24-hour notice to fix. | Already documented in root README audit. | Fix all backend CRITICAL bugs (BUG-001, 002, 003, 004, 007, 008, 009, 010, 011, 024) before going live — they are not just code issues, they are mandatory Play Store security baseline. |
| PLAY-017 | 🟡 MEDIUM | Android 14 / Target SDK ≥ 34 | `frontend/android/app/build.gradle.kts` L22-L31 + MainActivity L6-14 | `targetSdk = flutter.targetSdkVersion` (defaults to 34+ starting Flutter 3.22). Starting Android 14 (API 34): (1) `exported=true` components without specific intent-filter action for Launcher — currently OK for MainActivity but (2) **Foreground Service requirements** for location updates, (3) Runtime permission `POST_NOTIFICATIONS` required. Notifications screen exists but no permission request logic. | User opens notifications screen with targetSdk=34 → Android 14+ silently drops all local notifications, feature broken. Reviewer tests and notes. | On Android 14 device, open app → trigger a notification (new order accepted) → no system notification appears because POST_NOTIFICATIONS permission missing. | Add `POST_NOTIFICATIONS` permission to main manifest and request runtime from user before rendering NotificationsScreen. If using location services, use explicit `foregroundServiceType` in any future service declarations. |
| PLAY-018 | 🟡 MEDIUM | Backend Payment Dummy Integration | `src/controllers/paymentController.js` L1-L89 | Payment methods: Stripe/Razorpay/Google Pay/UPI not integrated. All `createPayment()` + `verifyPayment()` are fake in-memory only (no webhook, no gateway signature verification, no 3D-Secure). | If you select "Stripe Card" or "UPI" in Data Safety form as actually processed, but no real integration exists → Play can consider it deceptive. Users also report "I paid but order not marked paid" → 1-star reviews, increased crash rate. | Submit a payment → `verifyPayment` called without any real gateway webhook, but status changes to SUCCESS anyway because backend just sets it unconditionally. | Integrate production payment gateway with signed webhooks before going live. For Play uploads, if still in test phase: label "Test/Demo version" in Play Store listing description clearly so reviewer knows payments are mock. |

---

### 💡 TIER 3 — LOW RISK (Fix for Vitals/Reviews, but won't block upload)

| ID | Severity | Category | File | Location | Bug | Impact | Fix |
|----|----------|----------|------|----------|-----|--------|-----|
| PLAY-019 | 🔵 LOW | Excessive Battery Use (strict mode potential) | `frontend/lib/services/merchant_api_service.dart` L30-41 | `_isOfflineMode` cached forever for 60 seconds on a single network failure → during poor signal, app switches to mock mode instantly and stops trying real API for 1 minute. User confuses with "no data to show". | Users think orders are not showing → uninstalls, 1-star. | Shorten offline retry to ~10 seconds; show clearly in UI: "Offline mode — showing cached data" with banner snackbar. |
| PLAY-020 | 🔵 LOW | Slow Cold Start (Vitals Startup Time metric) | `frontend/android/app/src/main/res/values/styles.xml`, `styles.xml` night, `launch_background.xml` | Flutter default launch theme only. No `windowBackground` set for post-splash rendering → transition splash→first screen shows white flash ("White screen of death" on older mid-range phones). | Play Vitals "Slow cold start" > 5s warning on older Android phones. | Create a proper splash theme with matching background color matching Flutter AppTheme; eliminate the white flash. |
| PLAY-021 | 🔵 LOW | Analytics / Crash Monitoring Missing | `frontend/pubspec.yaml` dependencies and root backend package.json | No Firebase Crashlytics / Sentry / Google Analytics for Firebase dependency. | When 1000+ users install, you have **zero visibility of crashes** → you don't know why Vitals is red until after Play suspends. Add these BEFORE launch so Play console connects. | Add `firebase_crashlytics` (or Sentry) to pubspec.yaml; connect backend error middleware too. |
| PLAY-022 | 🔵 LOW | App Metadata / Store Listing | `frontend/pubspec.yaml` L1-3 | `name: herdoor_app`, `description: "A new Flutter project."` Default template description. If Play listing description doesn't clearly explain that app provides "Flour mill grinding services, delivery, merchant tools", it risks low visibility / mis-categorization. | SEO/algorithmic listing only; not a rejection but hurts installs. | Change pubspec `description:` to accurate 2-3 line summary for Play Store meta description; also fill Play listing with clear screenshots. |

---

## 2. RELATED BUG GROUPS (Root Causes)

### Group PS-A: "Hardcoded secrets & demo backdoors baked into Flutter release"
- PLAY-005 (master OTP in 4 methods)
- PLAY-006 (auto-login seeded credentials)
- PLAY-011 (forgot-password UI hints + default codes)
- PLAY-012 (pre-filled TextEditingControllers with seeded users)

### Group PS-B: "Release Android build is fundamentally broken before app logic"
- PLAY-001 (Dart syntax error — no build)
- PLAY-002 (signed with debug key → Play rejects upload)
- PLAY-003 (no INTERNET in main manifest → release crash)
- PLAY-004 (cleartext HTTP blocked → network fails)

### Group PS-C: "Session / Auth persistence broken on cold start"
- PLAY-009 (token stored in memory only, logout every restart)
- PLAY-015 (JSON parse unhandled crashes during login/register flows)

---

## 3. PLAY STORE CHECKLIST BEFORE GENERATING AAB/APK

> ✅ = must be GREEN before upload button click

| Step | Item | Status |
|------|------|:------:|
| 1 | **Fix PLAY-001** — `flutter build appbundle --release` runs WITHOUT errors (Fix Dart syntax first) | ❌ |
| 2 | **Fix PLAY-002** — Generate & upload release keystore to Play App Signing, wire `signingConfigs.release` | ❌ |
| 3 | **Fix PLAY-003** — Add INTERNET permission to main AndroidManifest.xml | ❌ |
| 4 | **Fix PLAY-004** — Add network_security_config.xml (or switch BASE_URL to HTTPS production server) | ❌ |
| 5 | **Fix PLAY-005** — Delete all hardcoded OTP "123456" / "1234" success bypass catch-blocks in auth_api_service.dart (4 locations) | ❌ |
| 6 | **Fix PLAY-006** — Delete `ensureAuthenticated()` from both customer & merchant services (no auto-login) | ❌ |
| 7 | **Fix PLAY-007** — Host public Privacy Policy (HTTPS URL), add link in-app settings, fill Play Console Data Safety | ❌ |
| 8 | **Fix PLAY-008** — Remove Apple Pay entry from Android payment_methods list | ❌ |
| 9 | **Fix PLAY-009** — Integrate `flutter_secure_storage` for JWT token/role persistence across restarts | ❌ |
| 10 | **Fix PLAY-010** — Add location permission declarations + handler when showing maps | ❌ |
| 11 | **Fix PLAY-011** — Delete all Snackbar hint texts that mention valid OTP codes | ❌ |
| 12 | **Fix PLAY-012** — Empty all TextEditingController(text: "...") demo pre-fills | ❌ |
| 13 | **Backend mandatory fixes before production domain submission**: CRITICAL bugs (BUG-001 BUG-002 BUG-003 BUG-004 BUG-007 BUG-008 BUG-009 BUG-010 BUG-011 BUG-024) | ❌ |
| 14 | Deploy backend on HTTPS domain, update Flutter BASE_URL to https://production-api.herdoor.com | ❌ |
| 15 | Run `flutter analyze` and fix all 60+ info-level issues before release | ❌ |
| 16 | Smoke-test on physical Android 10, 12, 14 devices (login/forgot-password/place-order/payment/checkout) | ❌ |
| 17 | Enable Play Console Pre-Launch Report, upload AAB to internal testing track first to get automated lab results | ❌ |
| 18 | Publish to Internal Testing Track → invite 10+ real testers → 48h soak period → check Crash-Free Sessions rate ≥ 99% | ❌ |

---

## 4. EXECUTIVE SUMMARY (Play Store only)

| Metric | Count |
|--------|-------|
| Tier 0: Will be REJECTED automatically | **6 critical blockers** |
| Tier 1: Very high manual rejection risk | **6 high** |
| Tier 2: Crash / policy edge case medium | **6 medium** |
| Tier 3: Low polish / Vitals improvements | **4 low** |
| Total Play Store specific bugs | **22** |
| Backend bugs that affect Play Store trust (from root audit) | **32 extra, 10 mandatory for launch** |
| Estimated review passes on first try | 🔴 **0% chance — will be rejected** unless Tier 0+1 fixed |
| Minimum number of issues to fix before first AAB upload | **14 items (Tier 0 + Tier 1 + Backend critical)** |

---

## 5. MINIMUM ACTION ORDER TO GET APPROVED ON FIRST TRY

1. Fix **PLAY-001** (Dart compile error) — only then can you build.
2. Fix **PLAY-002** (release signing) + setup Play App Signing in Console.
3. Fix **PLAY-003** (INTERNET) + **PLAY-004** (network security config).
4. Delete every security backdoor: **PLAY-005**, **PLAY-006**, **PLAY-011**, **PLAY-012**.
5. Fix session persistence: **PLAY-009**.
6. Fix permissions/payments for compliance: **PLAY-007**, **PLAY-008**, **PLAY-010**.
7. Fix 10 backend CRITICALs (README root audit Group C + D).
8. Deploy backend on HTTPS. Point Flutter base URL at production HTTPS.
9. Build AAB. Upload to **Internal Testing only** — wait for Pre-Launch Report.
10. Fix Pre-Launch Report crash warnings → promote to Closed Testing → 20 testers → Open Testing → Production.

---

## 6. PLAY STORE VITALS & PERFORMANCE IMPROVEMENTS (NEW SECTION)

> **Why this matters**: After passing policy + security (Tier 0-1), Google will actually run your AAB on physical devices in Pre-Launch Report and track **Android Vitals** live from the 20% worst-performing cohort of your users. If your app falls below thresholds you lose "Featured" eligibility, and if extreme (crashes > 1.09%, ANRs > 0.47%, start-up > 5s, slow renders > 5%) Play **automatically reduces visibility** and may warn users "This app may not work well on your device".

### 6.1 Android Vitals — Projected Current Scores

| Vitals Metric | Current Projection | Badge Threshold | Risk |
|--------------|--------------------|-----------------|:----:|
| **Crash-free sessions** | 🔴 ~78% (too many unhandled errors: JSON parse, token missing, auth state, cleartext HTTP) | ≥ 99.08% for "Good" badge | HIGH |
| **ANR-free sessions** | 🟡 ~95% (polling + main-isolate heavy JSON decode without isolates) | ≥ 99.28% | MED |
| **Cold start time (TTID)** | 🟡 ~3.5-5.5 s (GoogleFonts HTTP fetch on start, splash 1.4 s fixed wait, no lazy init) | ≤ 1.5 s for "Good" badge | HIGH |
| **Slow rendering (>50 ms frames)** | 🟡 8-12 % frames jank (build() computes OrderModel lists, AnimatedSwitcher/AnimatedSize in bottom-nav on every tap, AnimatedPositioned drawer on layout) | ≤ 5% for "Good" | MED |
| **Stuck partial wake locks** | 🟢 0.0 % (no foreground services used yet) | ≤ 0.10% | OK |
| **Excessive network radio use** | 🟡 ~15 % battery drainers (DashboardScreen Timer 15 s polling, merchant orders 30 s, admin orders 4 s) | ≤ 10% sessions with 50+ MB / hourly | MED |

---

## 6.2 Performance Bugs (19 items, ranked by Vitals impact)

### 🏆 TIER A — Boosts crash-free rating to 99% + fixes cold-start (Do before Internal Testing)

| ID | Affected | File / Location | Issue | Why It Kills Vitals | Suggested Fix |
|----|----------|-----------------|-------|---------------------|---------------|
| PERF-01 | 🟠 HIGH | `frontend/lib/main.dart` + all API services | **No global error / flutter error / Isolate error catch.** Every unhandled `FormatException`, `NoSuchMethodError`, or `SocketException` crashes straight to system and counts as 1 crash session. | Android Vitals crash-rate > 1.09% → instant "Poor Vitals" badge. | Wrap `runApp` in `FlutterError.onError` + `PlatformDispatcher.instance.onError` catcher. Log errors to Crashlytics/Sentry and NEVER let exception go uncaught to framework. |
| PERF-02 | 🟠 HIGH | `frontend/lib/theme/app_theme.dart` L2 (and every `GoogleFonts.playfairDisplay`/`GoogleFonts.plusJakartaSans` call on every screen build) | **GoogleFonts() pulls fonts over HTTPS every cold start.** The app has no bundled assets fonts, so: cold start → DNS → TCP → TLS → download ~80 KB Playfair Display + ~120 KB Plus Jakarta Sans before ANY text renders. If offline, falls back to system font with lag. | Adds 300-900 ms to cold start on 4G; 2-6 s on 2G; worst case total start > 5 s. Play marks as "Slow app launch". | Run `dart pub run google_fonts:as_files` to download Playfair + PlusJakartaSans into `fonts/`, register them in `pubspec.yaml` under `fonts:` family list, then change all `GoogleFonts.x` calls to plain `TextStyle(fontFamily: 'PlayfairDisplay', ...)` / `fontFamily: 'PlusJakartaSans'`. No more HTTP. |
| PERF-03 | 🟠 HIGH | `frontend/lib/screens/splash_screen.dart` L21-24 | **Forced 1400 ms splash animation** — `AnimationController` duration fixed to 1.4 s *plus* the user must also TAP the Get Started button (`onPressed: widget.onFinish`). Actual splash→login flow = animation 1.4 s + wait for user tap → cold time TTID ≥ 2.3 s before user even sees a form. | Wastes splash budget. Android wants TTID (Time To Initial Display) < 1s and Time To Full Display < 2s. | Make splash screen: (1) auto-call `widget.onFinish` after 400ms (not 1400) OR after fonts/assets loaded, whichever is later; (2) remove the mandatory manual "Get Started" tap → automatically progress. Use Flutter's Android 12 SplashScreen API via `flutter_native_splash` package (proper Android theme). |
| PERF-04 | 🟠 HIGH | `frontend/lib/services/auth_api_service.dart` L55, L104 etc. + `customer_api_service.dart` L67-69, L115-117 | **All JSON parsing runs on the MAIN UI ISOLATE.** When `CustomerApiService.getCustomerOrders()` returns 100 orders, each one is parsed with `o.fromJson()` on the same thread as build/layout/gestures. 30 orders = 20-40 ms jank; 100+ orders = skipped frames + ANR potential. | Pre-Launch Report on low-end phones (Pixel 3a) shows long frames. | Use `Isolate.run()` or `compute()` for any list parse > 10 items. Example: `final parsed = await Isolate.run(() => (jsonList as List).map(OrderModel.fromJson).toList());` |
| PERF-05 | 🟡 MED | `frontend/lib/screens/dashboard_screen.dart` L45-L49 | **Dashboard polls every 15 s on Timer.periodic (240 requests/day per user) + no abort controller + not cancelled when screen is in background.** User switches app → timer keeps firing for up to hours → radio wakes up every 15 s → **battery drain** + excessive mobile data. | Play counts "Sticky / excessive wake" — and real users leave 1-star: "drains battery". | (1) Use `WidgetsBindingObserver` and check `AppLifecycleState.paused` → Pause Timer when app minimized; Resume only on `resumed`. (2) Raise to 30-60 s default, add backoff on failure. (3) Switch to Server-Sent Events or WebSocket for push updates when possible. |
| PERF-06 | 🟡 MED | `frontend/lib/screens/dashboard_screen.dart` L149-L193 | **Active order carousel `OrderModel` construction loop runs inside build() EVERY frame.** The nested loops + regexp replaces on `quantityText.replaceAll` + string `.contains()` are re-executed every time any parent setState fires (polling every 15 s). This produces frequent ~25 ms builds → jank. | Slow frame rate on mid-range Android devices. | Lift `activeOrdersList` and `dynamicPastOrders` list building OUT of build. Compute them ONCE inside `_loadDashboardData()` when results arrive, store them in separate `_cachedActiveOrders` / `_cachedPastOrders` state fields. `build()` just reads from cache. |
| PERF-07 | 🟡 MED | `admin/src/pages/OrdersPage.jsx` L67-L73, L36-L73 (affects admin web console, but Flutter merchant apps similar) & `frontend/lib/services/merchant_api_service.dart` ~L30-41 polling | **Orders list FULL REFETCH + FULL RE-MAP every 3-4 seconds.** 900 fetches per user per day on the same data. Admin dashboard re-sorts/formats entire dataset even if nothing changed. | Backend CPU wasted → slow responses for everyone. | Add `If-None-Match` ETag / `lastUpdatedTimestamp` query / `hash` of top rows. Frontend sends the hash → backend returns HTTP 304 Not Modified instead of full dataset. On Flutter client: keep `_prevOrdersHash` → skip setState if same. |
| PERF-08 | 🟡 MED | `src/controllers/shopkeeperController.js` `getLiveOrders(millId)` L13-54 + `getShopkeeperDashboard` | **Every dashboard API call does ≥ 4 SQL queries, plus 2 fallback in-memory filter passes over ALL store.orders**. With 100 merchants polling every 30 s = 800 qps. No query cache, no DB prepared statement cache. | DB CPU spike, response times go to 800ms+ → Flutter client build gets stalled future → jank → Play says "app is slow". | Add `node-cache` or Redis in front of `getLiveOrders(millId)` with 5 s TTL (matches poll interval). Build a compound DB index on `orders (mill_id, status, created_at DESC)` — MySQL will return rows 50-80× faster. |
| PERF-09 | 🟡 MED | `src/controllers/millController.js` L28-31 `getNearbyMills` bounding-box query + L56-75 JS distance compute/sort | **Bounding-box LIMIT 50 but then sort in application code.** Without ORDER BY inside SQL, if user in dense city (Ahmedabad), limit may crop 50 nearest-west but actually 50 closest are in the south. Also ORDER BY distance in JS transfers full dataset. | Feels "slower than Google Maps search". | **Already done well**: L28-31 added bounding-box WHERE! Kudos. But add INDEX on `mills(latitude, longitude, is_open)` and, if MySQL 8.0+, use built-in `ST_Distance_Sphere(point(longitude,latitude), point(...))` ORDER BY in SQL with actual LIMIT 20. No need post-sort. |
| PERF-10 | 🟡 MED | `src/config/database.js` MySQL connection pool | **No explicit `waitForConnections: true`, `connectionLimit`, `queueLimit` config set on `createPool`.** Default mysql2 creates 10 connections and makes new queuers wait forever. Under load this triggers stalled 30 s requests that Flutter app interprets as server down. | Massive cascading timeouts during peak. | `createPool({ …, connectionLimit: process.env.DB_POOL_SIZE ?? 20, waitForConnections: true, queueLimit: 100 })` and add circuit breaker in app when DB pool is exhausted. Then monitor pool stats with `pool.on('acquire')` logging. |
| PERF-11 | 🟡 MED | `frontend/lib/screens/main_navigation_screen.dart` L43-L60 + L185-L224 | **Bottom nav rebuilds every tab with AnimatedSwitcher + AnimatedSize nested animations.** Each tab switch = 3× tween animation running = 48-60 ms GPU frame cost on older Adreno GPUs. | Play "Slow rendering" metric rises. | (1) Pre-create pages OUTSIDE build() → assign in `initState` (pages list never changes). Current code rebuilds 4 pages every single `setState` of drawer state. (2) Replace `AnimatedSize` + `AnimatedSwitcher` with a single `AnimatedCrossFade(firstChild: icon, secondChild: Row(...))` → half the tweens. (3) AnimatedPositioned drawer at L89-L105 = 600 ms layout animation that blocks GPU; reduce to 250 ms or use `Drawer` widget native. |
| PERF-12 | 🟡 MED | `frontend/lib/screens/auth/login_screen.dart` L22-L24, L29-L41 `_onRoleChanged` setState writes to TextEditingController.text inside setState while rebuild in progress | **`setState` closure modifies controller text → triggers another rebuild during current build phase.** Sometimes throws `setState() called during build` warning; rare but crashes on some Flutter builds. | Crash-free sessions metric reduced. | Move controller.text assignments OUTSIDE setState. Set state only to change `_selectedRole`. After `setState(() => _selectedRole = role);` THEN update `_phoneController.text = ...;`. |
| PERF-13 | 🟡 MED | `src/app.js` L13-15 `helmet({ contentSecurityPolicy: false })` + L38 `morgan('dev')` in prod when NODE_ENV !== 'test' | **Helmet CSP disabled globally** (Q-009 already flagged). Also **morgan('dev') runs in production too** (dev formatter writes color ANSI codes → wasted CPU on every request). | Latency increases 5-15 ms per request just for logger. | In NODE_ENV==='production' → `app.use(morgan('combined'))` (smaller). Use `compression()` middleware (not present) + `express.static` caching with ETag. Add `response-time` header for monitoring. Restore CSP with nonces for Swagger path only, not globally. |
| PERF-14 | 🟡 MED | `src/controllers/orderController.js` `createOrder` + `shopkeeperController.getPendingOrders/getCompletedOrders` | **No pagination / `LIMIT` / `OFFSET` / `cursor` on any orders list.** A year-old shop with 5000 orders: `SELECT * FROM orders WHERE mill_id = 101` returns 5000 rows every 30 s poll. | DB transfer size = 2-5 MB/poll → data usage = 150 MB/day for merchant → Play flags "high data usage". | Add `?page=1&perPage=20` or `?cursor=createdAt:<last-id>` query params to EVERY `get*Orders` endpoint. Limit max perPage=50. |
| PERF-15 | 🔵 LOW | `frontend/lib/services/auth_api_service.dart` L4 http.Client + Customer/ Merchant services each create their own `http.Client()` | **3 separate HTTP clients, 3 separate connection pools.** Handshake TLS 1.3 cost paid 3 times for hosts that are same server. | Adds 20-50 ms per session's first request. | Create ONE shared `http.Client()` instance via Provider/GetIt (DI) → inject into all 3 services. All reuse same TCP+TLS connection to backend. |
| PERF-16 | 🔵 LOW | Flutter images: `frontend/lib/screens/dashboard_screen.dart` L94-97 asset paths, `Image.asset('assets/images/...')` everywhere | No `cacheWidth`/`cacheHeight` specified, no `optimizeAddsToRenderTree` parameter. | For every `Image.asset` placed in a 400 px carousel cell, full 4096×4096 decoded bitmap stays in memory → out-of-memory crashes on 2 GB RAM phones. | Pass `cacheWidth: 400` or use `ResizedImage` provider; or pre-compile assets via `flutter build aab --split-debug-info`. |
| PERF-17 | 🔵 LOW | `src/store/dataStore.js` module-level global arrays with `find()`/`filter()` every request for fallback paths | 202 orders → O(n) `find(o => o.id === 501)` is called > 5 times in an accept/reject flow. | Minor CPU, but grows linearly with order count. | When using in-memory fallback (BUG-015 dual-write), convert primary key lookups to `Map<int, Order>` by id (`ordersById`) in parallel. Reduces lookup from O(n) to O(1). |
| PERF-18 | 🔵 LOW | `frontend/lib/main.dart` (not inspected, inferred from pubspec) | **No `--obfuscate` / `--split-debug-info` / R8/ProGuard rules explicitly set in `build.gradle.kts` release buildType**. (Default Flutter enables R8 shrink but not aggressive) | APK/AAB 15-30 % larger, startup time 100 ms slower. | Enable in app/build.gradle.kts: `isShrinkResources = true`, `isMinifyEnabled = true`. Always build: `flutter build appbundle --obfuscate --split-debug-info=build/debug-info --release`. Upload `app.android-arm64.symbols.zip` + mapping file to Play Console for deobfuscation. |
| PERF-19 | 🔵 LOW | All Flutter API services timeout/retry logic absent | Every `http.post` call has **NO `timeout(Duration(...))`** default; default http `POST` waits 2 min for response. If backend stalls under load, Flutter user sees frozen loading spinner for up to 120 s. During this time, user taps BACK multiple times = ANR (key input not dispatching). | ANR threshold 0.47% exceeded quickly with even 1 backend slow day. | Add `.timeout(const Duration(seconds: 10))` to every network call, with retry 1× (exponential backoff) on failure; show timeout error snackbar so user can retry instead of waiting. |

---

## 6.3 Priority Performance Fix Order (Vitals score ROI)

1. **PERF-01**: Catch all Flutter errors globally → crash-free sessions jumps ~ 10 points immediately.
2. **PERF-02**: Bundle GoogleFonts offline → removes ~ 500 ms cold-start network delay (fixes ~60 % of slow-launch Pre-Launch failures).
3. **PERF-03**: Reduce splash wait 1.4 s → 0.4 s, auto-advance, use native splash API (cuts TTID by ~ 1.5 s).
4. **PERF-04**: Isolate JSON parsing (big lists) → eliminates main-thread jank during dashboard polling.
5. **PERF-12 + PERF-19**: Fix login setState-during-build & add 10 s timeouts → removes 2 crash sources + ANR spikes.
6. **PERF-06 + PERF-11**: Lift heavy compute out of build() + pre-create pages + simplify animations → frame drops fall below 5 %.
7. **PERF-05**: App-lifecycle-aware polling with pause → fixes battery drain / wake-lock warnings.
8. **PERF-14**: Paginate orders APIs → 10× less data, 10× faster responses.
9. **PERF-08 + PERF-09 + PERF-10**: DB indexes, Redis/node-cache, pool tuning → backend p95 latency drops below 200 ms.
10. **PERF-15 + PERF-16 + PERF-18**: Connection reuse / image cache / AAB shrink → "Nice to have" polish that makes reviews happier.

---

## 6.4 Projected Vitals Improvements (After Tier A + Priority Top 10)

| Metric | Before | After Top 10 Fixes | Target "Good" |
|--------|:------:|:------------------:|:-------------:|
| Crash-free sessions | ~ 78% | ≥ 99.2 % | ≥ 99.08 % ✅ |
| ANR-free sessions | ~ 95% | ≥ 99.4 % | ≥ 99.28 % ✅ |
| Cold start (TTID) | 3.5-5.5 s | ~ 1.1-1.8 s | ≤ 1.5 s 🟢 mostly |
| Slow frames > 50 ms | 8-12 % | ~ 2-4 % | ≤ 5 % ✅ |
| Battery sessions > wake threshold | 15 % | ~ 5 % | ≤ 10 % ✅ |
| AAB download size | ~ 28-34 MB | ~ 19-22 MB (after R8 aggressive + obfuscate) | < 40 MB default 🟢 |

---

*End of Play Store + Performance Vitals audit. Tackle Tier 0-1 (policy/signing) FIRST, then Tier A performance fixes BEFORE uploading AAB to Internal Testing. The combined 22 policy + 19 performance bugs above, when all fixed, give your app the highest possible chance of being accepted on first Play Review pass AND staying visible once live.*
