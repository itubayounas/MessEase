import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mess_ease/screens/auth_wrapper.dart';
import 'firebase_options.dart';
// import 'screens/login_page.dart';

void main() async {
  // Firebase needs this before we touch any Firebase service.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MessEaseApp());
}

class MessEaseApp extends StatelessWidget {
  const MessEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MessEase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: AuthWrapper(),
    );
  }
}