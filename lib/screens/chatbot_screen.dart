import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:agua_pwa/services/gemini_service.dart'; 

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final GeminiService _geminiService = GeminiService(); // Instanciamos el servicio
  
  final ChatUser _usuario = ChatUser(id: '1', firstName: 'Vecino');
  final ChatUser _bot = ChatUser(
    id: '2', 
    firstName: 'Asistente',
    profileImage: "https://cdn-icons-png.flaticon.com/512/8943/8943377.png" // Icono de robot/agua
  );

  List<ChatMessage> _mensajes = [];
  List<ChatUser> _typingUsers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente Virtual 💧'),
        backgroundColor: Colors.blue, 
        foregroundColor: Colors.white,
      ),
      body: DashChat(
        currentUser: _usuario,
        typingUsers: _typingUsers,
        onSend: (ChatMessage m) => _handleSend(m),
        messages: _mensajes,
        inputOptions: const InputOptions(
          inputDecoration: InputDecoration(
            hintText: 'Pregunta sobre horarios, pagos...',
            border: InputBorder.none,
        ),
      ),
      ),
    );
  }

  Future<void> _handleSend(ChatMessage mensaje) async {
    setState(() {
      _mensajes.insert(0, mensaje);
      _typingUsers.add(_bot); // Aparece "Escribiendo..."
    });

    // Llamamos a nuestro servicio
    String? respuesta = await _geminiService.sendMessage(mensaje.text);

    setState(() {
      _typingUsers.remove(_bot); // Quitamos "Escribiendo..."
      if (respuesta != null) {
        _mensajes.insert(0, ChatMessage(
          user: _bot,
          createdAt: DateTime.now(),
          text: respuesta,
        ));
      }
    });
  }
}