import 'package:flutter_test/flutter_test.dart';
import 'package:mastery_email/core/storage/key_value_store_stub.dart';
import 'package:mastery_email/features/contacts/data/local_contact_repository.dart';
import 'package:mastery_email/features/contacts/domain/entities.dart';

void main() {
  test('keeps the company when its last contact is deleted', () {
    final repository = LocalContactRepository(MemoryKeyValueStore());
    final now = DateTime.utc(2026, 11, 27);
    final company = Company(
      id: 'company-1',
      name: 'Mastery',
      createdAt: now,
      updatedAt: now,
    );
    repository.saveCompany(company);
    repository.saveContact(
      Contact(
        id: 'contact-1',
        companyId: company.id,
        firstName: 'Olga',
        lastName: 'Nowak',
        emails: const [
          ContactEmail(id: 'email-1', address: 'olga@example.com'),
        ],
        primaryEmailId: 'email-1',
        createdAt: now,
        updatedAt: now,
      ),
    );

    repository.deleteContact('contact-1');

    expect(repository.getContacts(), isEmpty);
    expect(repository.getCompanies(), [company]);
  });

  test('rejects an email already used by another contact', () {
    final repository = LocalContactRepository(MemoryKeyValueStore());
    final now = DateTime.utc(2026, 11, 27);
    final company = Company(
      id: 'company-1',
      name: 'Mastery',
      createdAt: now,
      updatedAt: now,
    );
    repository.saveCompany(company);
    Contact contact(String id, String emailId) => Contact(
      id: id,
      companyId: company.id,
      firstName: 'Grace',
      lastName: 'Smith',
      emails: [ContactEmail(id: emailId, address: 'Grace@Example.com')],
      primaryEmailId: emailId,
      createdAt: now,
      updatedAt: now,
    );
    repository.saveContact(contact('contact-1', 'email-1'));

    expect(
      () => repository.saveContact(contact('contact-2', 'email-2')),
      throwsStateError,
    );
  });

  test('requires the primary email to belong to the contact', () {
    final repository = LocalContactRepository(MemoryKeyValueStore());
    final now = DateTime.utc(2026, 11, 27);
    final company = Company(
      id: 'company-1',
      name: 'Mastery',
      createdAt: now,
      updatedAt: now,
    );
    repository.saveCompany(company);

    expect(
      () => repository.saveContact(
        Contact(
          id: 'contact-1',
          companyId: company.id,
          firstName: 'Olga',
          lastName: 'Nowak',
          emails: const [
            ContactEmail(id: 'email-1', address: 'olga@example.com'),
          ],
          primaryEmailId: 'missing-email',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsStateError,
    );
  });
}
