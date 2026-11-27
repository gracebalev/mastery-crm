import 'package:flutter_test/flutter_test.dart';
import 'package:mastery_email/features/contacts/domain/contact_repository.dart';
import 'package:mastery_email/features/contacts/domain/entities.dart';
import 'package:mastery_email/features/events/domain/event.dart';
import 'package:mastery_email/features/events/domain/event_repository.dart';
import 'package:mastery_email/features/events/presentation/event_controller.dart';

void main() {
  test('an event exposes the contacts linked through sourceEventId', () async {
    final now = DateTime.utc(2026, 11, 28);
    final event = MasteryEvent(
      id: 'event-1',
      name: 'Warsaw Growth Summit',
      createdAt: now,
      updatedAt: now,
    );
    final controller = EventController(
      _MemoryEventRepository([event]),
      _MemoryContactRepository(
        ContactDirectory(
          companies: [
            Company(
              id: 'company-1',
              name: 'Northstar',
              createdAt: now,
              updatedAt: now,
            ),
          ],
          contacts: [
            Contact(
              id: 'linked',
              companyId: 'company-1',
              firstName: 'Anna',
              lastName: 'Kowalska',
              emails: const [],
              sourceEventId: 'event-1',
              createdAt: now,
              updatedAt: now,
            ),
            Contact(
              id: 'other',
              companyId: 'company-1',
              firstName: 'Grace',
              lastName: 'Smith',
              emails: const [],
              createdAt: now,
              updatedAt: now,
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.contactsFor('event-1').single.id, 'linked');
    controller.dispose();
  });

  test('only an event name is required when saving', () async {
    final events = _MemoryEventRepository([]);
    final controller = EventController(
      events,
      _MemoryContactRepository(
        const ContactDirectory(companies: [], contacts: []),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    await controller.save(
      const EventFormValue(
        name: 'Web Summit',
        location: '',
        websiteUrl: '',
        notes: '',
      ),
    );

    expect(events.saved.single.name, 'Web Summit');
    expect(events.saved.single.date, isNull);
    controller.dispose();
  });
}

class _MemoryEventRepository implements EventRepository {
  _MemoryEventRepository(this.events);
  final List<MasteryEvent> events;
  final List<MasteryEvent> saved = [];

  @override
  Future<List<MasteryEvent>> loadEvents() async => [...events];

  @override
  Future<String> saveEvent(MasteryEvent event) async {
    saved.add(event);
    events.add(event);
    return event.id.isEmpty ? 'event-new' : event.id;
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    events.removeWhere((event) => event.id == eventId);
  }
}

class _MemoryContactRepository implements ContactRepository {
  _MemoryContactRepository(this.directory);
  final ContactDirectory directory;

  @override
  Future<ContactDirectory> load() async => directory;

  @override
  Future<void> deleteContact(String contactId) async {}

  @override
  Future<ImportSummary> importContacts(List<ContactWrite> contacts) async =>
      const ImportSummary(imported: 0, skipped: 0, errors: []);

  @override
  Future<SavedContactReference> saveContact(ContactWrite contact) async =>
      SavedContactReference(
        id: contact.contact.id,
        companyId: contact.contact.companyId,
      );
}
