import 'package:flutter/foundation.dart';

import '../../contacts/domain/contact_repository.dart';
import '../../contacts/domain/entities.dart';
import '../domain/event.dart';
import '../domain/event_repository.dart';

class EventController extends ChangeNotifier {
  EventController(this._eventRepository, this._contactRepository) {
    reload();
  }

  final EventRepository _eventRepository;
  final ContactRepository _contactRepository;

  List<MasteryEvent> events = [];
  List<Contact> contacts = [];
  List<Company> companies = [];
  bool isLoading = true;
  String? error;
  String search = '';
  EventFilter filter = EventFilter.all;

  Future<void> reload() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _eventRepository.loadEvents(),
        _contactRepository.load(),
      ]);
      events = results[0] as List<MasteryEvent>;
      final directory = results[1] as ContactDirectory;
      contacts = directory.contacts;
      companies = directory.companies;
    } on Object catch (exception) {
      error = exception.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<MasteryEvent> get visibleEvents {
    final query = search.trim().toLowerCase();
    final today = DateTime.now();
    return events.where((event) {
      final matchesSearch =
          query.isEmpty ||
          '${event.name} ${event.location ?? ''} ${event.notes ?? ''}'
              .toLowerCase()
              .contains(query);
      final matchesFilter = switch (filter) {
        EventFilter.all => true,
        EventFilter.upcoming =>
          _eventEnd(event) == null ||
              !_eventEnd(event)!.isBefore(_startOfDay(today)),
        EventFilter.past =>
          _eventEnd(event) != null &&
              _eventEnd(event)!.isBefore(_startOfDay(today)),
      };
      return matchesSearch && matchesFilter;
    }).toList();
  }

  List<Contact> contactsFor(String eventId) =>
      contacts.where((contact) => contact.sourceEventId == eventId).toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));

  String companyName(String companyId) =>
      companies.where((company) => company.id == companyId).firstOrNull?.name ??
      'Unknown company';

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  void setFilter(EventFilter value) {
    filter = value;
    notifyListeners();
  }

  Future<void> save(EventFormValue value, {MasteryEvent? existing}) async {
    final now = DateTime.now().toUtc();
    await _eventRepository.saveEvent(
      MasteryEvent(
        id: existing?.id ?? '',
        name: value.name.trim(),
        startDate: value.startDate,
        endDate: value.endDate,
        location: _optional(value.location),
        websiteUrl: _optional(value.websiteUrl),
        notes: _optional(value.notes),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    await reload();
  }

  Future<void> delete(MasteryEvent event) async {
    await _eventRepository.deleteEvent(event.id);
    await reload();
  }

  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime? _eventEnd(MasteryEvent event) => event.endDate ?? event.startDate;
}

enum EventFilter { all, upcoming, past }

class EventFormValue {
  const EventFormValue({
    required this.name,
    this.startDate,
    this.endDate,
    required this.location,
    required this.websiteUrl,
    required this.notes,
  });

  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final String location;
  final String websiteUrl;
  final String notes;
}
