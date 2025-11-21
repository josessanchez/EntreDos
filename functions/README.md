# Cloud Functions for EntreDos

This folder contains Firebase Cloud Functions used by the EntreDos app.

Included functions:
- `listHijosForUid`: callable function that returns child documents where the
  given UID is listed in the `progenitores` array. This function runs with
  Admin SDK privileges and is intended as a fallback for clients that cannot
  query `hijos` directly due to restrictive Firestore rules.
- `getHijoByCodigo`, `joinHijoByCodigo`, `sendNotification`, `onMensajeCreated`,
  and some debug helpers.

Quick deploy steps
1. Install dependencies:

```bash
cd functions
npm install
```

2. (Optional) Test locally with the Firebase Emulator:

```bash
firebase emulators:start --only functions
```

3. Deploy functions to your Firebase project:

```bash
# from project root or functions dir
cd functions
npm run deploy
# or: firebase deploy --only functions
```

Notes
- The callable `listHijosForUid` requires the caller to be authenticated; it
  uses `context.auth.uid` when `data.uid` is not supplied.
- Ensure the Firebase project and `firebase` CLI are configured (`firebase login`)
  and the correct project is selected (`firebase use <projectId>`).
- After deploying, clients can call the function via the Flutter
  `FirebaseFunctions.instance.httpsCallable('listHijosForUid')` helper.

Security
- This function runs with admin privileges. Keep caller authentication checks
  strict and consider adding additional authorization (custom claims) if
  needed for production.

