# Build the iOS demo online

This is the same Codemagic unsigned-iOS workflow used for Plan B. You do not
need a local Mac. Codemagic supplies the Mac builder; Sideloadly signs the IPA.

1. Use the existing repository https://github.com/myndco02-ctrl/tahi on `main`.
   Version 0.2.0 includes the animated knife launch intro for iOS and Android.
2. Sign in at https://codemagic.io/apps and add that repository as a Flutter app.
3. Use codemagic.yaml and select `elTahi iOS Demo (Sideloadly)` / `ios-unsigned`.
4. Start the build. Confirm available build minutes before starting.
5. When it succeeds, download `elTahi-demo-unsigned.ipa` from build artifacts.
6. Drop that IPA (not this ZIP/folder) into Impactor or Sideloadly, choose your connected
   iPhone, and sign with your own Apple ID.

No Apple signing secrets are required in Codemagic for this unsigned build.
The workflow is configured but has not yet been run in your Codemagic account.
This is a demo of the LIVE website; real actions affect real data.

Codemagic setup documentation:
https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/
