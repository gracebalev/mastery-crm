import 'package:flutter_test/flutter_test.dart';
import 'package:mastery_email/features/contacts/domain/business_card_draft.dart';

void main() {
  test('offline card parsing extracts email and LinkedIn without guessing', () {
    const text = '''
Marie Dubois
Managing Director
Northstar Coaching
MARIE@NORTHSTAR.FR
linkedin.com/in/marie-dubois
''';

    final draft = BusinessCardDraft.offline(text);

    expect(draft.emails, ['marie@northstar.fr']);
    expect(draft.linkedinUrl, 'https://linkedin.com/in/marie-dubois');
    expect(draft.fullName, isEmpty);
    expect(draft.company, isEmpty);
    expect(draft.role, isEmpty);
    expect(draft.usedOfflineFallback, isTrue);
  });

  test('function data is normalized into a contact draft', () {
    final draft = BusinessCardDraft.fromFunctionData({
      'fullName': ' Marie Dubois ',
      'company': 'Northstar Coaching',
      'role': 'Managing Director',
      'emails': ['marie@northstar.fr', '', 'marie@northstar.fr'],
      'linkedinUrl': 'https://linkedin.com/in/marie-dubois',
    }, rawText: 'raw');

    expect(draft.fullName, 'Marie Dubois');
    expect(draft.emails, ['marie@northstar.fr']);
    expect(draft.rawText, 'raw');
    expect(draft.usedOfflineFallback, isFalse);
  });
}
