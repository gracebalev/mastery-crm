import 'package:material_ui/material_ui.dart';

import '../features/contacts/domain/contact_repository.dart';
import '../features/contacts/presentation/contacts_page.dart';
import '../features/auth/presentation/auth_gate.dart';
import 'theme/app_theme.dart';

class MasteryEmailApp extends StatelessWidget {
  const MasteryEmailApp({super.key, required this.repository});
  final ContactRepository repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mastery Email',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: AuthGate(child: ContactsPage(repository: repository)),
  );
}
