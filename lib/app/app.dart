import 'package:material_ui/material_ui.dart';

import '../features/contacts/domain/contact_repository.dart';
import '../features/events/domain/event_repository.dart';
import '../features/auth/presentation/auth_gate.dart';
import 'theme/app_theme.dart';
import 'workspace_home.dart';

class MasteryEmailApp extends StatelessWidget {
  const MasteryEmailApp({
    super.key,
    required this.contactRepository,
    required this.eventRepository,
  });
  final ContactRepository contactRepository;
  final EventRepository eventRepository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mastery CRM',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: AuthGate(
      child: WorkspaceHome(
        contactRepository: contactRepository,
        eventRepository: eventRepository,
      ),
    ),
  );
}
