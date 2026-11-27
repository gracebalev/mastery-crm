import 'package:material_ui/material_ui.dart';

import '../features/contacts/domain/contact_repository.dart';
import '../features/contacts/presentation/contacts_page.dart';
import '../features/events/domain/event_repository.dart';
import '../features/events/presentation/events_page.dart';
import 'workspace_sidebar.dart';

class WorkspaceHome extends StatefulWidget {
  const WorkspaceHome({
    super.key,
    required this.contactRepository,
    required this.eventRepository,
  });

  final ContactRepository contactRepository;
  final EventRepository eventRepository;

  @override
  State<WorkspaceHome> createState() => _WorkspaceHomeState();
}

class _WorkspaceHomeState extends State<WorkspaceHome> {
  var _selected = WorkspaceSection.contacts;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        WorkspaceSidebar(
          selected: _selected,
          onSelected: (value) => setState(() => _selected = value),
        ),
        Expanded(
          child: IndexedStack(
            index: _selected.index,
            children: [
              ContactsPage(
                repository: widget.contactRepository,
                eventRepository: widget.eventRepository,
              ),
              EventsPage(
                contactRepository: widget.contactRepository,
                eventRepository: widget.eventRepository,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
