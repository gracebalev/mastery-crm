import 'package:flutter_test/flutter_test.dart';
import 'package:mastery_email/core/utils/csv_codec.dart';
import 'package:mastery_email/features/contacts/domain/entities.dart';

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

    expect(contact.primaryEmail.address, 'primary@example.com');
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
}
