import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:me_chat/firebase_options.dart';
import 'package:me_chat/screens/home_screen.dart';
import 'package:me_chat/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
      url: 'https://gnnoapjvrhokojizadzq.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdubm9hcGp2cmhva29qaXphZHpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ2NDg3OTMsImV4cCI6MjA2MDIyNDc5M30.gtxyfdMTDraXjrJZwfWqtQFzt8frkctvG_6pszIhiVc',
      storageOptions: StorageClientOptions(retryAttempts: 10));
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: AppBarTheme(
                iconTheme: IconThemeData(color: Colors.black),
                backgroundColor: Colors.white,
                centerTitle: true,
                elevation: 0.5,
                titleTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black)),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
                shape: CircleBorder())),
        home: (FirebaseAuth.instance.currentUser != null)
            ? HomeScreen()
            : LoginScreen(),
      ),
    ),
  );
}
