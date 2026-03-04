import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/public_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('es', null);

  // Configuración Offline
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agua Potable',
      // --- TEMA TURQUESA (CLEAN WATER) ---
      theme: ThemeData(
        useMaterial3: true,
        // Definimos la semilla de color Turquesa
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B), // Color Principal (Turquesa)
          primary: const Color(0xFF00695C),   // Turquesa Oscuro
          secondary: const Color(0xFF4DB6AC), // Turquesa Claro
          surface: const Color(0xFFF5F7FA),   // Fondo gris muy suave
          background: const Color(0xFFF5F7FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        
        // Estilo de los AppBar (Barra superior)
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00796B),
          foregroundColor: Colors.white, // Texto blanco
          centerTitle: true,
          elevation: 2,
        ),

        // Estilo de Botones (Rellenos)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00796B), // Fondo Turquesa
            foregroundColor: Colors.white, // Letra Blanca
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        
        // Estilo de Inputs (Cajas de texto)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
          ),
          prefixIconColor: const Color(0xFF00796B),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      // -----------------------------------
      
      home: PublicHomeScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/admin_dashboard': (context) => AdminDashboard(),
      },
    );
  }
}