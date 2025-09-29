# Hipster Task - Video Call App

A Flutter application for one-to-one video calling using the **Agora RTC SDK**, featuring mute/unmute, video toggle, screen sharing, user list caching, persistent login, and navigation to a user list via `Icons.people`.

This project serves as a starting point for building a Flutter application with real-time communication capabilities.

---

## Features

* **One-to-One Video Calling**: Real-time video calls using Agora RTC SDK.
* **Controls**: Mute/unmute audio, enable/disable video, screen sharing, and end call.
* **User List**: Displays cached users with avatars and names, accessible via `Icons.people` in the video call screen.
* **Persistent Login**: Uses `shared_preferences` for session persistence with the ReqRes API.
* **State Management**: Uses Provider for reactive UI updates (`AuthProvider`, `UserProvider`, `VideoCallProvider`).

---

## Prerequisites

* **Flutter**: Version `3.24.0` or higher (run `flutter doctor` to verify).
* **Dart**: Version `3.5.0` or higher.
* **Android SDK**: API level 21+ (`minSdk`), 34 (`targetSdk`).
* **Node.js**: Required for the token server (production use).
* **Agora Account**: Sign up at [Agora Console](https://console.agora.io/) to get an App ID.
* **Android Device/Emulator**: For testing release APKs.

---

## Build & Run Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd hipster_task
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Environment

Create `android/app/.env` with your Agora App ID:

```env
AGORA_APP_ID=your-agora-app-id
```

> Obtain the App ID from Agora Console.

### 4. Build and Run (Debug)

```bash
flutter run
```

* Select a device/emulator when prompted.
* Log in with `eve.holt@reqres.in` and password `cityslicka` for testing.

### 5. Build Release APK

#### Configure Signing

Generate a keystore (if not already created):

```bash
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

Create `android/key.properties`:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=key
storeFile=/Users/your-username/key.jks
```

Ensure `android/app/build.gradle.kts` references the signing config.

#### Build APK

```bash
flutter clean
flutter pub get
flutter build apk --release
```

#### Install APK

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

If you encounter **"App not installed as package appears to be invalid"**, see [Troubleshooting](#troubleshooting).

---

## 6. Test the App

* **Login**: Use `eve.holt@reqres.in` and `cityslicka`.
* **Video Call**: Join `test_channel` on two devices to test video calling.
* **Features**: Verify mute, video toggle, screen sharing, and `Icons.people` navigation.
* **Offline Mode**: Disable internet to test user list caching.
* **Logs**:

  ```bash
  adb logcat | grep flutter
  ```

---

## Getting Started (Flutter Resources)

* [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
* [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
* [Flutter Documentation](https://docs.flutter.dev/) for tutorials, samples, and API references.
