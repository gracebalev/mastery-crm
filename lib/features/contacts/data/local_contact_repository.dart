import 'dart:convert';

import '../../../core/storage/key_value_store_base.dart';
import '../domain/contact_repository.dart';
import '../domain/entities.dart';

class LocalContactRepository implements ContactRepository {
  LocalContactRepository(this._store) {
    _load();
  }
  static const _storageKey = 'mastery_email_contacts_v1';
  final KeyValueStore _store;
  final List<Company> _companies = [];
  final List<Contact> _contacts = [];

  @override
  List<Company> getCompanies() => List.unmodifiable(_companies);
  @override
  List<Contact> getContacts() => List.unmodifiable(_contacts);

  @override
  Company saveCompany(Company company) {
    final index = _companies.indexWhere((item) => item.id == company.id);
    if (index == -1) {
      _companies.add(company);
    } else {
      _companies[index] = company;
    }
    _persist();
    return company;
  }

  @override
  Contact saveContact(Contact contact) {
    _validate(contact);
    final index = _contacts.indexWhere((item) => item.id == contact.id);
    if (index == -1) {
      _contacts.add(contact);
    } else {
      _contacts[index] = contact;
    }
    _persist();
    return contact;
  }

  @override
  void deleteContact(String contactId) {
    _contacts.removeWhere((contact) => contact.id == contactId);
    _persist();
  }

  void _validate(Contact contact) {
    if (!_companies.any((company) => company.id == contact.companyId)) {
      throw StateError('Choose a company.');
    }
    if (contact.emails.isEmpty) throw StateError('Add at least one email.');
    if (!contact.emails.any((email) => email.id == contact.primaryEmailId)) {
      throw StateError('Choose a primary email.');
    }
    final addresses = contact.emails
        .map((email) => normalizeEmail(email.address))
        .toList();
    if (addresses.toSet().length != addresses.length) {
      throw StateError('The same email cannot be added twice.');
    }
    final used = _contacts
        .where((item) => item.id != contact.id)
        .expand((item) => item.emails)
        .map((email) => normalizeEmail(email.address))
        .toSet();
    if (addresses.any(used.contains)) {
      throw StateError('This email already belongs to another contact.');
    }
  }

  void _load() {
    final source = _store.read(_storageKey);
    if (source == null || source.isEmpty) return;
    try {
      final data = jsonDecode(source) as Map<String, dynamic>;
      _companies.addAll(
        (data['companies'] as List<dynamic>? ?? []).map(
          (item) => _companyFromJson(item as Map<String, dynamic>),
        ),
      );
      _contacts.addAll(
        (data['contacts'] as List<dynamic>? ?? []).map(
          (item) => _contactFromJson(item as Map<String, dynamic>),
        ),
      );
    } on FormatException {
      // A corrupt local draft should not prevent the app from opening.
    }
  }

  void _persist() => _store.write(
    _storageKey,
    jsonEncode({
      'companies': _companies.map(_companyToJson).toList(),
      'contacts': _contacts.map(_contactToJson).toList(),
    }),
  );

  Map<String, dynamic> _companyToJson(Company company) => {
    'id': company.id,
    'name': company.name,
    'domain': company.domain,
    'createdAt': company.createdAt.toIso8601String(),
    'updatedAt': company.updatedAt.toIso8601String(),
  };
  Company _companyFromJson(Map<String, dynamic> json) => Company(
    id: json['id'] as String,
    name: json['name'] as String,
    domain: json['domain'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
  Map<String, dynamic> _contactToJson(Contact contact) => {
    'id': contact.id,
    'companyId': contact.companyId,
    'firstName': contact.firstName,
    'lastName': contact.lastName,
    'emails': contact.emails
        .map(
          (email) => {
            'id': email.id,
            'address': email.address,
            'label': email.label,
          },
        )
        .toList(),
    'primaryEmailId': contact.primaryEmailId,
    'role': contact.role,
    'linkedinUrl': contact.linkedinUrl,
    'source': contact.source,
    'segments': contact.segments,
    'canReceiveCampaignEmails': contact.canReceiveCampaignEmails,
    'createdAt': contact.createdAt.toIso8601String(),
    'updatedAt': contact.updatedAt.toIso8601String(),
  };
  Contact _contactFromJson(Map<String, dynamic> json) => Contact(
    id: json['id'] as String,
    companyId: json['companyId'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    emails: (json['emails'] as List<dynamic>).map((item) {
      final map = item as Map<String, dynamic>;
      return ContactEmail(
        id: map['id'] as String,
        address: map['address'] as String,
        label: map['label'] as String?,
      );
    }).toList(),
    primaryEmailId: json['primaryEmailId'] as String,
    role: json['role'] as String?,
    linkedinUrl: json['linkedinUrl'] as String?,
    source: json['source'] as String?,
    segments: List<String>.from(json['segments'] as List<dynamic>? ?? []),
    canReceiveCampaignEmails:
        json['canReceiveCampaignEmails'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
