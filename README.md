# Sangaso

Sangaso is an on-demand home-services marketplace (Flutter + Firebase). Seekers discover and book local pros; providers manage services and bookings; admins moderate users, KYC, and bookings.

> Pricing is shown in Zambian Kwacha (K). Firebase project: `ondemand-a16d1`. Currently configured for **Android + Web** (`firebase_options.dart` throws `UnsupportedError` for iOS/macOS/Windows/Linux).

## Features

- **Auth:** email/password sign-up, email verification gate, role selection (`seeker` / `provider` / `admin`), profile setup, password reset
- **Seeker:** category search (Cleaning, Plumbing, Electrical, Carpentry, Painting, Gardening, Moving, Tutoring, Beauty & Wellness, IT & Tech Support, Event Planning), service details, provider profiles, 3-step booking, booking tracking (`requested → accepted → inProgress → completed`, plus `declined`/`cancelled`), per-booking chat, reviews/ratings
- **Provider:** provider home, profile setup (`tradingName` / `category` / `bio` / `basePrice`), service CRUD (`services` collection, `isActive` toggle), accept/decline/start/complete bookings
- **Admin:** `/admin` dashboard — Overview/Users/Bookings, KYC approve/reject, ban/suspend/verify users, platform stats/revenue
- **Notifications:** Firestore-backed inbox (`bookingRequest`, `Accepted`, `Declined`, `Cancelled`, `jobStarted`, `jobCompleted`, `newMessage`, `system`) — no FCM push yet
- **Responsive shell:** mobile bottom nav (5 tabs) vs. web sidebar (>860px) via `MainShell`

## Architecture

Feature-first, no clean-architecture layers — screens call services directly via `provider` + `StreamBuilder`.

```
lib/main.dart               # Firebase init + MultiProvider DI
lib/firebase_options.dart   # Generated FlutterFire options (android + web)
lib/src/app.dart            # MaterialApp.router, Material3 + Inter theme
lib/src/core/router.dart    # go_router routes + auth redirect guards
lib/src/core/theme/         # AppTheme (primary #FF7043) + AppColors
lib/src/models/             # User, Service, Booking, Message, Review, Notification
lib/src/services/           # FirebaseAuth/Booking/Service/Messaging/Review/Notification/Admin
lib/src/features/           # auth, home, search, booking, profile, messaging, notifications, admin, onboarding
lib/src/widgets/            # MainShell, Responsive
```

**State:** `provider` only. Root `MultiProvider` exposes `AuthService (ChangeNotifier)` + `Booking / Messaging / Review / Service / Notification` services. `StreamProvider<UserModel?>` mirrors `authService.userChanges`. Local form/tab state via `setState`.

**Routing (`go_router`):** `/`, `/welcome`, `/login`, `/signup`, `/verify-email`, `/profile-setup`, `/admin` + shell routes `/home`, `/search`, `/bookings`, `/notifications`, `/profile` + detail routes `/service/:id`, `/provider/:id`, `/profile/edit`, `/services`, `/services/add`, `/services/edit/:id`, `/book/:providerId`, `/chat/:bookingId`, `/booking/:id`. Redirect forces unverified users to `/verify-email`, admins to `/admin`.

## Data (Firestore)

| Collection | Model | Notes |
|---|---|---|
| `users/{uid}` | `UserModel` | `role`, `isVerified`, profile fields, provider fields (`tradingName`, `category`, `bio`, `basePrice`), moderation (`isBanned`, `isSuspended`, `kycRejectionReason`) |
| `services/{id}` | `ServiceModel` | `providerId`, `category`, `price`, `imageUrls`, `isActive` |
| `bookings/{id}` | `BookingModel` | denormalized seeker/provider names + contacts, `status`, `scheduledTime`, `acceptedAt/startedAt/completedAt` |
| `bookings/{id}/messages/{id}` | `MessageModel` | `senderId`, `text`/`imageUrl`, `timestamp`, `isRead` |
| `reviews/{id}` | `ReviewModel` | one per booking (enforced), `rating` + `comment` |
| `notifications/{id}` | `NotificationModel` | `userId`, `type`, `relatedId` (bookingId), `isRead` |

Storage: `profile_pictures/{uid}_{ts}.jpg` via `firebase_storage`.

## Getting started

Prerequisites: Flutter SDK `>=3.0.0 <4.0.0` (CI uses 3.16.9), Dart, Android Studio / Chrome, Firebase CLI + FlutterFire CLI for reconfiguration.

```bash
flutter pub get
# Android emulator or Chrome:
flutter run -d chrome
flutter run
```

Useful commands:

```bash
flutter analyze
flutter test
flutter build apk --debug          # matches .github/workflows/build.yml
flutter build appbundle --release  # needs android/key.properties (git-ignored)
```

## Configuration / secrets

- `lib/firebase_options.dart` holds **client-side** Firebase keys (`ondemand-a16d1`) — normal to ship in-app, but repo is private by default.
- Never commit: `android/key.properties`, `*.keystore`/`*.jks`, `google-services.json`, `APK_AAD/signing/`, `*.apk`/`*.aab` (all git-ignored).
- iOS/macOS/Windows/Linux Firebase options are not configured — run `flutterfire configure` to add them if needed.

## CI

`.github/workflows/build.yml` — manual dispatch, builds debug APK on `flutter 3.16.9`, uploads `app-debug.apk`.

## Repo info

- **Name:** `sangaso`
- **Description:** Sangaso – on-demand home-services marketplace (Flutter + Firebase)
- **Visibility:** private
