import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
// 1. IMPORTAMOS EL SERVICIO DE NOTIFICACIONES
import '../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      // 1. Autenticación con Firebase Auth
      UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Obtener datos del usuario desde Firestore
      var userDoc = await _dbService.obtenerUsuario(cred.user!.uid);

      // 3. Verificar si es Admin
      if (userDoc != null && userDoc.rol == 'admin') {
        
        // --- CÓDIGO NUEVO PARA NOTIFICACIONES ---
        // Si es admin, guardamos su Token en la base de datos
        try {
          NotificationService notifService = NotificationService();
          await notifService.uploadTokenForUser(cred.user!.uid);
          print("Token de admin actualizado correctamente");
        } catch (e) {
          print("Error al guardar token (pero dejamos pasar al admin): $e");
        }
        // ----------------------------------------

        // 4. Navegar al Dashboard
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
        
      } else {
        // Si entra pero no es admin, lo sacamos (opcionalmente hacemos logout)
        await FirebaseAuth.instance.signOut(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No tienes permisos de administrador"))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Acceso Administrativo")),
      body: Center(
        child: Container(
          width: 350,
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Login Admin", style: TextStyle(fontSize: 24)),
              SizedBox(height: 20),
              TextField(
                controller: _emailController, 
                decoration: InputDecoration(labelText: "Email")
              ),
              SizedBox(height: 10), // Un poco de espacio extra
              TextField(
                controller: _passwordController, 
                decoration: InputDecoration(labelText: "Contraseña"), 
                obscureText: true
              ),
              SizedBox(height: 20),
              _isLoading 
                ? CircularProgressIndicator() 
                : ElevatedButton(
                    onPressed: _login, 
                    child: Text("Ingresar")
                  ),
            ],
          ),
        ),
      ),
    );
  }
}