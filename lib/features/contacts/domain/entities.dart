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
    this.primaryEmailId,
    this.role,
    this.linkedinUrl,
    this.sourceEventId,
    String? source,
    String? sourceNote,
    this.segments = const [],
    this.canReceiveCampaignEmails = false,
    required this.createdAt,
    required this.updatedAt,
  }) : sourceNote = sourceNote ?? source;
  final String id;
  final String companyId;
  final String firstName;
  final String lastName;
  final List<ContactEmail> emails;
  final String? primaryEmailId;
  final String? role;
  final String? linkedinUrl;
  final String? sourceEventId;
  final String? sourceNote;
  String? get source => sourceNote;
  final List<String> segments;
  final bool canReceiveCampaignEmails;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName'.trim();
  ContactEmail? get primaryEmail {
    for (final email in emails) {
      if (email.id == primaryEmailId) return email;
    }
    return null;
  }

  bool get hasPrimaryEmail => primaryEmail != null;

  Contact copyWith({String? sourceEventId}) => Contact(
    id: id,
    companyId: companyId,
    firstName: firstName,
    lastName: lastName,
    emails: emails,
    primaryEmailId: primaryEmailId,
    role: role,
    linkedinUrl: linkedinUrl,
    sourceEventId: sourceEventId ?? this.sourceEventId,
    sourceNote: sourceNote,
    segments: segments,
    canReceiveCampaignEmails: canReceiveCampaignEmails,
    createdAt: createdAt,
    updatedAt: DateTime.now().toUtc(),
  );
}

String normalizeEmail(String value) => value.trim().toLowerCase();

({String firstName, String lastName}) splitFullName(String value) {
  final parts = value.trim().split(RegExp(r'\s+'));
  return (
    firstName: parts.isEmpty ? '' : parts.first,
    lastName: parts.length > 1 ? parts.skip(1).join(' ') : '',
  );
}
