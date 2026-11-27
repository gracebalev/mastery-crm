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
              .where((contact) {
                if (activeQuery.isNotEmpty &&
                    !_includes(company.name, activeQuery) &&
                    !_includes(contact.fullName, activeQuery) &&
                    !_includes(contact.primaryEmail.address, activeQuery)) {
                  return false;
                }
                return _matchesFilter('Company', company.name) &&
                    _matchesFilter(
                      'Contact',
                      '${contact.fullName} ${contact.primaryEmail.address}',
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
                  hasColumnFilters) &&
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
              item.name.trim().toLowerCase() ==
              value.companyName.trim().toLowerCase(),
        )
        .firstOrNull;
    final names = splitFullName(value.fullName);
    final contact = Contact(
      id: existing?.id ?? '',
      companyId: company?.id ?? '',
      firstName: names.firstName,
      lastName: names.lastName,
      emails: value.emails
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
      canReceiveCampaignEmails: value.canReceiveCampaignEmails,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      final saved = await _repository.saveContact(
        ContactWrite(contact: contact, companyName: value.companyName.trim()),
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
        .take(3)
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
    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      String cell(String name) {
        final index = indexes[name.toLowerCase()];
        return index == null || index >= row.length ? '' : row[index].trim();
      }

      final company = cell('Company');
      final fullName = cell('Full name');
      final email = normalizeEmail(cell('Primary email'));
      if (company.isEmpty || fullName.isEmpty || email.isEmpty) {
        skipped++;
        errors.add(
          'Row ${rowIndex + 1}: Company, Full name and Primary email are required.',
        );
        continue;
      }
      if (contacts.any(
        (contact) =>
            contact.emails.any((item) => normalizeEmail(item.address) == email),
      )) {
        skipped++;
        errors.add('Row ${rowIndex + 1}: $email already exists.');
        continue;
      }
      final emailId = _id('email');
      final names = splitFullName(fullName);
      final now = DateTime.now().toUtc();
      writes.add(
        ContactWrite(
          companyName: company,
          contact: Contact(
            id: '',
            companyId: '',
            firstName: names.firstName,
            lastName: names.lastName,
            emails: [ContactEmail(id: emailId, address: email, label: 'Work')],
            primaryEmailId: emailId,
            role: _blankToNull(cell('Role')),
            source: _blankToNull(cell('Event / Source')),
            linkedinUrl: _blankToNull(cell('LinkedIn URL')),
            segments: cell('Segments')
                .split(RegExp(r'[,;]'))
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toSet()
                .toList(),
            canReceiveCampaignEmails: _isYes(cell('Include in email outreach')),
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );
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
          contact.primaryEmail.address,
          contact.role ?? '',
          contact.source ?? '',
          contact.linkedinUrl ?? '',
          contact.segments.join(', '),
          contact.canReceiveCampaignEmails ? 'Yes' : 'No',
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

  String _errorMessage(Object error) {
    final message = error.toString();
    return message
        .replaceFirst('StateError: ', '')
        .replaceFirst('Exception: ', '')
        .replaceFirst(RegExp(r'^\[cloud_functions/[^]]+\]\s*'), '');
  }
}

class CompanyContactGroup {
  const CompanyContactGroup({required this.company, required this.contacts});
  final Company company;
  final List<Contact> contacts;
}

class ContactFormValue {
  const ContactFormValue({
    this.companyId,
    required this.companyName,
    required this.fullName,
    required this.emails,
    required this.primaryEmailId,
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
  final String primaryEmailId;
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
