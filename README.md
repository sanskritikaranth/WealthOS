# 💰 WealthOS

**A smart personal finance companion — track expenses, manage your portfolio, and get AI-powered financial insights, all in one sleek app.**

Built with Flutter, Firebase Authentication, and Cloud Firestore. WealthOS helps you see your *true net worth* at a glance, keeps your budget in check with real-time alerts, and lets you chat with an AI financial advisor whenever you need guidance.

---

### 🔗 Quick Links

| | |
|---|---|
| 🌐 **Live Demo** | [wealthos-cc738.web.app](https://wealthos-cc738.web.app) |
| 📱 **Download Android APK** | [Download here](#) *(https://tinyurl.com/wealthos-app)* |
| 💻 **Source Code** | You're already here! |

---

## ✨ Features

### 🔐 Authentication
- Email/password sign-up and login, powered by **Firebase Authentication**
- Persistent sessions — close the app and reopen anytime, no re-login needed
- Every user's data is fully private and isolated (enforced at the database level, not just the UI)

### 📊 Dashboard
- **True Net Worth** card — combines liquid cash + investment value in one number, tap to toggle between full and abbreviated (₹1.2L / ₹1.2Cr) formats
- **Monthly budget ceiling** with a live progress bar
- Real-time **in-app alert feed** for budget thresholds, big spends, and portfolio milestones

### 💸 Expenses
- Add, categorize, and delete transactions on the fly
- Search and filter by category (Food, Housing, Entertainment, Others)
- Pull-to-refresh, swipe-to-delete
- Editable monthly budget — synced instantly across every screen

### 📈 Portfolio
- Track stocks and crypto holdings side by side
- Automatic **portfolio concentration warnings** (e.g. "75% of your portfolio is in one asset")
- **All-time-high tracker** — get notified when your portfolio hits a new peak

### 🤖 AI Financial Advisor
- Built-in chatbot for financial questions, budgeting tips, and quick advice

### 🔔 Notifications
- Native Android notifications for budget alerts, spending spikes, and portfolio milestones
- In-app notification banners, dismissible with a swipe

### 🌓 Light & Dark Themes
- Clean, modern light mode
- Sleek "matte neon" dark mode with glowing accent highlights

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart) |
| **State Management** | Riverpod |
| **Authentication** | Firebase Authentication (Email/Password) |
| **Database** | Cloud Firestore (per-user scoped, real-time sync) |
| **Local Notifications** | Native Android `MethodChannel` + `NotificationCompat` |
| **Hosting (Web)** | Firebase Hosting |
| **Other Packages** | `flutter_riverpod`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `confetti`, `flutter_dotenv`, `http` |

---

## 🔑 Login & Signup Flow

WealthOS uses a simple, secure authentication flow with **zero backend code of your own** — Firebase handles all of it:

1. **First launch** → app checks the current Firebase auth session
   - No active session → **Login screen**
   - Active session → straight to the **Dashboard**
2. **New user?** Tap **"Sign up"** → enter email + password (min. 6 characters) → account is created instantly via Firebase Authentication
3. **Existing user?** Enter your email + password on the **Login screen**
4. Once authenticated, a unique Firestore document is created for that user (`users/{uid}`) — this is where all their expenses, portfolio holdings, and wallet data live, **completely isolated from every other user**
5. **Log out** anytime via the logout icon in the top app bar — returns you cleanly to the Login screen
6. Sessions persist automatically across app restarts, thanks to Firebase's built-in session management — no manual token handling required

**Security:** Firestore rules restrict every user to reading and writing *only* their own data:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.4.0 or higher)
- [Firebase CLI](https://firebase.google.com/docs/cli) — `npm install -g firebase-tools`
- [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup) — `dart pub global activate flutterfire_cli`
- A Firebase project (free Spark plan is enough)

### 1️⃣ Clone the repo
```bash
git clone https://github.com/yourusername/wealthos.git
cd wealthos
```

### 2️⃣ Install dependencies
```bash
flutter pub get
```

### 3️⃣ Connect your own Firebase project
```bash
firebase login
flutterfire configure
```
Select (or create) a Firebase project, and choose the platforms you need (Android/Web/iOS). This generates `lib/firebase_options.dart` automatically.

In the [Firebase Console](https://console.firebase.google.com):
- **Authentication → Sign-in method** → enable **Email/Password**
- **Firestore Database** → create a database → paste in the security rules shown above under the **Rules** tab → **Publish**

### 4️⃣ Set up environment variables
Create a `.env` file in the project root:
```
OPENAI_API_KEY=your_openai_api_key_here
```
> ⚠️ Never commit your real `.env` file — it's already excluded via `.gitignore`.

### 5️⃣ Run the app
```bash
flutter run
```

---

## 📦 Deployment

### 🌐 Web (Firebase Hosting)
```bash
flutter build web --release
firebase init hosting   # first time only
firebase deploy --only hosting
```

### 📱 Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

> 💡 If your build environment blocks release compilation (common with strict Windows security policies), use `flutter build apk --debug` instead — fully installable and functional, just not optimized/signed for the Play Store.

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── auth_gate.dart              # Routes between Login and Dashboard based on auth state
│   ├── navigation_shell.dart       # Bottom nav + app-wide shell
│   ├── notification_provider.dart  # In-app alert state
│   ├── notification_service.dart   # Native Android notification bridge
│   ├── theme_provider.dart         # Light/Dark theme state
│   └── services/
│       ├── auth_service.dart          # Firebase Auth wrapper
│       ├── auth_state_provider.dart   # Global auth-state stream
│       ├── firestore_service.dart     # All Firestore reads/writes
│       └── wallet_provider.dart       # Bank balance & budget state
├── features/
│   ├── auth/                       # Login & Signup screens
│   ├── dashboard/                  # Net worth, budget, alerts
│   ├── expenses/                   # Transaction tracking
│   ├── portfolio/                  # Investment tracking
│   ├── chatbot/                    # AI financial advisor
│   └── calculators/                # Financial predictors/tools
└── main.dart                       # App entry point
```

---

## 🗺️ Roadmap / Future Improvements

- [ ] Proper release signing config for Play Store distribution
- [ ] Password reset flow
- [ ] Multi-currency support
- [ ] Charts/graphs for spending trends over time
- [ ] Export expenses to CSV

---

## 📄 License

This project is open source and available for personal and educational use.

---

## 🙋 Author

Built by **SANSKRITI KARANTH** — 4th year ISE student.


---

<p align="center">⭐ If you found this project interesting, consider giving it a star!</p>
