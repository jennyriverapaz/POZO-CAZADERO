import 'package:flutter/material.dart';
import 'public_receipts_screen.dart';
import 'create_report_screen.dart'; 
import 'transparency_screen.dart'; 

class PublicHomeScreen extends StatelessWidget {
  final _medidorController = TextEditingController();

  void _irAConsulta(BuildContext context) {
    if (_medidorController.text.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PublicReceiptsScreen(numeroMedidor: _medidorController.text.trim())));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos los colores del tema que definimos en main.dart
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white, 
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500), // Para que no se estire feo en PC
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Botón Admin Discreto (Top Right)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.settings, color: Colors.grey[400]),
                      tooltip: "Acceso Administrativo",
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  
                  // LOGO ESTILIZADO
                  Container(
                    padding: EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1), // Fondo suavecito
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.water_drop_rounded, size: 80, color: primaryColor),
                  ),
                  
                  SizedBox(height: 30),
                  
                  Text(
                    "Servicio de Agua", 
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueGrey[900], letterSpacing: -0.5)
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Consulta recibos, reporta fugas y revisa la transparencia de tu comunidad.", 
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey[600], height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 50),
                  
                  // INPUT GRANDE CON SOMBRA
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: Offset(0, 10))]
                    ),
                    child: TextField(
                      controller: _medidorController,
                      style: TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        hintText: "Ingresa tu Número de Medidor",
                        prefixIcon: Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onSubmitted: (_) => _irAConsulta(context),
                    ),
                  ),
                  
                  SizedBox(height: 25),
                  
                  // BOTÓN PRINCIPAL (Grande y Turquesa)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _irAConsulta(context),
                      child: Text("CONSULTAR RECIBOS"),
                      // El estilo ya viene del main.dart, no hace falta repetirlo aquí
                    ),
                  ),
                  
                  SizedBox(height: 50),
                  Divider(color: Colors.grey[200]),
                  SizedBox(height: 30),

                  // BOTONES SECUNDARIOS (En fila para que se vea moderno)
                  Row(
                    children: [
                      // Reportar Fuga
                      Expanded(
                        child: _BotonCuadrado(
                          icon: Icons.warning_amber_rounded,
                          color: Colors.orange.shade800,
                          titulo: "Reportar\nFuga",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateReportScreen())),
                        ),
                      ),
                      
                      SizedBox(width: 20),
                      
                      // Transparencia
                      Expanded(
                        child: _BotonCuadrado(
                          icon: Icons.pie_chart_outline,
                          color: primaryColor,
                          titulo: "Portal de\nTransparencia",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransparencyScreen())),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar para que los botones de abajo se vean iguales y bonitos
class _BotonCuadrado extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String titulo;
  final VoidCallback onTap;

  const _BotonCuadrado({required this.icon, required this.color, required this.titulo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08), // Fondo muy clarito del mismo color
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 10),
            Text(
              titulo, 
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)
            )
          ],
        ),
      ),
    );
  }
}