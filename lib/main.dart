import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/shopping_list_screen.dart'; // Import screen yang sudah dipisah

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Mengatur Status Bar agar transparan dan ikon berwarna gelap/terang sesuai kebutuhan
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // Icon putih untuk header gelap
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShopMaster Pro',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5), // Indigo Professional
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6), // Cool Grey Background
        fontFamily: 'Roboto', 
      ),
      home: const ShoppingListScreen(),
    );
  }
}