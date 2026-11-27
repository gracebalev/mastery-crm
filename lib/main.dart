import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'core/storage/key_value_store.dart';
import 'features/contacts/data/local_contact_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MasteryEmailApp(repository: LocalContactRepository(createKeyValueStore())),
  );
}
