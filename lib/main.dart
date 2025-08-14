import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:me_chat/firebase_options.dart';
import 'package:me_chat/screens/splash_screen.dart';
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
          debugShowCheckedModeBanner: false, home: AnimationScreen()),
    ),
  );
}
