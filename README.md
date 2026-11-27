# Mastery Email

Flutter Web prototype for Mastery's internal contact and email outreach workflow.

## Contacts release

The first functional release provides:

- companies with persistent contact groups;
- contact creation, editing and deletion;
- multiple email addresses with one primary email;
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

Cloud Functions CRUD handlers are included under `functions/`. The current
Spark project cannot deploy them until billing is attached, so the web runtime
uses the Firestore repository directly. Firestore authentication must be added
before the prototype is exposed beyond the internal testing group.
