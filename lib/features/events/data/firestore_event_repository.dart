import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/event.dart';
import '../domain/event_repository.dart';

class FirestoreEventRepository implements EventRepository {
  FirestoreEventRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('events');

  @override
  Future<List<MasteryEvent>> loadEvents() async {
    final snapshot = await _events.get();
    final events = snapshot.docs.map(_fromDocument).toList()
      ..sort((a, b) {
        if (a.date == null && b.date == null) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return b.date!.compareTo(a.date!);
      });
    return events;
  }

  @override
  Future<String> saveEvent(MasteryEvent event) async {
    final name = event.name.trim();
    if (name.isEmpty) throw StateError('Event name is required.');
    final reference = event.id.isEmpty ? _events.doc() : _events.doc(event.id);
    final existing = await reference.get();
    final now = FieldValue.serverTimestamp();
    await reference.set({
      'name': name,
      'normalizedName': name.toLowerCase(),
      'date': event.date == null ? null : Timestamp.fromDate(event.date!),
      'location': event.location ?? '',
      'websiteUrl': event.websiteUrl ?? '',
      'notes': event.notes ?? '',
      'createdAt': existing.data()?['createdAt'] ?? now,
      'updatedAt': now,
    });
    return reference.id;
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    final linked = await _firestore
        .collection('contacts')
        .where('sourceEventId', isEqualTo: eventId)
        .get();
    final batch = _firestore.batch();
    for (final document in linked.docs) {
      batch.update(document.reference, {
        'sourceEventId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    batch.delete(_events.doc(eventId));
    await batch.commit();
  }

  MasteryEvent _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return MasteryEvent(
      id: document.id,
      name: data['name'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate(),
      location: _optional(data['location']),
      websiteUrl: _optional(data['websiteUrl']),
      notes: _optional(data['notes']),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  String? _optional(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  DateTime _date(Object? value) => value is Timestamp
      ? value.toDate()
      : DateTime.fromMillisecondsSinceEpoch(0);
}
