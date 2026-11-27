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
- browser-local persistence for the prototype.

Run locally with `flutter run -d chrome`. Validate changes with:

```text
flutter analyze
flutter test
flutter build web
```

Browser-local data is intended for prototype testing. A shared backend is required before Olga and Grace can work with the same contact directory from different browsers.
