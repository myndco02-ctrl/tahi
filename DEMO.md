# elTahi Demo 0.3

Installable Android demo of https://www.eltahi.com with the elTahi name and a
green (#b8d057), rotated chef's knife on white. The icon is an editable vector,
with PNG launcher assets generated for Android and iOS.

## What this demo does

- Opens the live mobile website in the system WebView.
- Opens directly without an animated intro or artificial launch delay.
- Shows a thin loading line at the top edge, above the content's safe area.
- Uses app-titled dialogs instead of browser URL titles for alerts, confirmations
  and text prompts. iOS link previews are disabled; external links still open
  in their appropriate apps. Website addresses within content are unchanged.
- Uses the website's existing login and session cookies.
- Keeps website navigation inside the app; opens approved external links outside.
- Supports Android back navigation, a loading indicator and a connection-error Retry screen.
- Offers the Android system file picker for existing photos/videos/documents.
- Uses safe areas around the phone status bar, keyboard and navigation bar.

This is not an offline clone or an App Store/Play Store release. Website changes
appear in the app. Actions such as posts, messages and account changes affect
the live website, not a sandbox. No demo credentials are included. Native push
notifications, background tasks, deep links, camera capture and downloads have
not been implemented/tested as production features. iOS has not been built or
device-tested on this Windows computer.

## Android

Requires Android 7.0 or newer. Install the supplied APK on your phone and allow
installation from the app used to open the file, if Android asks. The APK is a
release-mode demo signed using a local debug certificate, not a store signing key.

Rebuild with Flutter 3.44.5 and the Android SDK:

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

On this machine, Gradle's online resolution stalled. The successful build used
the cached dependencies via `android/gradlew.bat --offline assembleRelease
-Ptarget-platform=android-arm,android-arm64,android-x64 -Ptarget=lib/main.dart`.

Verification covers Flutter static analysis, URL-policy and app-chrome widget tests.
The previous release was installed in an Android 14 emulator. Authenticated
posting, uploads and real-device login have not been tested with a user account.

## iOS / Sideloadly

The `ios` folder is source code, NOT an IPA. Windows cannot compile this Flutter
iOS project. On a Mac with Xcode and Flutter installed:

```sh
flutter pub get
bash tools/build-ios-demo.sh
```

The helper packages an unsigned device build as `dist/elTahi-demo-unsigned.ipa`.
Open that IPA in Sideloadly and sign/install using your own Apple ID. Do not send
Apple credentials to another person. Apple may require Developer Mode and trust
confirmation on the phone. Free-account signing expires and needs refreshing.
This build path is provided but has not been executed here.

References: https://docs.flutter.dev/platform-integration/ios/setup
and https://sideloadly.io/faq.html .

## Branding

Edit `assets/icon/knife.svg`; `tools/render-icon.cjs` creates the two 1024px PNGs
using Playwright/Edge. Set `PLAYWRIGHT_MODULE` to your installed Playwright module
when running on another machine. Then run `dart run flutter_launcher_icons`.
