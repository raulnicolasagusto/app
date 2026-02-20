import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';

import 'src/app_theme.dart';
import 'src/home_screen.dart';
import 'src/math_canvas_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MathFightApp());
}

class MathFightApp extends StatelessWidget {
  const MathFightApp({super.key});

  static const String homeRoute = '/home';
  static const String quickTestRoute = '/quick-test';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Fight',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      initialRoute: homeRoute,
      routes: <String, WidgetBuilder>{
        homeRoute: (BuildContext context) => const HomeScreen(),
        quickTestRoute: (BuildContext context) => const MathCanvasScreen(),
      },
    );
  }
}
