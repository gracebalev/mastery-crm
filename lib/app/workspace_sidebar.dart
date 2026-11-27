import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'theme/app_theme.dart';

enum WorkspaceSection { contacts, events }

class WorkspaceSidebar extends StatelessWidget {
  const WorkspaceSidebar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final WorkspaceSection selected;
  final ValueChanged<WorkspaceSection> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    width: 232,
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: brandPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'M',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'mastery',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  'EMAIL STUDIO',
                  style: TextStyle(
                    fontSize: 9,
                    color: brandPurple,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 34),
        const Text(
          'WORKSPACE',
          style: TextStyle(
            color: mutedInk,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        const _NavItem(icon: Icons.home_outlined, label: 'Overview'),
        _NavItem(
          icon: Icons.radio_button_checked,
          label: 'Contacts',
          enabled: true,
          selected: selected == WorkspaceSection.contacts,
          onTap: () => onSelected(WorkspaceSection.contacts),
        ),
        _NavItem(
          icon: Icons.calendar_today_outlined,
          label: 'Events',
          enabled: true,
          selected: selected == WorkspaceSection.events,
          onTap: () => onSelected(WorkspaceSection.events),
        ),
        const _NavItem(icon: Icons.diamond_outlined, label: 'Templates'),
        const _NavItem(icon: Icons.north_east, label: 'Campaigns'),
        const _NavItem(
          icon: Icons.auto_awesome_outlined,
          label: 'Brand settings',
        ),
        const Spacer(),
        Opacity(
          opacity: 0.35,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFE8FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly sends',
                  style: TextStyle(color: brandPurple, fontSize: 11),
                ),
                SizedBox(height: 8),
                Text('0 / 10,000'),
                SizedBox(height: 8),
                LinearProgressIndicator(value: 0, minHeight: 5),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFFFF3D6),
              child: Text('AM', style: TextStyle(fontSize: 11, color: ink)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FirebaseAuth.instance.currentUser?.displayName ??
                        'Mastery Admin',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: mutedInk),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Sign out',
              onPressed: FirebaseAuth.instance.signOut,
              icon: const Icon(Icons.logout, size: 18),
            ),
          ],
        ),
      ],
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.enabled = false,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : 0.32,
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF4EFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: selected ? brandPurple : mutedInk),
            const SizedBox(width: 11),
            Text(
              label,
              style: TextStyle(
                color: selected ? ink : mutedInk,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
