import 'entities.dart';

abstract interface class ContactRepository {
  Future<ContactDirectory> load();
  Future<SavedContactReference> saveContact(ContactWrite contact);
  Future<void> deleteContact(String contactId);
  Future<ImportSummary> importContacts(List<ContactWrite> contacts);
}

class ContactDirectory {
  const ContactDirectory({required this.companies, required this.contacts});
  final List<Company> companies;
  final List<Contact> contacts;
}

class ContactWrite {
  const ContactWrite({required this.contact, required this.companyName});
  final Contact contact;
  final String companyName;
}

class SavedContactReference {
  const SavedContactReference({required this.id, required this.companyId});
  final String id;
  final String companyId;
}

class ImportSummary {
  const ImportSummary({
    required this.imported,
    required this.skipped,
    required this.errors,
  });
  final int imported;
  final int skipped;
  final List<ImportFailure> errors;
}

class ImportFailure {
  const ImportFailure({required this.row, required this.message});
  final int row;
  final String message;
}
