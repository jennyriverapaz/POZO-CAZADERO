import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/receipt_model.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import 'chatbot_screen.dart'; // <--- 1. AGREGADO: Importa la pantalla del chat

class UserHomeScreen extends StatelessWidget {
  final DatabaseService _dbService = DatabaseService();
  final PdfService _pdfService = PdfService();
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Recibos"), // Es buena práctica poner const
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut().then((_) => Navigator.pushReplacementNamed(context, '/login')),
          )
        ],
      ),
      body: StreamBuilder<List<ReceiptModel>>(
        stream: _dbService.obtenerMisRecibos(user!.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var recibos = snapshot.data!;
          
          if (recibos.isEmpty) {
            return const Center(child: Text("No tienes recibos pendientes"));
          }

          return ListView.builder(
            itemCount: recibos.length,
            itemBuilder: (context, index) {
              final recibo = recibos[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.blue),
                  title: Text(recibo.periodo),
                  subtitle: Text("Total: \$${recibo.montoTotal} - Medidor: ${recibo.numeroMedidor}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.print),
                    onPressed: () => _pdfService.imprimirRecibo(recibo),
                    tooltip: "Descargar/Imprimir PDF",
                  ),
                ),
              );
            },
          );
        },
      ),
      // 2. AGREGADO: El botón flotante para el Chatbot
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.support_agent, color: Colors.white), // Icono de soporte
        tooltip: 'Asistente Virtual',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
          );
        },
      ),
    );
  }
}