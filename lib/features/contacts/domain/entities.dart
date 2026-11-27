class Company {
  const Company({
    required this.id,
    required this.name,
    this.domain,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id;
  final String name;
  final String? domain;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ContactEmail {
  const ContactEmail({required this.id, required this.address, this.label});
  final String id;
  final String address;
  final String? label;
}

class Contact {
  const Contact({
    required this.id,
    required this.companyId,
    required this.firstName,
    required this.lastName,
    required this.emails,
    required this.primaryEmailId,
    this.role,
    this.linkedinUrl,
    this.source,
    this.segments = const [],
    this.canReceiveCampaignEmails = false,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id;
  final String companyId;
  final String firstName;
  final String lastName;
  final List<ContactEmail> emails;
  final String primaryEmailId;
  final String? role;
  final String? linkedinUrl;
  final String? source;
  final List<String> segments;
  final bool canReceiveCampaignEmails;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName'.trim();
  ContactEmail get primaryEmail =>
      emails.singleWhere((email) => email.id == primaryEmailId);
}

String normalizeEmail(String value) => value.trim().toLowerCase();

({String firstName, String lastName}) splitFullName(String value) {
  final parts = value.trim().split(RegExp(r'\s+'));
  return (
    firstName: parts.isEmpty ? '' : parts.first,
    lastName: parts.length > 1 ? parts.skip(1).join(' ') : '',
  );
}
