# Release Checklist — Play Store & App Store

This checklist prepares the repository and CI for publishing Android and iOS releases.

Pre-requisites
- Android keystore (`keystore.jks`) and `keystore.properties` created locally (see `SIGNING.md`).
- Google Play Console service account JSON (for CI) if you want automatic uploads.
- Apple developer account and App Store Connect API key/certificates (Fastlane `AppStore Connect` or match) for iOS automation.
- GitHub repository secrets configured if using CI automation (see **CI secrets** below).

CI secrets (recommended names)
- `KEYSTORE_BASE64` — base64-encoded keystore file for GitHub Actions (optional)
- `KEYSTORE_PASSWORD` — keystore password
- `KEY_ALIAS` — key alias
- `KEY_PASSWORD` — key password
- `FIREBASE_TOKEN` — token for `firebase deploy` (Functions deploy workflow)
- `PLAY_STORE_SERVICE_ACCOUNT` — base64 JSON for Play Store upload (optional)
- `APP_STORE_CONNECT_KEY` — base64 P8 key or Fastlane credentials for App Store (optional)

High-level steps to release Android (manual)
1. Ensure `keystore.properties` exists in repo root (local only) or CI secrets are set.
2. Build signed AAB locally:

```powershell
flutter build appbundle --release
```

3. Upload the generated AAB (`build/app/outputs/bundle/release/app-release.aab`) to Play Console.
4. Test release track (internal testing) before rolling out to production.

High-level steps to release iOS (manual)
1. Use Xcode or `flutter build ipa` with proper signing identities.
2. Use Transporter or Xcode to upload the IPA to App Store Connect.
3. Create release in App Store Connect and submit for review.

Using CI for release (recommended)
- For Android: use Gradle + GitHub Actions job that writes `keystore.properties` from secrets and runs `flutter build appbundle --release`; optionally use `r0adkll/upload-google-play` action or Fastlane to upload.
- For iOS: use Fastlane with App Store Connect API key stored in secrets and let it build & upload.

Verification
- Verify the built artifacts locally (install internal test APK or use internal testing track).
- Run smoke tests and QA flows before production rollout.

Rollback
- If a release causes issues, use Play Console/App Store Connect rollout controls, or revert the release version and re-publish with fixes.

Notes
- Never commit `keystore.properties`, `.jks` or Apple private keys to the repository.
- Keep CI environment Node version aligned with `.nvmrc` (we use `20` for Cloud Functions).

If you want, I can:
- Add example GitHub Actions steps to upload AAB to Play Store using `PLAY_STORE_SERVICE_ACCOUNT` secret, or
- Add Fastlane configuration skeleton for Android/iOS.
