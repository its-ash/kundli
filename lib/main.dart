import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import 'app/app_model.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final model = await AppModel.load();
  runApp(KundliApp(model: model));
}

class KundliApp extends StatelessWidget {
  const KundliApp({super.key, required this.model});

  final AppModel model;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      model: model,
      child: UiApp(
        title: 'Kundli',
        accent: const Color(0xFF5B3FA6), // deep indigo
        home: const HomeScreen(),
      ),
    );
  }
}
