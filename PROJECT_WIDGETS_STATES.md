# Vaseela Project - Widgets & States Documentation

## 1. WIDGET TYPES

### 1.1 StatefulWidget Classes

#### Main App Widgets
| Widget | File | Purpose |
|--------|------|---------|
| `VaseelaApp` | `main.dart` | Root MaterialApp with GoRouter |
| `AdminPanelScreen` | `screens/admin/admin_panel_screen.dart` | Main admin panel with 5 tabs |
| `_AdminPanelScreenState` | `screens/admin/admin_panel_screen.dart` | State with TabController, manages admin tabs |

#### User Screen Widgets
| Widget | File | Purpose |
|--------|------|---------|
| `HomeScreen` | `screens/user/home_screen.dart` | User home dashboard |
| `_HomeScreenState` | `screens/user/home_screen.dart` | State with notifications toggle |
| `LoginScreen` | `screens/auth/login_screen.dart` | User/admin login |
| `_LoginScreenState` | `screens/auth/login_screen.dart` | State with form handling, admin toggle |
| `RegisterScreen` | `screens/auth/register_screen.dart` | User registration |
| `_RegisterScreenState` | `screens/auth/register_screen.dart` | State with verification UI |
| `RaastPaymentScreen` | `screens/user/raast_payment_screen.dart` | Payment flow with screenshot upload |
| `_RaastPaymentScreenState` | `screens/user/raast_payment_screen.dart` | State with image picker, submission |
| `ChooseCauseScreen` | `screens/user/choose_cause_screen.dart` | Grid of 6 causes |
| `DonorDetailScreen` | `screens/user/donor_detail_screen.dart` | Individual donor view |
| `EditProfileScreen` | `screens/user/edit_profile_screen.dart` | Profile editing |
| `SelectAmountScreen` | `screens/user/select_amount_screen.dart` | Amount selection |
| `WalletScreen` | `screens/user/wallet_screen.dart` | Transaction history |
| `MyDisbursementsScreen` | `screens/user/my_disbursements_screen.dart` | User disbursement list |
| `RequestsScreen` | `screens/user/requests_screen.dart` | Donation requests view |

#### Admin Tab Widgets (in admin_panel_screen.dart)
| Widget | Type | Purpose |
|--------|------|---------|
| `_PendingVerificationsTab` | StatelessWidget | List of payments pending verification |
| `_DisbursementsTab` | StatefulWidget | Disburse funds, view cause balances |
| `_DisbursementsTabState` | State | Manages amount input, cause selection |
| `_SettingsTab` | StatefulWidget | Admin settings (IBAN, recipient) |
| `_SettingsTabState` | State | Form handling for payment settings |
| `_TeamTab` | StatefulWidget | Team management with hierarchy |
| `_TeamTabState` | State | Search, role management, fire permissions |
| `_DonorsTab` | StatefulWidget | List of all donors |
| `_DonorsTabState` | State | Stream caching, new donor detection |

#### Legacy/Old Screen Widgets
| Widget | File | Purpose |
|--------|------|---------|
| `AdminPanelScreen` | `screens/admin_panel.dart` | Legacy admin panel (2 tabs) |
| `_RequestsTab` | `screens/admin_panel.dart` | Create/view requests |
| `_DisbursementsTab` | `screens/admin_panel.dart` | Legacy disbursement tab |
| `_DisbursementCard` | `screens/admin_panel.dart` | Individual disbursement card |
| `ScreenHome` | `screens/screen_home.dart` | Legacy home screen |
| `ScreenChooseCause` | `screens/screen_choose_cause.dart` | Legacy cause selection |
| `ScreenPayment` | `screens/screen_payment.dart` | Legacy payment screen |
| `ScreenWallet` | `screens/screen_wallet.dart` | Legacy wallet |
| `ScreenSelectAmount` | `screens/screen_select_amount.dart` | Legacy amount selector |
| `ScreenDisbursed` | `screens/screen_disbursed.dart` | Legacy disbursements |
| `ScreenRequests` | `screens/screen_requests.dart` | Legacy requests |
| `ScreenCreateAccount` | `screens/screen_create_account.dart` | Legacy registration |

### 1.2 StatelessWidget Classes

#### Custom Cards & Tiles
| Widget | File | Purpose |
|--------|------|---------|
| `_QuickDonateCard` | `screens/user/home_screen.dart` | Quick action cards (Hunger, Education, Capital) |
| `_ActionTile` | `screens/user/home_screen.dart` | List tiles for Choose Cause, Wallet |
| `_RequestCard` | `screens/admin_panel.dart` | Display individual request |
| `_AllocationRow` | `screens/admin_panel.dart` | User allocation display |
| `_CauseChip` | `screens/admin/admin_panel_screen.dart` | Cause selection chips with balance |

#### Reusable Widgets
| Widget | File | Purpose |
|--------|------|---------|
| `PaymentSlip` | `widgets/payment_slip.dart` | QR code + payment details display |
| `PhoneFrame` | `widgets/phone_frame.dart` | Phone mockup for screenshots |

---

## 2. STATE MANAGEMENT

### 2.1 State Classes (State<T>)

| State Class | Widget | Key Variables |
|-------------|--------|---------------|
| `_AdminPanelScreenState` | AdminPanelScreen | `_tab`, `_isSuper`, `_myRole` |
| `_DisbursementsTabState` | _DisbursementsTab | `_amountCtrl`, `_reasonCtrl`, `_selectedCause`, `_proofImage`, `_processing` |
| `_SettingsTabState` | _SettingsTab | `_ibanCtrl`, `_nameCtrl`, `_loading`, `_error`, `_success` |
| `_TeamTabState` | _TeamTab | `_searchQuery` |
| `_DonorsTabState` | _DonorsTab | `_donorStream`, `_previousDonorIds` |
| `_HomeScreenState` | HomeScreen | `_showNotifications` |
| `_LoginScreenState` | LoginScreen | `_emailController`, `_passwordController`, `_isAdmin`, `_loading`, `_error` |
| `_RegisterScreenState` | RegisterScreen | `_nameController`, `_emailController`, `_phoneController`, `_passwordController`, `_loading`, `_verificationSent` |
| `_RaastPaymentScreenState` | RaastPaymentScreen | `_adminIban`, `_adminName`, `_reference`, `_donationId`, `_screenshot`, `_uploading`, `_submitted` |
| `_QuickDonateCard` | Stateless | `icon`, `label`, `color`, `onTap` |
| `_ActionTile` | Stateless | `icon`, `title`, `subtitle`, `onTap` |

### 2.2 Mixin Usage

| Mixin | Used By | Purpose |
|-------|---------|---------|
| `SingleTickerProviderStateMixin` | `_AdminPanelScreenState` | TabController animation |
| `SingleTickerProviderStateMixin` | `_LoginScreenState` | Admin toggle animation |

---

## 3. CONTROLLERS & INPUTS

### 3.1 TextEditingController Instances

| Controller | Location | Purpose |
|------------|----------|---------|
| `_emailController` | LoginScreen | Email input |
| `_passwordController` | LoginScreen | Password input |
| `_nameController` | RegisterScreen | Full name input |
| `_emailController` | RegisterScreen | Email input |
| `_phoneController` | RegisterScreen | Phone input |
| `_passwordController` | RegisterScreen | Password input |
| `_amountCtrl` | DisbursementsTab | Disbursement amount |
| `_reasonCtrl` | DisbursementsTab | Disbursement reason |
| `_ibanCtrl` | SettingsTab | IBAN input |
| `_nameCtrl` | SettingsTab | Recipient name input |
| `emailCtrl` | Add Member Dialog | New member email |
| `nameCtrl` | Add Member Dialog | New member name |
| `passCtrl` | Add Member Dialog | New member password |
| `reasonCtrl` | Reject Dialog | Rejection reason |

### 3.2 Animation Controllers

| Controller | Location | Purpose |
|------------|----------|---------|
| `_tab` | AdminPanelScreen | Tab navigation (length: 5) |
| `_animController` | LoginScreen | Fade animation for admin toggle |

---

## 4. STREAMS & STREAMBUILDERS

### 4.1 Stream Sources

| Stream | Location | Data Type |
|--------|----------|-----------|
| `FirestoreService.userDonations()` | HomeScreen | `List<DonationModel>` |
| `FirestoreService.pendingVerifications()` | PendingVerificationsTab | `List<DonationModel>` |
| `FirestoreService.allDisbursements()` | DisbursementsTab (legacy) | `List<DisbursementModel>` |
| `FirestoreService.getAllUsers()` | TeamTab | `List<Map<String, dynamic>>` |
| `FirestoreService.paymentSettings()` | SettingsTab | `Map<String, dynamic>` |
| `NotificationService.getUserNotifications()` | HomeScreen | `List<NotificationModel>` |
| `NotificationService.getUnreadCount()` | HomeScreen | `int` |
| `_donorStream` | DonorsTab | `List<QueryDocumentSnapshot>` |
| `_donorStream` | Legacy DonorsTab | `List<QueryDocumentSnapshot>` |

### 4.2 FutureBuilders Used

| Future | Location | Purpose |
|--------|----------|---------|
| `_loadDonorDetails()` | PendingVerificationsTab | Get user name, email, phone |
| `_loadCauseBalances()` | DisbursementsTab | Calculate cause balances |
| `_loadDonorsForCause()` | DisbursementsTab | Get donors for selected cause |

---

## 5. KEY VARIABLES & FLAGS

### 5.1 Boolean States

| Variable | Location | Purpose |
|----------|----------|---------|
| `_isSuper` | AdminPanelScreen | Current user is Boss/Super Admin |
| `_showNotifications` | HomeScreen | Toggle notifications panel |
| `_loading` | Multiple screens | Loading indicator state |
| `_uploading` | RaastPaymentScreen | Image upload in progress |
| `_submitted` | RaastPaymentScreen | Payment proof submitted |
| `_processing` | DisbursementsTab | Disbursement in progress |
| `_verificationSent` | RegisterScreen | Email verification sent |
| `_obscure` | Login/Register | Password visibility toggle |

### 5.2 String Variables

| Variable | Location | Purpose |
|----------|----------|---------|
| `_myRole` | AdminPanelScreen | Current user's role (Manager/Employee/Volunteer) |
| `_selectedCause` | DisbursementsTab | Selected cause for disbursement |
| `_searchQuery` | TeamTab | Team member search text |
| `_error` | Multiple screens | Error message display |

---

## 6. MODELS USED

| Model | File | Purpose |
|-------|------|---------|
| `DonationModel` | `models/donation_model.dart` | Donation data structure |
| `DisbursementModel` | `models/disbursement_model.dart` | Disbursement data |
| `UserAllocation` | `models/disbursement_model.dart` | User allocation within disbursement |
| `NotificationModel` | `models/notification_model.dart` | Notification data |
| `RequestModel` | `models/request_model.dart` | Donation request data |

---

## 7. SERVICES USED

| Service | File | Methods |
|---------|------|---------|
| `AuthService` | `services/auth_service.dart` | `registerUser()`, `loginUser()`, `logout()`, `isCurrentUserAdmin()` |
| `FirestoreService` | `services/firestore_service.dart` | `addDonation()`, `updateDonationStatus()`, `disburseFunds()`, `createDisbursement()`, `verifyDisbursement()` |
| `NotificationService` | `services/notification_service.dart` | `createPaymentVerifiedNotification()`, `createDisbursementNotification()`, `notifyTeamChange()`, `createNewPaymentNotification()` |
| `ReferenceGenerator` | `services/reference_generator.dart` | `createDonationRecord()` |
| `RaastQrService` | `services/raast_qr_service.dart` | QR code generation |
| `PakistanBanks` | `services/pakistan_banks.dart` | Bank validation |

---

## 8. CONSTANTS

| Constant | File | Value |
|----------|------|-------|
| `_maxDocumentSizeBytes` | FirestoreService | 900 * 1024 (900KB) |
| `_maxImageSizeBytes` | DisbursementsTab | 200 * 1024 (200KB) |
| `_maxBatchSize` | FirestoreService | 20 |
| `AppColors.primaryGreen` | app_colors.dart | Color(0xFF1A6B3C) |
| `AppColors.gold` | app_colors.dart | Color(0xFFF5A623) |
| `AppColors.errorRed` | app_colors.dart | Color(0xFFE53935) |

---

## 9. CAUSES (6 Total)

| Key | Label | Color | Icon |
|-----|-------|-------|------|
| `hunger` | Hunger Relief | Red (0xFFE53935) | restaurant |
| `education` | Education | Blue (0xFF1976D2) | school |
| `capital` | Capital Fund | Gold (0xFFF5A623) | account_balance |
| `healthcare` | Healthcare | Green (0xFF43A047) | local_hospital |
| `shelter` | Shelter | Purple (0xFF8E24AA) | home |
| `water` | Clean Water | Blue (0xFF0288D1) | water_drop |

---

## 10. ROUTES (GoRouter)

| Route | Path | Widget |
|-------|------|--------|
| Login | `/login` | LoginScreen |
| Register | `/register` | RegisterScreen |
| Home | `/home` | HomeScreen |
| Admin | `/admin` | AdminPanelScreen |
| Cause Selection | `/cause` | ChooseCauseScreen |
| Amount Selection | `/amount?cause=` | SelectAmountScreen |
| Payment | `/payment?cause=&amount=` | RaastPaymentScreen |
| Wallet | `/wallet` | WalletScreen |
