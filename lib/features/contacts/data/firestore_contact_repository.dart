import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../domain/contact_repository.dart';
import '../domain/entities.dart';

class FirestoreContactRepository implements ContactRepository {
  FirestoreContactRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _companies =>
      _firestore.collection('companies');
  CollectionReference<Map<String, dynamic>> get _contacts =>
      _firestore.collection('contacts');
  CollectionReference<Map<String, dynamic>> get _emailIndex =>
      _firestore.collection('contactEmailIndex');

  @override
  Future<ContactDirectory> load() async {
    final results = await Future.wait([
      _companies.orderBy('normalizedName').get(),
      _contacts.orderBy('normalizedFullName').get(),
    ]);
    return ContactDirectory(
      companies: results[0].docs.map(_companyFromDocument).toList(),
      contacts: results[1].docs.map(_contactFromDocument).toList(),
    );
  }

  @override
  Future<SavedContactReference> saveContact(ContactWrite value) async {
    _validate(value);
    final contact = value.contact;
    final companyName = value.companyName.trim();
    final companyId = contact.companyId.isNotEmpty
        ? contact.companyId
        : 'company_${_hash(companyName.toLowerCase()).substring(0, 24)}';
    final companyRef = _companies.doc(companyId);
    final contactRef = contact.id.isEmpty
        ? _contacts.doc()
        : _contacts.doc(contact.id);
    final newKeys = {
      for (final email in contact.emails) _hash(normalizeEmail(email.address)),
    };

    await _firestore.runTransaction((transaction) async {
      final existingContact = await transaction.get(contactRef);
      final existingCompany = await transaction.get(companyRef);
      final owners = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final key in newKeys) {
        owners.add(await transaction.get(_emailIndex.doc(key)));
      }
      for (final owner in owners) {
        if (owner.exists && owner.data()?['contactId'] != contactRef.id) {
          throw StateError(
            'Email ${owner.data()?['email']} already belongs to another contact.',
          );
        }
      }

      final oldEmails = (existingContact.data()?['emails'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => item['address']?.toString() ?? '');
      for (final email in oldEmails) {
        final key = _hash(normalizeEmail(email));
        if (!newKeys.contains(key)) transaction.delete(_emailIndex.doc(key));
      }

      final now = FieldValue.serverTimestamp();
      final primary = contact.primaryEmail;
      transaction.set(companyRef, {
        'name': companyName,
        'normalizedName': companyName.toLowerCase(),
        'domain': primary == null
            ? (existingCompany.data()?['domain'] ?? '')
            : _domainFromEmail(primary.address),
        'createdAt': existingCompany.data()?['createdAt'] ?? now,
        'updatedAt': now,
      });
      transaction.set(contactRef, {
        'companyId': companyId,
        'firstName': contact.firstName.trim(),
        'lastName': contact.lastName.trim(),
        'normalizedFullName': contact.fullName.toLowerCase(),
        'emails': contact.emails
            .map(
              (email) => {
                'id': email.id,
                'address': normalizeEmail(email.address),
                'label': email.label?.trim() ?? '',
              },
            )
            .toList(),
        'primaryEmailId': contact.primaryEmailId,
        'role': contact.role ?? '',
        'linkedinUrl': contact.linkedinUrl ?? '',
        'source': contact.source ?? '',
        'segments': contact.segments,
        'canReceiveCampaignEmails':
            primary != null && contact.canReceiveCampaignEmails,
        'createdAt': existingContact.data()?['createdAt'] ?? now,
        'updatedAt': now,
      });
      for (final email in contact.emails) {
        transaction.set(_emailIndex.doc(_hash(normalizeEmail(email.address))), {
          'contactId': contactRef.id,
          'email': normalizeEmail(email.address),
          'updatedAt': now,
        });
      }
    });
    return SavedContactReference(id: contactRef.id, companyId: companyId);
  }

  @override
  Future<void> deleteContact(String contactId) async {
    final contactRef = _contacts.doc(contactId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(contactRef);
      if (!snapshot.exists) throw StateError('Contact not found.');
      final emails = (snapshot.data()?['emails'] as List? ?? const [])
          .whereType<Map>();
      for (final email in emails) {
        final address = email['address']?.toString() ?? '';
        transaction.delete(_emailIndex.doc(_hash(normalizeEmail(address))));
      }
      transaction.delete(contactRef);
    });
  }

  @override
  Future<ImportSummary> importContacts(List<ContactWrite> contacts) async {
    var imported = 0;
    final errors = <ImportFailure>[];
    for (var index = 0; index < contacts.length; index++) {
      try {
        await saveContact(contacts[index]);
        imported++;
      } on Object catch (error) {
        errors.add(
          ImportFailure(
            row: index + 2,
            message: error.toString().replaceFirst('Bad state: ', ''),
          ),
        );
      }
    }
    return ImportSummary(
      imported: imported,
      skipped: contacts.length - imported,
      errors: errors,
    );
  }

  void _validate(ContactWrite value) {
    final contact = value.contact;
    if (value.companyName.trim().isEmpty || contact.firstName.trim().isEmpty) {
      throw StateError('Company and full name are required.');
    }
    if (contact.emails.isNotEmpty &&
        !contact.emails.any((email) => email.id == contact.primaryEmailId)) {
      throw StateError('Primary email must belong to the contact.');
    }
    if (contact.emails.isEmpty && contact.primaryEmailId != null) {
      throw StateError('A contact without emails cannot have a primary email.');
    }
  }

  Company _companyFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return Company(
      id: document.id,
      name: data['name'] as String,
      domain: _optionalString(data['domain']),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  Contact _contactFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final emails = (data['emails'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (email) => ContactEmail(
            id: email['id'] as String,
            address: email['address'] as String,
            label: _optionalString(email['label']),
          ),
        )
        .toList();
    final storedPrimaryEmailId = _optionalString(data['primaryEmailId']);
    final primaryEmailId =
        emails.any((email) => email.id == storedPrimaryEmailId)
        ? storedPrimaryEmailId
        : emails.firstOrNull?.id;
    return Contact(
      id: document.id,
      companyId: data['companyId'] as String,
      firstName: data['firstName'] as String,
      lastName: data['lastName'] as String? ?? '',
      emails: emails,
      primaryEmailId: primaryEmailId,
      role: _optionalString(data['role']),
      linkedinUrl: _optionalString(data['linkedinUrl']),
      source: _optionalString(data['source']),
      segments: (data['segments'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      canReceiveCampaignEmails:
          primaryEmailId != null &&
          (data['canReceiveCampaignEmails'] as bool? ?? false),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  String _hash(String value) => sha256.convert(utf8.encode(value)).toString();
  String _domainFromEmail(String value) =>
      normalizeEmail(value).split('@').last;
  String? _optionalString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
  DateTime _date(Object? value) => value is Timestamp
      ? value.toDate()
      : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
