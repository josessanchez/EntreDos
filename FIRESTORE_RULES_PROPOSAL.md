Proposed Firestore rules (safe draft)

Goal
- Allow only authenticated users access to data they should see (progenitores -> hijos).
- Make rules query-safe for common client queries (use resource.data fields where possible).
- Provide roll-forward/rollback instructions and staging test plan.

Notes
- These rules are a draft. Do NOT deploy to production without testing in staging.
- Some client queries may rely on different field names (`hijoId`, `hijoID`, `progenitores`). We try to cover variants.
- If you prefer denormalization (copy `progenitores` into referencing documents), the rules become simpler and faster to evaluate for queries.

Proposed rules (file: `firestore.rules.proposed`)
- See `firestore.rules.proposed` in the repo root for the exact rules text.

Testing plan
1. Create a staging Firebase project or use a rules-only deploy preview.
2. Deploy rules to staging: `firebase deploy --only firestore:rules --project <staging-project>`
3. Run in a test device/emulator connected to the staging project (update `google-services.json`/`GoogleService-Info.plist` if needed).
4. Run `flutter analyze` and `flutter run -d <device-id>` and exercise the app flows: Hijos, Mensajería, Pagos (historial + disputas), Calendario, Salud, Documentos.
5. Watch logs for `PERMISSION_DENIED` and adjust rules as needed.

Rollback
- If rules block functionality, redeploy previous rules file (we keep your last-working file in version control). Example:
  - `firebase deploy --only firestore:rules --project <project-id>` (after restoring previous `firestore.rules` file)

Additional recommendations
- Consider denormalizing `progenitores` into top-level documents that reference a child: this makes query rules simpler (you can allow `resource.data.progenitores` checks, which are query-friendly).
- Enable App Check for production.
- Add Cloud Functions for admin-level operations when necessary.

I will not change live rules until you approve the draft below.
