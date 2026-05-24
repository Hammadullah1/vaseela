# Vaseela - Transparent Donation Platform

Vaseela is a Flutter-based donation platform designed for transparency and trust. It connects donors directly with verified causes and provides real-time proof of how every penny is spent.

## Core Features
- **Raast QR Payments**: Seamless mobile banking integration for Pakistani donors.
- **FIFO Disbursement**: Ensures oldest donations are prioritized and fully tracked.
- **Impact Notifications**: Donors receive photos of receipts/proof when their specific donation is spent.
- **Admin Audit Trail**: Complete transparency for all administrative actions (Verifications, Disbursements, Team Changes).

## Getting Started
To understand the project architecture and file-by-file logic, please refer to the main documentation:
👉 **[PROJECT_DOCUMENTATION.md](./PROJECT_DOCUMENTATION.md)**

## Setup
1. Clone the repository.
2. Run `flutter pub get`.
3. Ensure you have a `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the correct directories for Firebase integration.
4. Use the provided `firestore.rules` in your Firebase console.

## Technology Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Authentication)
- **Routing**: GoRouter
- **State Management**: StreamBuilder / SetState (Minimalist & Performant)

---
Developed for transparency and community support.
