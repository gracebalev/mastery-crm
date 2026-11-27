import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_theme.dart';
import '../../contacts/domain/contact_repository.dart';
import '../../contacts/domain/entities.dart';
import '../../contacts/presentation/contact_controller.dart';
import '../../contacts/presentation/contact_dialog.dart';
import '../domain/event.dart';
import '../domain/event_repository.dart';
import 'event_controller.dart';
import 'event_dialog.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({
    super.key,
    required this.contactRepository,
    required this.eventRepository,
  });

  final ContactRepository contactRepository;
  final EventRepository eventRepository;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late final EventController _controller;
  late final ContactController _contactController;
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _controller = EventController(
      widget.eventRepository,
      widget.contactRepository,
    );
    _contactController = ContactController(
      widget.contactRepository,
      eventRepository: widget.eventRepository,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth < 1080 ? 1080 : constraints.maxWidth,
            height: constraints.maxHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 34, 40, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 26),
                  _toolbar(),
                  const SizedBox(height: 26),
                  Expanded(child: _body()),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _header() => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Events', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            const Text(
              'Track the events where your contacts were discovered',
              style: TextStyle(color: mutedInk),
            ),
          ],
        ),
      ),
      ElevatedButton.icon(
        onPressed: () =>
            showEventDialog(context: context, controller: _controller),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('New event'),
      ),
    ],
  );

  Widget _toolbar() => Container(
    height: 68,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 360,
          child: TextField(
            onChanged: _controller.setSearch,
            decoration: const InputDecoration(
              hintText: 'Search events',
              prefixIcon: Icon(Icons.search, size: 19),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Color(0xFFF7F6F9),
            ),
          ),
        ),
        const Spacer(),
        _filterChip('All events', EventFilter.all),
        const SizedBox(width: 8),
        _filterChip('Upcoming', EventFilter.upcoming),
        const SizedBox(width: 8),
        _filterChip('Past', EventFilter.past),
      ],
    ),
  );

  Widget _filterChip(String label, EventFilter value) {
    final selected = _controller.filter == value;
    return InkWell(
      onTap: () => _controller.setFilter(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFE8FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? brandPurple : mutedInk,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_controller.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _controller.reload,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    final events = _controller.visibleEvents;
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'No events match this search.',
          style: TextStyle(color: mutedInk),
        ),
      );
    }
    return Column(
      children: [
        const _EventColumnHeaders(),
        const SizedBox(height: 9),
        Expanded(
          child: ListView.separated(
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final event = events[index];
              return _EventCard(
                event: event,
                contacts: _controller.contactsFor(event.id),
                companyName: _controller.companyName,
                expanded: _expanded.contains(event.id),
                onToggle: () => setState(() {
                  if (!_expanded.add(event.id)) _expanded.remove(event.id);
                }),
                onEditEvent: () => showEventDialog(
                  context: context,
                  controller: _controller,
                  event: event,
                ),
                onDeleteEvent: () => _confirmDelete(event),
                onCreateContact: () => _createContact(event),
                onLinkContact: () => _linkExisting(event),
                onEditContact: (contact) async {
                  final changed = await showContactDialog(
                    context: context,
                    controller: _contactController,
                    contact: contact,
                  );
                  if (changed) await _controller.reload();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _createContact(MasteryEvent event) async {
    await _contactController.reload();
    if (!mounted) return;
    final changed = await showContactDialog(
      context: context,
      controller: _contactController,
      initialEventId: event.id,
    );
    if (changed) await _controller.reload();
  }

  Future<void> _linkExisting(MasteryEvent event) async {
    await _contactController.reload();
    if (!mounted) return;
    final available = _contactController.contacts
        .where((contact) => contact.sourceEventId != event.id)
        .toList();
    final selected = await showDialog<Contact>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link existing contact'),
        content: SizedBox(
          width: 520,
          height: 420,
          child: available.isEmpty
              ? const Center(child: Text('All contacts are already linked.'))
              : ListView.separated(
                  itemCount: available.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final contact = available[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(_initials(contact.fullName)),
                      ),
                      title: Text(contact.fullName),
                      subtitle: Text(
                        '${_contactController.companies.where((item) => item.id == contact.companyId).firstOrNull?.name ?? ''} · ${contact.primaryEmail?.address ?? 'No email'}',
                      ),
                      trailing: const Icon(Icons.link),
                      onTap: () => Navigator.pop(context, contact),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (selected == null) return;
    await _contactController.assignEvent(selected, event.id);
    await _controller.reload();
  }

  Future<void> _confirmDelete(MasteryEvent event) async {
    final count = _controller.contactsFor(event.id).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text(
          count == 0
              ? 'The event will be permanently deleted.'
              : '$count linked contacts will be kept and unlinked from this event.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _controller.delete(event);
  }

  String _initials(String name) => name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}

class _EventColumnHeaders extends StatelessWidget {
  const _EventColumnHeaders();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 18),
    child: Row(
      children: [
        SizedBox(width: 86),
        Expanded(flex: 3, child: _ColumnHeader('EVENT')),
        Expanded(flex: 2, child: _ColumnHeader('DATES')),
        Expanded(flex: 2, child: _ColumnHeader('DURATION')),
        Expanded(flex: 2, child: _ColumnHeader('LOCATION')),
        Expanded(flex: 2, child: _ColumnHeader('CONTACTS')),
        SizedBox(width: 48, child: _ColumnHeader('ACTIONS')),
      ],
    ),
  );
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      color: mutedInk,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.contacts,
    required this.companyName,
    required this.expanded,
    required this.onToggle,
    required this.onEditEvent,
    required this.onDeleteEvent,
    required this.onCreateContact,
    required this.onLinkContact,
    required this.onEditContact,
  });

  final MasteryEvent event;
  final List<Contact> contacts;
  final String Function(String) companyName;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onEditEvent;
  final VoidCallback onDeleteEvent;
  final VoidCallback onCreateContact;
  final VoidCallback onLinkContact;
  final ValueChanged<Contact> onEditContact;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(expanded ? Icons.expand_more : Icons.chevron_right),
                const SizedBox(width: 12),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFE8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_outlined,
                    color: brandPurple,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (event.notes != null)
                        Text(
                          event.notes!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: mutedInk, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(_dateRange(event.startDate, event.endDate)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(_duration(event.startDate, event.endDate)),
                ),
                Expanded(flex: 2, child: Text(event.location ?? '—')),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${contacts.length} ${contacts.length == 1 ? 'contact' : 'contacts'}',
                    style: const TextStyle(
                      color: brandPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      value == 'edit' ? onEditEvent() : onDeleteEvent(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              children: [
                const Text(
                  'SOURCE CONTACTS',
                  style: TextStyle(
                    fontSize: 10,
                    color: mutedInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onLinkContact,
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('Link existing'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onCreateContact,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create contact'),
                ),
              ],
            ),
          ),
          if (contacts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'No contacts linked to this event yet.',
                style: TextStyle(color: mutedInk),
              ),
            )
          else
            ...contacts.map(
              (contact) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 22),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFEFE8FF),
                  child: Text(
                    _initials(contact.fullName),
                    style: const TextStyle(fontSize: 10, color: brandPurple),
                  ),
                ),
                title: Text(
                  contact.fullName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(contact.primaryEmail?.address ?? 'No email'),
                trailing: SizedBox(
                  width: 420,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          companyName(contact.companyId),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          contact.role ?? '—',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit contact',
                        onPressed: () => onEditContact(contact),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    ),
  );

  static String _dateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) return 'No dates';
    if (startDate == null) return 'Until ${_date(endDate!)}';
    if (endDate == null || _sameDay(startDate, endDate)) {
      return _date(startDate);
    }
    return '${_date(startDate)} – ${_date(endDate)}';
  }

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  static String _duration(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null || endDate.isBefore(startDate)) {
      return '—';
    }
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final days = end.difference(start).inDays + 1;
    return '$days ${days == 1 ? 'day' : 'days'}';
  }

  static bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  static String _initials(String name) => name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}
