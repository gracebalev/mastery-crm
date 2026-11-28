import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/contacts/domain/contact_repository.dart';
import '../features/contacts/presentation/business_card_scanner_page.dart';
import '../features/contacts/presentation/contacts_page.dart';
import '../features/events/domain/event_repository.dart';
import '../features/events/presentation/events_page.dart';
import 'theme/app_theme.dart';
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
  final _contactsKey = GlobalKey<ContactsPageState>();

  bool get _supportsCardScanning =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _scanBusinessCard() async {
    if (!_supportsCardScanning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Business card scanning is available on Android and iOS.',
          ),
        ),
      );
      return;
    }
    final draft = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const BusinessCardScannerPage(),
      ),
    );
    if (!mounted || draft == null) return;
    setState(() => _selected = WorkspaceSection.contacts);
    await _contactsKey.currentState?.openScannedContact(draft);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final content = IndexedStack(
        index: _selected.index,
        children: [
          ContactsPage(
            key: _contactsKey,
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
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: _ScanButton(onPressed: _scanBusinessCard),
          bottomNavigationBar: _MobileNavigation(
            selected: _selected,
            onSelected: (value) => setState(() => _selected = value),
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

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({required this.selected, required this.onSelected});

  final WorkspaceSection selected;
  final ValueChanged<WorkspaceSection> onSelected;

  @override
  Widget build(BuildContext context) => BottomAppBar(
    height: 76,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    shape: const CircularNotchedRectangle(),
    notchMargin: 9,
    child: Row(
      children: [
        Expanded(
          child: _MobileNavItem(
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
            label: 'Contacts',
            selected: selected == WorkspaceSection.contacts,
            onTap: () => onSelected(WorkspaceSection.contacts),
          ),
        ),
        const SizedBox(width: 88),
        Expanded(
          child: _MobileNavItem(
            icon: Icons.event_outlined,
            selectedIcon: Icons.event,
            label: 'Events',
            selected: selected == WorkspaceSection.events,
            onTap: () => onSelected(WorkspaceSection.events),
          ),
        ),
      ],
    ),
  );
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          selected ? selectedIcon : icon,
          color: selected ? brandPurple : mutedInk,
          size: 23,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: selected ? brandPurple : mutedInk,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 72,
    child: FloatingActionButton(
      tooltip: 'Scan business card',
      onPressed: onPressed,
      elevation: 8,
      backgroundColor: brandPurple,
      foregroundColor: Colors.white,
      shape: const CircleBorder(),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.document_scanner_outlined, size: 27),
          SizedBox(height: 2),
          Text(
            'SCAN',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    ),
  );
}
