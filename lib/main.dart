import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/public_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/user_home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es', null);
  await dotenv.load(fileName: ".env");

  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: !kIsWeb,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // NUEVA PALETA: DARK & NEON
    const Color bgDark = Color(0xFF090E17); // Azul medianoche casi negro
    const Color neonMint = Color(0xFF00E5FF); // Cian/Menta Neón vibrante
    const Color darkSurface = Color(0xFF151D2A); // Color para tarjetas oscuras

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agua Potable',
      theme: ThemeData(
        brightness: Brightness.dark, // FORZAMOS EL MODO OSCURO
        useMaterial3: true,
        scaffoldBackgroundColor: bgDark,
        
        colorScheme: const ColorScheme.dark(
          primary: neonMint,
          secondary: Color(0xFF00FF9D), // Verde esmeralda neón
          surface: darkSurface,
          onSurface: Colors.white,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),

        // Botones globales brillantes para contrastar con el fondo oscuro
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: neonMint,
            foregroundColor: Colors.black, // Texto negro sobre botón neón resalta súper bien
            shadowColor: neonMint.withOpacity(0.5),
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        // Inputs estilo Dark Glass
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: neonMint, width: 2),
          ),
          prefixIconColor: neonMint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        ),
      ),

      home: const PublicHomeScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/user_home': (context) => UserHomeScreen(),
      },
    );
  }
}