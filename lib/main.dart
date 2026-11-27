import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'features/contacts/data/firestore_contact_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  await FirebaseAuth.instance.signInAnonymously();
  runApp(MasteryEmailApp(repository: FirestoreContactRepository()));
}
