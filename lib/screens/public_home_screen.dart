import 'dart:ui';
import 'package:flutter/material.dart';
import 'create_report_screen.dart'; 
import 'login_screen.dart'; 
import '../widgets/water_drop_mascot.dart';
import '../widgets/animated_glass_button.dart';

class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF090E17), // Fondo oscuro profundo
      body: Stack(
        children: [
          // RESPLANDORES DE NEÓN (Regresamos a tu Cian/Menta original)
          _buildNeonGlow(color: theme.primary, top: -50, left: -100, size: 350), 
          _buildNeonGlow(color: theme.secondary, bottom: -100, right: -50, size: 300), 
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    children: [
                      const WaterDropMascot(),
                      const SizedBox(height: 40),
                      
                      // Título iluminado
                      const Text(
                        "POZO EL CAZADERO", 
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Accede a tus servicios de agua y realiza reportes de forma rápida y segura.", 
                        style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7), height: 1.5), 
                        textAlign: TextAlign.center
                      ),
                      
                      const SizedBox(height: 60),

                      // --- 1. BOTÓN PRINCIPAL EN MEDIO (De vuelta a tu color Neón/Menta original) ---
                      AnimatedGlassButton(
                        text: "INICIAR SESIÓN", 
                        color: theme.primary, // Usamos el neón original
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()))
                      ),

                      const SizedBox(height: 40),
                      
                      // --- 2. BOTÓN DE EMERGENCIA ABAJO (Verde Esmeralda Pulsante) ---
                      _DarkGlassEmergencyButton(
                        icon: Icons.warning_amber_rounded,
                        color: theme.secondary, // Verde Esmeralda
                        titulo: "REPORTAR FUGA AHORA",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateReportScreen()))
                      ),
                      
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Creador del efecto "Neon Glow" de fondo
  Widget _buildNeonGlow({required Color color, double? top, double? bottom, double? left, double? right, required double size}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90), child: Container()),
      ),
    );
  }
}

// --- CLASE PRIVADA: BOTÓN DE EMERGENCIA DARK GLASS CON RESPLANDOR PULSANTE ---
class _DarkGlassEmergencyButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String titulo;
  final VoidCallback onTap;

  const _DarkGlassEmergencyButton({required this.icon, required this.color, required this.titulo, required this.onTap});

  @override
  State<_DarkGlassEmergencyButton> createState() => _DarkGlassEmergencyButtonState();
}

class _DarkGlassEmergencyButtonState extends State<_DarkGlassEmergencyButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); 
    
    _pulseAnimation = Tween<double>(begin: 0.1, end: 0.5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Future.delayed(const Duration(milliseconds: 100), widget.onTap);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05), 
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: widget.color.withOpacity(0.6), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(_pulseAnimation.value), 
                        blurRadius: 30,
                        offset: const Offset(0, 0), 
                      )
                    ]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: 28, color: widget.color),
                      const SizedBox(width: 15),
                      Text(
                        widget.titulo, 
                        textAlign: TextAlign.center, 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.w900, 
                          fontSize: 18, 
                          letterSpacing: 1.0,
                        )
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}