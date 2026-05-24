# Vaseela Project Documentation

Welcome to the **Vaseela** codebase. This document provides a step-by-step walkthrough of the application's architecture, file structure, and core logic to help you understand the system flow.

---

## 1. Application Entry Point
### `lib/main.dart`
- **Explanation**: This is the starting point of the Flutter application. It initializes Firebase, sets up the routing system using `go_router`, and defines the global theme.
- **Important Logic**: 
    - **GoRouter Configuration**: Handles navigation and protected routes.
    - **Auth Redirect Logic**: Automatically redirects users to `/login` if not authenticated. It also checks the user's role (Admin vs. User) to ensure they land on the correct dashboard.
- **Data Flow**: `main()` → `Firebase.initializeApp()` → `VaseelaApp` → `GoRouter` → [Auth Check] → `HomeScreen` or `LoginScreen`.

---

## 2. Authentication Flow
### `lib/services/auth_service.dart`
- **Explanation**: Centralizes all Firebase Authentication logic, including registration, login, email verification, and logout.
- **Important Logic**:
    - **Email Verification**: Forces a verification email upon registration and blocks login until verified.
    - **Session Logging**: Integrates with `AuditService` to record login/logout events.
- **Data Flow**: `LoginScreen` → `AuthService.loginUser()` → `FirebaseAuth` → [Callback to Main Router].

### `lib/screens/auth/register_screen.dart` & `login_screen.dart`
- **Explanation**: The UI layers for user onboarding.
- **Important Logic**: Validates inputs (email format, password strength) and provides real-time feedback via SnackBars.

---

## 3. Core Database Logic
### `lib/services/firestore_service.dart`
- **Explanation**: The most critical file in the project. It contains all CRUD operations for Firestore.
- **Important Logic**:
    - **FIFO Disbursement Engine**: `disburseFunds()` implements a "First-In-First-Out" logic. It finds the oldest verified donations for a specific cause and deducts funds from them until the disbursement goal is met.
    - **Base64 Image Handling**: To stay within the Firebase Free Tier (Spark Plan), images (screenshots/receipts) are converted to Base64 strings and stored directly in Firestore documents.
    - **Role Management**: Handles `isAdmin` and `isSuper` (Boss) permissions.
- **Data Flow**: UI Screen → `FirestoreService` → `FirebaseFirestore` → [Snapshot Stream] → UI Update.

---

## 4. Communication & Tracking
### `lib/services/notification_service.dart`
- **Explanation**: Manages the in-app notification system.
- **Important Logic**: 
    - **Categorized Notifications**: Distinguishes between User notifications (Payment Verified, Funds Disbursed) and Admin notifications (New Payment Submitted, Team Change).
    - **Batch Operations**: Allows "Mark All as Read" using Firestore Batches.
- **Data Flow**: `FirestoreService` (on action) → `NotificationService.create...()` → Firestore `notifications` collection → `HomeScreen` (StreamBuilder).

### `lib/services/audit_service.dart`
- **Explanation**: Provides a transparent trail of all administrative actions for accountability.
- **Important Logic**: 
    - **Action Logging**: Every verification, rejection, disbursement, and team change is recorded with an actor ID, timestamp, and details.
    - **Immutable Logs**: Logs are designed to be read-only for the Boss/Super Admin.
- **Data Flow**: Admin Action → `AuditService.logAction()` → Firestore `audit_logs` collection.

---

## 5. User Experience (Donor Side)
### `lib/screens/user/home_screen.dart`
- **Explanation**: The primary dashboard for donors. Shows total impact, quick-donate options, and notifications.
- **Important Logic**:
    - **Real-time Impact Tracking**: Uses `StreamBuilder` to calculate the total amount donated by the user across all verified transactions.

### `lib/screens/user/raast_payment_screen.dart`
- **Explanation**: Handles the donation payment process.
- **Important Logic**: 
    - **Raast QR Integration**: Generates a standard Raast-compatible QR code for Pakistani banks.
    - **Proof Upload**: Captures the payment screenshot, converts it to Base64, and attaches it to the donation record for admin verification.

---

## 6. Administration (Team Side)
### `lib/screens/admin/admin_panel_screen.dart`
- **Explanation**: A multi-tab dashboard for managing the platform.
- **Tabs**:
    1. **Verifications**: Reviewing donor screenshots and marking payments as "Verified".
    2. **Disbursements**: Selecting a cause (e.g., Hunger) and disbursing available verified funds.
    3. **Settings**: Managing the Admin IBAN and account details.
    4. **Team**: Boss-level management for adding/removing team members and assigning roles (Manager, Employee, Volunteer).
    5. **Donors**: Real-time list of all donors and their total contributions.

---

## 7. Data Structures
### `lib/models/`
- **DonationModel**: Tracks the lifecycle of a donation (Pending → Verified → Disbursed).
- **DisbursementModel**: Records how funds were spent, including the proof image and which donors contributed to that specific spend.
- **NotificationModel**: Structure for the in-app alert system.

---

## 8. Security & Rules
### `firestore.rules`
- **Explanation**: The security layer that protects the database.
- **Logic**: 
    - Regular users can only see their own donations.
    - Only Admins can verify payments.
    - Only the Boss can delete users or view full audit logs.

---

## Project Flow Summary
1. **Donor** logs in → Selects **Cause** → Pays via **Raast** → Uploads **Screenshot**.
2. **Admin** sees **Notification** → Reviews **Screenshot** → **Verifies** Payment.
3. **Admin** selects **Disburse** → Uploads **Receipt** → Clicks **Disburse**.
4. **System** finds the oldest donations for that cause → Allocates funds → Sends **Notification** to all contributing donors.
5. **Donor** receives alert: "Your donation has been disbursed!" and can see the receipt.
