import 'entities.dart';

abstract interface class ContactRepository {
  List<Company> getCompanies();
  List<Contact> getContacts();
  Company saveCompany(Company company);
  Contact saveContact(Contact contact);
  void deleteContact(String contactId);
}
