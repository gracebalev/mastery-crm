# Mastery Email

Corporate source repository: https://github.com/gracebalev/mastery-crm

Flutter Web prototype for Mastery's internal contact and email outreach workflow.

## Contacts release

The first functional release provides:

- companies with persistent contact groups;
- contact creation, editing and deletion;
- contacts may be saved without email while research is in progress;
- multiple email addresses with one optional primary email;
- email-status filtering for missing and completed contact records;
- reusable free-form segment labels;
- per-column filtering after three characters;
- CSV import and export with user-facing headers;
- shared Firebase Firestore persistence across browsers;
- transactional email uniqueness and company preservation after contact deletion.

Run locally with `flutter run -d chrome`. Validate changes with:

```text
flutter analyze
flutter test
flutter build web
```

The deployed prototype uses the Firebase project `mastery-crm-515920` and the
Firestore collections `companies`, `contacts`, and `contactEmailIndex`.
The client signs in with a verified corporate Firebase Auth account before
accessing Firestore. Security rules allow only the Alex, Olga, and Grace
accounts from `themasterycompany.com`.

Cloud Functions CRUD handlers are included under `functions/`. The current
Spark project cannot deploy them until billing is attached, so the web runtime
uses the Firestore repository directly. All three current users have the same
admin role.
