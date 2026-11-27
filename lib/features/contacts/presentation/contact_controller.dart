import 'package:flutter/foundation.dart';

import '../../../core/utils/csv_codec.dart';
import '../domain/contact_repository.dart';
import '../domain/entities.dart';

class ContactController extends ChangeNotifier {
  ContactController(this._repository) {
    reload();
  }

  static const csvHeaders = <String>[
    'Company',
    'Full name',
    'Primary email',
    'Role',
    'Event / Source',
    'LinkedIn URL',
    'Segments',
    'Include in email outreach',
  ];

  final ContactRepository _repository;
  final _csv = const SimpleCsvCodec();
  var _sequence = 0;

  List<Company> companies = [];
  List<Contact> contacts = [];
  bool isLoading = true;
  String? loadError;
  String globalSearch = '';
  final Map<String, String> columnFilters = {};
  bool filtersVisible = false;
  EmailFilter emailFilter = EmailFilter.all;

  Future<void> reload() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      final directory = await _repository.load();
      companies = [...directory.companies]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      contacts = [...directory.contacts]
        ..sort(
          (a, b) =>
              a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );
    } on Object catch (error) {
      loadError = _errorMessage(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Set<String> get knownSegments =>
      contacts.expand((contact) => contact.segments).toSet();

  List<CompanyContactGroup> get visibleGroups {
    final query = globalSearch.trim().toLowerCase();
    final activeQuery = query.length >= 3 ? query : '';
    return companies
        .map((company) {
          final companyContacts = contacts
              .where((contact) => contact.companyId == company.id)
              .where(_matchesEmailFilter)
              .where((contact) {
                final primaryEmail = contact.primaryEmail?.address ?? '';
                if (activeQuery.isNotEmpty &&
                    !_includes(company.name, activeQuery) &&
                    !_includes(contact.fullName, activeQuery) &&
                    !_includes(primaryEmail, activeQuery)) {
                  return false;
                }
                return _matchesFilter('Company', company.name) &&
                    _matchesFilter(
                      'Contact',
                      '${contact.fullName} $primaryEmail',
                    ) &&
                    _matchesFilter('Role', contact.role ?? '') &&
                    _matchesFilter('Event / Source', contact.source ?? '') &&
                    _matchesFilter('LinkedIn', contact.linkedinUrl ?? '') &&
                    _matchesFilter('Segment', contact.segments.join(' '));
              })
              .toList();
          final companyMatches =
              activeQuery.isNotEmpty && _includes(company.name, activeQuery);
          final hasColumnFilters = columnFilters.values.any(
            (value) => value.trim().length >= 3,
          );
          if (companyContacts.isEmpty &&
              (contacts.any((contact) => contact.companyId == company.id) ||
                  activeQuery.isNotEmpty ||
                  hasColumnFilters ||
                  emailFilter != EmailFilter.all) &&
              !companyMatches) {
            return null;
          }
          return CompanyContactGroup(
            company: company,
            contacts: companyContacts,
          );
        })
        .whereType<CompanyContactGroup>()
        .toList();
  }

  bool _matchesFilter(String key, String value) {
    final filter = columnFilters[key]?.trim().toLowerCase() ?? '';
    return filter.length < 3 || _includes(value, filter);
  }

  bool _includes(String value, String query) =>
      value.toLowerCase().contains(query);

  bool _matchesEmailFilter(Contact contact) => switch (emailFilter) {
    EmailFilter.all => true,
    EmailFilter.missing => !contact.hasPrimaryEmail,
    EmailFilter.hasEmail => contact.hasPrimaryEmail,
  };

  void setGlobalSearch(String value) {
    globalSearch = value;
    notifyListeners();
  }

  void setColumnFilter(String key, String value) {
    columnFilters[key] = value;
    notifyListeners();
  }

  void toggleFilters() {
    filtersVisible = !filtersVisible;
    notifyListeners();
  }

  void setEmailFilter(EmailFilter value) {
    emailFilter = value;
    notifyListeners();
  }

  Future<Contact> saveContact(
    ContactFormValue value, {
    Contact? existing,
  }) async {
    final now = DateTime.now().toUtc();
    var company = value.companyId == null
        ? null
        : companies.where((item) => item.id == value.companyId).firstOrNull;
    company ??= companies
        .where(
          (item) =>
              _normalizeIdentity(item.name) ==
              _normalizeIdentity(value.companyName),
        )
        .firstOrNull;
    final names = splitFullName(value.fullName);
    final companyName = value.companyName.trim();
    final identityMatch = contacts
        .where(
          (contact) =>
              _contactIdentityKey(contact) ==
              _identityKey(companyName, '${names.firstName} ${names.lastName}'),
        )
        .firstOrNull;
    if (existing != null &&
        identityMatch != null &&
        identityMatch.id != existing.id) {
      throw StateError(
        'A contact with this company and full name already exists.',
      );
    }
    final target = existing ?? identityMatch;
    final contact = Contact(
      id: target?.id ?? '',
      companyId: company?.id ?? '',
      firstName: names.firstName,
      lastName: names.lastName,
      emails: value.emails
          .where((email) => email.address.trim().isNotEmpty)
          .map(
            (email) => ContactEmail(
              id: email.id,
              address: normalizeEmail(email.address),
              label: _blankToNull(email.label),
            ),
          )
          .toList(),
      primaryEmailId: value.primaryEmailId,
      role: _blankToNull(value.role),
      linkedinUrl: _blankToNull(value.linkedinUrl),
      source: _blankToNull(value.source),
      segments: value.segments
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(),
      canReceiveCampaignEmails:
          value.primaryEmailId != null && value.canReceiveCampaignEmails,
      createdAt: target?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      final saved = await _repository.saveContact(
        ContactWrite(contact: contact, companyName: companyName),
      );
      await reload();
      return contacts.firstWhere((item) => item.id == saved.id);
    } on Object catch (error) {
      throw StateError(_errorMessage(error));
    }
  }

  Future<void> deleteContact(Contact contact) async {
    try {
      await _repository.deleteContact(contact.id);
      await reload();
    } on Object catch (error) {
      throw StateError(_errorMessage(error));
    }
  }

  Future<ImportResult> importCsv(String source) async {
    final rows = _csv.decode(source);
    if (rows.isEmpty) {
      return const ImportResult(
        imported: 0,
        skipped: 0,
        errors: ['The CSV file is empty.'],
      );
    }
    final header = rows.first.map((cell) => cell.trim()).toList();
    final indexes = <String, int>{
      for (var i = 0; i < header.length; i++) header[i].toLowerCase(): i,
    };
    final missing = csvHeaders
        .take(2)
        .where((name) => !indexes.containsKey(name.toLowerCase()))
        .toList();
    if (missing.isNotEmpty) {
      return ImportResult(
        imported: 0,
        skipped: rows.length - 1,
        errors: ['Missing required columns: ${missing.join(', ')}'],
      );
    }

    var skipped = 0;
    final errors = <String>[];
    final writes = <ContactWrite>[];
    final pendingIndexes = <String, int>{};
    final existingByIdentity = <String, Contact>{
      for (final contact in contacts) _contactIdentityKey(contact): contact,
    };
    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      String cell(String name) {
        final index = indexes[name.toLowerCase()];
        return index == null || index >= row.length ? '' : row[index].trim();
      }

      bool hasColumn(String name) => indexes.containsKey(name.toLowerCase());

      final company = cell('Company');
      final fullName = cell('Full name');
      final email = normalizeEmail(cell('Primary email'));
      if (company.isEmpty || fullName.isEmpty) {
        skipped++;
        errors.add('Row ${rowIndex + 1}: Company and Full name are required.');
        continue;
      }
      final identity = _identityKey(company, fullName);
      final existing = existingByIdentity[identity];
      if (email.isNotEmpty &&
          contacts.any(
            (contact) =>
                contact.id != existing?.id &&
                contact.emails.any(
                  (item) => normalizeEmail(item.address) == email,
                ),
          )) {
        skipped++;
        errors.add('Row ${rowIndex + 1}: $email already exists.');
        continue;
      }
      final names = splitFullName(fullName);
      final now = DateTime.now().toUtc();
      final previousPendingIndex = pendingIndexes[identity];
      final current = previousPendingIndex == null
          ? existing
          : writes[previousPendingIndex].contact;
      final emailState = _importEmails(current, email);
      final candidate = Contact(
        id: current?.id ?? '',
        companyId: current?.companyId ?? '',
        firstName: names.firstName,
        lastName: names.lastName,
        emails: emailState.emails,
        primaryEmailId: emailState.primaryEmailId,
        role: hasColumn('Role') ? _blankToNull(cell('Role')) : current?.role,
        source: hasColumn('Event / Source')
            ? _blankToNull(cell('Event / Source'))
            : current?.source,
        linkedinUrl: hasColumn('LinkedIn URL')
            ? _blankToNull(cell('LinkedIn URL'))
            : current?.linkedinUrl,
        segments: hasColumn('Segments')
            ? cell('Segments')
                  .split(RegExp(r'[,;]'))
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toSet()
                  .toList()
            : current?.segments ?? const [],
        canReceiveCampaignEmails:
            emailState.primaryEmailId != null &&
            (hasColumn('Include in email outreach')
                ? _isYes(cell('Include in email outreach'))
                : current?.canReceiveCampaignEmails ?? false),
        createdAt: current?.createdAt ?? now,
        updatedAt: now,
      );
      if (current != null && _sameContactData(current, candidate)) {
        skipped++;
        continue;
      }
      final write = ContactWrite(contact: candidate, companyName: company);
      if (previousPendingIndex == null) {
        pendingIndexes[identity] = writes.length;
        writes.add(write);
      } else {
        writes[previousPendingIndex] = write;
        skipped++;
      }
    }
    if (writes.isEmpty) {
      return ImportResult(imported: 0, skipped: skipped, errors: errors);
    }
    try {
      final result = await _repository.importContacts(writes);
      await reload();
      errors.addAll(
        result.errors.map((error) => 'Row ${error.row}: ${error.message}'),
      );
      return ImportResult(
        imported: result.imported,
        skipped: skipped + result.skipped,
        errors: errors,
      );
    } on Object catch (error) {
      throw StateError(_errorMessage(error));
    }
  }

  String exportCsv() {
    final companyById = {for (final company in companies) company.id: company};
    final rows = <List<String>>[csvHeaders];
    for (final group in visibleGroups) {
      for (final contact in group.contacts) {
        rows.add([
          companyById[contact.companyId]?.name ?? '',
          contact.fullName,
          contact.primaryEmail?.address ?? '',
          contact.role ?? '',
          contact.source ?? '',
          contact.linkedinUrl ?? '',
          contact.segments.join(', '),
          contact.hasPrimaryEmail && contact.canReceiveCampaignEmails
              ? 'Yes'
              : 'No',
        ]);
      }
    }
    return _csv.encode(rows);
  }

  String _id(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';
  String? _blankToNull(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
  bool _isYes(String value) =>
      {'yes', 'true', '1', 'y'}.contains(value.trim().toLowerCase());

  String _contactIdentityKey(Contact contact) {
    final companyName = companies
        .where((company) => company.id == contact.companyId)
        .firstOrNull
        ?.name;
    return _identityKey(companyName ?? contact.companyId, contact.fullName);
  }

  String _identityKey(String companyName, String fullName) =>
      '${_normalizeIdentity(companyName)}\u0000${_normalizeIdentity(fullName)}';

  String _normalizeIdentity(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  _ImportedEmailState _importEmails(Contact? existing, String email) {
    if (email.isEmpty) {
      return _ImportedEmailState(
        emails: existing?.emails ?? const [],
        primaryEmailId: existing?.primaryEmailId,
      );
    }
    final matching = existing?.emails
        .where((item) => normalizeEmail(item.address) == email)
        .firstOrNull;
    if (matching != null) {
      return _ImportedEmailState(
        emails: existing!.emails,
        primaryEmailId: matching.id,
      );
    }
    final added = ContactEmail(id: _id('email'), address: email, label: 'Work');
    return _ImportedEmailState(
      emails: [...?existing?.emails, added],
      primaryEmailId: added.id,
    );
  }

  bool _sameContactData(Contact left, Contact right) {
    String optional(String? value) => _normalizeIdentity(value ?? '');
    List<String> emails(Contact contact) =>
        contact.emails
            .map(
              (email) =>
                  '${normalizeEmail(email.address)}\u0000${optional(email.label)}',
            )
            .toList()
          ..sort();
    List<String> segments(Contact contact) =>
        contact.segments.map(_normalizeIdentity).toList()..sort();

    return optional(left.firstName) == optional(right.firstName) &&
        optional(left.lastName) == optional(right.lastName) &&
        optional(left.role) == optional(right.role) &&
        optional(left.linkedinUrl) == optional(right.linkedinUrl) &&
        optional(left.source) == optional(right.source) &&
        listEquals(emails(left), emails(right)) &&
        listEquals(segments(left), segments(right)) &&
        normalizeEmail(left.primaryEmail?.address ?? '') ==
            normalizeEmail(right.primaryEmail?.address ?? '') &&
        left.canReceiveCampaignEmails == right.canReceiveCampaignEmails;
  }

  String _errorMessage(Object error) {
    final message = error.toString();
    return message
        .replaceFirst('StateError: ', '')
        .replaceFirst('Exception: ', '')
        .replaceFirst(RegExp(r'^\[cloud_functions/[^]]+\]\s*'), '');
  }
}

class _ImportedEmailState {
  const _ImportedEmailState({required this.emails, this.primaryEmailId});
  final List<ContactEmail> emails;
  final String? primaryEmailId;
}

class CompanyContactGroup {
  const CompanyContactGroup({required this.company, required this.contacts});
  final Company company;
  final List<Contact> contacts;
}

enum EmailFilter { all, missing, hasEmail }

class ContactFormValue {
  const ContactFormValue({
    this.companyId,
    required this.companyName,
    required this.fullName,
    required this.emails,
    this.primaryEmailId,
    this.role,
    this.linkedinUrl,
    this.source,
    this.segments = const [],
    this.canReceiveCampaignEmails = false,
  });
  final String? companyId;
  final String companyName;
  final String fullName;
  final List<ContactEmailValue> emails;
  final String? primaryEmailId;
  final String? role;
  final String? linkedinUrl;
  final String? source;
  final List<String> segments;
  final bool canReceiveCampaignEmails;
}

class ContactEmailValue {
  const ContactEmailValue({
    required this.id,
    required this.address,
    this.label,
  });
  final String id;
  final String address;
  final String? label;
}

class ImportResult {
  const ImportResult({
    required this.imported,
    required this.skipped,
    required this.errors,
  });
  final int imported;
  final int skipped;
  final List<String> errors;
}
