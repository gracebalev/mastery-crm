import 'package:flutter_test/flutter_test.dart';
import 'package:mastery_email/core/utils/csv_codec.dart';
import 'package:mastery_email/features/contacts/domain/contact_repository.dart';
import 'package:mastery_email/features/contacts/domain/entities.dart';
import 'package:mastery_email/features/contacts/presentation/contact_controller.dart';

void main() {
  test('uses the selected primary email', () {
    final now = DateTime.utc(2026, 11, 27);
    final contact = Contact(
      id: 'contact-1',
      companyId: 'company-1',
      firstName: 'Olga',
      lastName: 'Nowak',
      emails: const [
        ContactEmail(id: 'email-1', address: 'first@example.com'),
        ContactEmail(id: 'email-2', address: 'primary@example.com'),
      ],
      primaryEmailId: 'email-2',
      createdAt: now,
      updatedAt: now,
    );

    expect(contact.primaryEmail?.address, 'primary@example.com');
  });

  test('supports a contact without email', () {
    final now = DateTime.utc(2026, 11, 27);
    final contact = Contact(
      id: 'contact-2',
      companyId: 'company-1',
      firstName: 'Anna',
      lastName: 'Kowalska',
      emails: const [],
      createdAt: now,
      updatedAt: now,
    );

    expect(contact.primaryEmail, isNull);
    expect(contact.hasPrimaryEmail, isFalse);
  });

  test('CSV codec preserves commas and quotes', () {
    const codec = SimpleCsvCodec();
    final csv = codec.encode([
      ['Company', 'Full name'],
      ['Mastery, Inc.', 'Grace "G" Smith'],
    ]);

    expect(codec.decode(csv), [
      ['Company', 'Full name'],
      ['Mastery, Inc.', 'Grace "G" Smith'],
    ]);
  });

  test('filters contacts by missing email without storing a status', () async {
    final now = DateTime.utc(2026, 11, 27);
    final controller = ContactController(_EmptyContactRepository());
    await Future<void>.delayed(Duration.zero);
    controller.companies = [
      Company(id: 'company-1', name: 'Mastery', createdAt: now, updatedAt: now),
    ];
    controller.contacts = [
      Contact(
        id: 'missing',
        companyId: 'company-1',
        firstName: 'Missing',
        lastName: 'Email',
        emails: const [],
        createdAt: now,
        updatedAt: now,
      ),
      Contact(
        id: 'complete',
        companyId: 'company-1',
        firstName: 'Complete',
        lastName: 'Contact',
        emails: const [
          ContactEmail(id: 'email-1', address: 'complete@example.com'),
        ],
        primaryEmailId: 'email-1',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    controller.setEmailFilter(EmailFilter.missing);
    expect(controller.visibleGroups.single.contacts.single.id, 'missing');

    controller.setEmailFilter(EmailFilter.hasEmail);
    expect(controller.visibleGroups.single.contacts.single.id, 'complete');
    controller.dispose();
  });

  test('imports a CSV contact without an email column', () async {
    final repository = _CapturingContactRepository();
    final controller = ContactController(repository);
    await Future<void>.delayed(Duration.zero);

    final result = await controller.importCsv(
      'Company,Full name\nNorthstar,Research Contact',
    );

    expect(result.imported, 1);
    expect(repository.imported.single.contact.emails, isEmpty);
    expect(repository.imported.single.contact.primaryEmailId, isNull);
    controller.dispose();
  });

  test(
    'imports a CSV contact with a blank email and disables outreach',
    () async {
      final repository = _CapturingContactRepository();
      final controller = ContactController(repository);
      await Future<void>.delayed(Duration.zero);

      final result = await controller.importCsv(
        'Company,Full name,Primary email,Include in email outreach\n'
        'Northstar,Future Contact,,Yes',
      );

      final contact = repository.imported.single.contact;
      expect(result.imported, 1);
      expect(contact.emails, isEmpty);
      expect(contact.primaryEmailId, isNull);
      expect(contact.canReceiveCampaignEmails, isFalse);
      controller.dispose();
    },
  );

  test('skips an unchanged contact with the same company and name', () async {
    final now = DateTime.utc(2026, 11, 27);
    final repository = _CapturingContactRepository(
      directory: ContactDirectory(
        companies: [
          Company(
            id: 'company-1',
            name: 'Northstar',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        contacts: [
          Contact(
            id: 'contact-1',
            companyId: 'company-1',
            firstName: 'Anna',
            lastName: 'Kowalska',
            emails: const [],
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
    );
    final controller = ContactController(repository);
    await Future<void>.delayed(Duration.zero);

    final result = await controller.importCsv(
      'Company,Full name\n northstar ,  ANNA   KOWALSKA ',
    );

    expect(result.imported, 0);
    expect(result.skipped, 1);
    expect(repository.imported, isEmpty);
    controller.dispose();
  });

  test('updates an existing contact when imported data changed', () async {
    final now = DateTime.utc(2026, 11, 27);
    final repository = _CapturingContactRepository(
      directory: ContactDirectory(
        companies: [
          Company(
            id: 'company-1',
            name: 'Northstar',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        contacts: [
          Contact(
            id: 'contact-1',
            companyId: 'company-1',
            firstName: 'Anna',
            lastName: 'Kowalska',
            emails: const [],
            role: 'Marketing Manager',
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
    );
    final controller = ContactController(repository);
    await Future<void>.delayed(Duration.zero);

    final result = await controller.importCsv(
      'Company,Full name,Role\nNorthstar,Anna Kowalska,CMO',
    );

    expect(result.imported, 1);
    expect(result.skipped, 0);
    expect(repository.imported.single.contact.id, 'contact-1');
    expect(repository.imported.single.contact.role, 'CMO');
    controller.dispose();
  });

  test('missing optional CSV columns do not clear existing data', () async {
    final now = DateTime.utc(2026, 11, 27);
    final repository = _CapturingContactRepository(
      directory: ContactDirectory(
        companies: [
          Company(
            id: 'company-1',
            name: 'Northstar',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        contacts: [
          Contact(
            id: 'contact-1',
            companyId: 'company-1',
            firstName: 'Anna',
            lastName: 'Kowalska',
            emails: const [],
            role: 'Marketing Manager',
            source: 'Conference',
            segments: const ['Lead'],
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
    );
    final controller = ContactController(repository);
    await Future<void>.delayed(Duration.zero);

    final result = await controller.importCsv(
      'Company,Full name\nNorthstar,Anna Kowalska',
    );

    expect(result.imported, 0);
    expect(result.skipped, 1);
    expect(repository.imported, isEmpty);
    controller.dispose();
  });

  test(
    'a blank imported email does not erase known emails on update',
    () async {
      final now = DateTime.utc(2026, 11, 27);
      final repository = _CapturingContactRepository(
        directory: ContactDirectory(
          companies: [
            Company(
              id: 'company-1',
              name: 'Northstar',
              createdAt: now,
              updatedAt: now,
            ),
          ],
          contacts: [
            Contact(
              id: 'contact-1',
              companyId: 'company-1',
              firstName: 'Anna',
              lastName: 'Kowalska',
              emails: const [
                ContactEmail(id: 'email-1', address: 'anna@northstar.co'),
              ],
              primaryEmailId: 'email-1',
              role: 'Manager',
              createdAt: now,
              updatedAt: now,
            ),
          ],
        ),
      );
      final controller = ContactController(repository);
      await Future<void>.delayed(Duration.zero);

      final result = await controller.importCsv(
        'Company,Full name,Primary email,Role\n'
        'Northstar,Anna Kowalska,,CMO',
      );

      expect(result.imported, 1);
      final updated = repository.imported.single.contact;
      expect(updated.id, 'contact-1');
      expect(updated.primaryEmail?.address, 'anna@northstar.co');
      expect(updated.role, 'CMO');
      controller.dispose();
    },
  );
}

class _EmptyContactRepository implements ContactRepository {
  @override
  Future<ContactDirectory> load() async =>
      const ContactDirectory(companies: [], contacts: []);

  @override
  Future<void> deleteContact(String contactId) async {}

  @override
  Future<ImportSummary> importContacts(List<ContactWrite> contacts) async =>
      const ImportSummary(imported: 0, skipped: 0, errors: []);

  @override
  Future<SavedContactReference> saveContact(ContactWrite contact) async =>
      const SavedContactReference(id: 'contact', companyId: 'company');
}

class _CapturingContactRepository extends _EmptyContactRepository {
  _CapturingContactRepository({
    this.directory = const ContactDirectory(companies: [], contacts: []),
  });

  final ContactDirectory directory;
  final List<ContactWrite> imported = [];

  @override
  Future<ContactDirectory> load() async => directory;

  @override
  Future<ImportSummary> importContacts(List<ContactWrite> contacts) async {
    imported.addAll(contacts);
    return ImportSummary(
      imported: contacts.length,
      skipped: 0,
      errors: const [],
    );
  }
}
