class MasteryEvent {
  const MasteryEvent({
    required this.id,
    required this.name,
    this.date,
    this.location,
    this.websiteUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final DateTime? date;
  final String? location;
  final String? websiteUrl;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}
