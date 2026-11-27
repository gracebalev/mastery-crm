import 'package:cloud_functions/cloud_functions.dart';

import '../domain/contact_repository.dart';
import '../domain/entities.dart';

class CloudContactRepository implements ContactRepository {
  CloudContactRepository({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-east1');

  final FirebaseFunctions _functions;

  @override
  Future<ContactDirectory> load() async {
    final response = await _functions
        .httpsCallable('contactsList')
        .call<Map<Object?, Object?>>();
    final data = _stringMap(response.data);
    return ContactDirectory(
      companies: _mapList(data['companies']).map(_companyFromMap).toList(),
      contacts: _mapList(data['contacts']).map(_contactFromMap).toList(),
    );
  }

  @override
  Future<SavedContactReference> saveContact(ContactWrite value) async {
    final response = await _functions
        .httpsCallable('contactSave')
        .call<Map<Object?, Object?>>(_writeToMap(value));
    final data = _stringMap(response.data);
    return SavedContactReference(
      id: data['id'] as String,
      companyId: data['companyId'] as String,
    );
  }

  @override
  Future<void> deleteContact(String contactId) async {
    await _functions.httpsCallable('contactDelete').call<void>({
      'contactId': contactId,
    });
  }

  @override
  Future<ImportSummary> importContacts(List<ContactWrite> contacts) async {
    final response = await _functions
        .httpsCallable('contactsImport')
        .call<Map<Object?, Object?>>({
          'contacts': contacts.map(_writeToMap).toList(),
        });
    final data = _stringMap(response.data);
    return ImportSummary(
      imported: (data['imported'] as num).toInt(),
      skipped: (data['skipped'] as num).toInt(),
      errors: _mapList(data['errors'])
          .map(
            (error) => ImportFailure(
              row: (error['row'] as num).toInt(),
              message: error['message'] as String,
            ),
          )
          .toList(),
    );
  }

  Map<String, Object?> _writeToMap(ContactWrite value) {
    final contact = value.contact;
    return {
      if (contact.id.isNotEmpty) 'id': contact.id,
      if (contact.companyId.isNotEmpty) 'companyId': contact.companyId,
      'companyName': value.companyName,
      'firstName': contact.firstName,
      'lastName': contact.lastName,
      'emails': contact.emails
          .map(
            (email) => {
              'id': email.id,
              'address': email.address,
              'label': email.label ?? '',
            },
          )
          .toList(),
      'primaryEmailId': contact.primaryEmailId,
      'role': contact.role ?? '',
      'linkedinUrl': contact.linkedinUrl ?? '',
      'source': contact.source ?? '',
      'segments': contact.segments,
      'canReceiveCampaignEmails': contact.canReceiveCampaignEmails,
    };
  }

  Company _companyFromMap(Map<String, Object?> map) => Company(
    id: map['id'] as String,
    name: map['name'] as String,
    domain: _optionalString(map['domain']),
    createdAt: _date(map['createdAt']),
    updatedAt: _date(map['updatedAt']),
  );

  Contact _contactFromMap(Map<String, Object?> map) => Contact(
    id: map['id'] as String,
    companyId: map['companyId'] as String,
    firstName: map['firstName'] as String,
    lastName: map['lastName'] as String? ?? '',
    emails: _mapList(map['emails'])
        .map(
          (email) => ContactEmail(
            id: email['id'] as String,
            address: email['address'] as String,
            label: _optionalString(email['label']),
          ),
        )
        .toList(),
    primaryEmailId: map['primaryEmailId'] as String,
    role: _optionalString(map['role']),
    linkedinUrl: _optionalString(map['linkedinUrl']),
    source: _optionalString(map['source']),
    segments: (map['segments'] as List<Object?>? ?? const [])
        .whereType<String>()
        .toList(),
    canReceiveCampaignEmails: map['canReceiveCampaignEmails'] as bool? ?? false,
    createdAt: _date(map['createdAt']),
    updatedAt: _date(map['updatedAt']),
  );

  List<Map<String, Object?>> _mapList(Object? value) =>
      (value as List<Object?>? ?? const [])
          .map((item) => _stringMap(item as Map<Object?, Object?>))
          .toList();
  Map<String, Object?> _stringMap(Map<Object?, Object?> value) =>
      value.map((key, item) => MapEntry(key.toString(), item));
  String? _optionalString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
  DateTime _date(Object? value) => value is String
      ? DateTime.parse(value)
      : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
