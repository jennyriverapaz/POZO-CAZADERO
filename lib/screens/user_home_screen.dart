import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/receipt_model.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';

class UserHomeScreen extends StatelessWidget {
  final DatabaseService _dbService = DatabaseService();
  final PdfService _pdfService = PdfService();
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mis Recibos"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut().then((_) => Navigator.pushReplacementNamed(context, '/login')),
          )
        ],
      ),
      body: StreamBuilder<List<ReceiptModel>>(
        stream: _dbService.obtenerMisRecibos(user!.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          var recibos = snapshot.data!;
          
          return ListView.builder(
            itemCount: recibos.length,
            itemBuilder: (context, index) {
              final recibo = recibos[index];
              return Card(
                child: ListTile(
                  leading: Icon(Icons.receipt_long, color: Colors.blue),
                  title: Text(recibo.periodo),
                  subtitle: Text("Total: \$${recibo.montoTotal} - Medidor: ${recibo.numeroMedidor}"),
                  trailing: IconButton(
                    icon: Icon(Icons.print),
                    onPressed: () => _pdfService.imprimirRecibo(recibo),
                    tooltip: "Descargar/Imprimir PDF",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}