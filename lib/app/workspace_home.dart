import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final content = IndexedStack(
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
      );
      if (constraints.maxWidth < 800) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mastery CRM'),
            actions: [
              IconButton(
                tooltip: 'Sign out',
                onPressed: FirebaseAuth.instance.signOut,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selected.index,
            onDestinationSelected: (index) =>
                setState(() => _selected = WorkspaceSection.values[index]),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Contacts',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_outlined),
                selectedIcon: Icon(Icons.event),
                label: 'Events',
              ),
            ],
          ),
        );
      }
      return Scaffold(
        body: Row(
          children: [
            WorkspaceSidebar(
              selected: _selected,
              onSelected: (value) => setState(() => _selected = value),
            ),
            Expanded(child: content),
          ],
        ),
      );
    },
  );
}
