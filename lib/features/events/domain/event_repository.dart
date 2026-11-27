import 'event.dart';

abstract interface class EventRepository {
  Future<List<MasteryEvent>> loadEvents();
  Future<String> saveEvent(MasteryEvent event);
  Future<void> deleteEvent(String eventId);
}
