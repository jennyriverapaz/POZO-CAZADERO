import 'dart:ui'; // <--- ¡IMPORTANTE: Agrega este import para el blur!
import 'package:flutter/material.dart';

class AnimatedGlassButton extends StatefulWidget {
  // ... (tus variables se quedan igual)
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;

  const AnimatedGlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color,
  });

  @override
  State<AnimatedGlassButton> createState() => _AnimatedGlassButtonState();
}

class _AnimatedGlassButtonState extends State<AnimatedGlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Future.delayed(const Duration(milliseconds: 100), widget.onPressed);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // ¡Aquí ocurre la magia del desenfoque!
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
              decoration: BoxDecoration(
                color: buttonColor.withOpacity(0.6), // Transparencia ajustada para que el blur destaque
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18, // Subimos un poco el tamaño para más impacto
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}