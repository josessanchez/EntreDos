# Android App Signing — Instructions

This project is prepared to support a standard Android signing workflow. Follow these steps when you're ready to sign release builds.

1) Create or obtain your keystore

- Use `keytool` to create a JKS if you don't have one yet:

```powershell
keytool -genkeypair -v -keystore C:\path\to\my-release-key.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

2) Create a local `keystore.properties` file

- Copy the provided template at `android/keystore.properties.template` to the project root as `keystore.properties` (do NOT commit it):

```powershell
copy android\keystore.properties.template keystore.properties
# then edit keystore.properties with your real paths/passwords
notepad keystore.properties
```

- Example `keystore.properties` content:

```
storeFile=C:\Users\you\keys\my-release-key.jks
storePassword=your_store_password
keyAlias=upload
keyPassword=your_key_password
```

3) Build a signed AAB/APK

- When `keystore.properties` is present in the project root, the Gradle build will automatically configure a `release` signing config.

Build a release AAB:

```powershell
flutter build appbundle --release
```

Or an APK:

```powershell
flutter build apk --release
```

4) CI / automation notes

- Never store `keystore.properties` or `.jks` files in the repository. Use CI secret stores (GitHub Actions secrets, GitLab CI variables) and write them to the workspace during the pipeline run.
- Example GitHub Actions steps:
  - Checkout
  - Restore secrets to `keystore.properties` and `keystore.jks`
  - Run `flutter build appbundle --release`
  - Upload artifact

5) Optional: Verify the signing

- Use `apksigner` (Android SDK build tools) to verify the built artifact:

```powershell
apksigner verify --print-certs build\app\outputs\bundle\release\app-release.aab
```

Security reminders
- Do NOT commit passwords, keystore files, or `keystore.properties` into Git.
- Rotate keys if you believe secrets were leaked.

If you want, I can also:
- Add a GitHub Actions workflow template to build an AAB using repository secrets (I will not store any secrets in the repo).
- Create a small PowerShell helper script to copy the template and prompt for values.
