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
  final List<ContactWrite> imported = [];

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
