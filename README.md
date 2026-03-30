# 📱 PortfolioMe: Digital CV & Portfolio App

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0-0175C2?style=for-the-badge&logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?style=for-the-badge&logo=firebase)
![Provider](https://img.shields.io/badge/State_Management-Provider-blue?style=for-the-badge)
![Cloudinary](https://img.shields.io/badge/Storage-Cloudinary-3448C5?style=for-the-badge&logo=cloudinary)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**PortfolioMe** is more than a resume builder — it's your digital professional identity in your pocket. Built with Flutter and Firebase, it combines a sleek Dark Navy & Gold UI with powerful CV management tools. It empowers professionals to build, manage, and instantly share a complete portfolio — experience, education, projects, and a one-tap PDF export — all from their phone.

---

## 📸 Application Showcase

| Profile | Portfolio | Contact | PDF Export |
|:---:|:---:|:---:|:---:|
| <img src="screenshots/profile_screen.jpg" width="200" alt="Profile Screen"> | <img src="screenshots/portfolio_screen.jpg" width="200" alt="Portfolio Screen"> | <img src="screenshots/contact_screen.jpg" width="200" alt="Contact Screen"> | <img src="screenshots/pdfexport_screen.jpg" width="200" alt="PDF Export Screen"> |

---

## 🚀 Core Capabilities

### 👤 **Smart Profile Builder**
* **Complete CV Data** — Name, job title, bio, location, contact info, and social links all in one place.
* **Tabbed Editor** — Dedicated tabs for Work Experience, Education, and Projects with full Add / Edit / Delete support.
* **Confirmation Guards** — Delete confirmation dialogs to prevent accidental data loss.
* **Persistent Storage** — All data synced in real-time to Cloud Firestore, accessible across devices.

### 🖼️ **Cloud Photo Management**
* **Cloudinary Integration** — Profile photo upload via Cloudinary free tier — no billing required.
* **Live Progress Indicator** — Real-time upload progress shown directly on the photo widget.
* **Smart Fallback** — Displays the user's initials when no photo is set.

### 📄 **Professional PDF Export**
* **One-Tap Generation** — Exports a clean, well-structured A4 resume from live Firestore data.
* **Real Photo in PDF** — Profile photo is fetched from Cloudinary and embedded directly in the PDF header.
* **Two-Column Layout** — Experience & Education on the left, Skills & Projects on the right for maximum readability.
* **Preview & Share** — Preview before downloading, or share instantly via any platform.

### 📂 **Portfolio Showcase**
* **Project Cards** — Each project displays name, description, tech stack chips, and direct GitHub / Live URL links.
* **Stats Summary** — Quick overview of total projects, skills, and jobs at the top of the Portfolio tab.
* **User-Specific** — Every user sees only their own data pulled directly from Firestore.

### 📬 **Interactive Contact Page**
* **One-Tap Actions** — Email, call, and open LinkedIn/GitHub with a single tap using `url_launcher`.
* **Long Press to Copy** — Long press any contact row to copy to clipboard.
* **Smart Empty States** — Missing info shows an "+ Add" card that navigates directly to Edit Profile.

### 🔐 **Secure Authentication**
* **Firebase Auth** — Email/password registration and login.
* **Remember Me** — Persistent login using `SharedPreferences`.
* **Re-Auth on Delete** — Account deletion requires password re-entry for security.
* **Smart Splash** — Splash screen waits for Firebase Auth state to fully restore before routing.

---

## 🏗️ Technical Architecture

PortfolioMe is built on a **Feature-First Layered Architecture**, ensuring clean separation of concerns, scalability, and maintainability.

### 📂 Directory Map

```text
lib/
├── core/
│   ├── constants/         # AppColors, gradients, shadows
│   ├── theme/             # Material dark theme (DM Sans + Space Grotesk)
│   └── utils/             # Form validators
├── data/
│   └── services/          # AuthService, AuthProvider, StorageService, PdfExportService
├── screens/
│   ├── auth/              # Login, Register, ForgotPassword
│   ├── splash/            # Animated splash with auth routing
│   ├── home/              # HomeScreen (Profile · Portfolio · Contact tabs)
│   └── profile/           # EditProfileScreen (4-tab editor)
└── widgets/               # CVTextField, GoldButton, ProfilePhotoWidget, ExportCVButton
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x |
| Language | Dart 3.0 |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Photo Storage | Cloudinary (free tier — no billing) |
| State Management | Provider |
| PDF Generation | `pdf` + `printing` + `share_plus` |
| Fonts | DM Sans · Space Grotesk (Google Fonts) |
| Icons | Font Awesome Flutter |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- Firebase project (Authentication + Firestore enabled)
- Cloudinary account (free — no credit card required)

### Setup

**1. Clone the repo**
```bash
git clone https://github.com/YOUR_USERNAME/portfoliome.git
cd portfoliome
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Configure Firebase**
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
Place the generated `google-services.json` in `android/app/`

**4. Configure Cloudinary**

In `lib/data/services/storage_service.dart`:
```dart
static const String _cloudName    = 'your_cloud_name';   // Cloudinary Dashboard
static const String _uploadPreset = 'cv_app_uploads';    // Unsigned preset
```

**5. Run**
```bash
flutter run
```

---

## 🔥 Firebase Setup

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create project → Add Android app → download `google-services.json`
3. Enable **Authentication** → Email/Password
4. Create **Firestore** database → Production mode
5. Apply security rules from `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## ☁️ Cloudinary Setup (Free — No Credit Card)

1. Sign up at [cloudinary.com](https://cloudinary.com/users/register_free)
2. Go to **Settings → Upload → Upload Presets → Add upload preset**
3. Set **Signing Mode** to `Unsigned`
4. Name it `cv_app_uploads`
5. Copy your **Cloud Name** from the Dashboard

---

## 📦 Build Release AAB

```bash
# 1. Generate keystore (first time only)
keytool -genkey -v -keystore android/app/cv_keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias cv_key

# 2. Create android/key.properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=cv_key
storeFile=cv_keystore.jks

# 3. Build
flutter build appbundle --release
```
> Output: `build/app/outputs/bundle/release/app-release.aab`

---
