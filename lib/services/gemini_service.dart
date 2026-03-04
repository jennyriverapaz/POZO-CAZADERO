import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // OJO: En producción, usa flutter_dotenv para no dejar la KEY visible.
  static const String _apiKey = 'TU_API_KEY_AQUI'; 

  late final GenerativeModel _model;
  ChatSession? _chat;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'Eres el asistente virtual de la App del Pozo de Agua. '
        'Tu objetivo es ayudar a los vecinos con respuestas breves y amables. '
        'DATOS CLAVE: '
        '- Horario de bombeo: Lun, Mie, Vie de 6:00 AM a 10:00 AM. '
        '- Costo: 50 pesos al mes. '
        '- Fugas: Pedir que cierren llave de paso y reporten en la sección "Reportes". '
        '- Si te insultan o preguntan cosas ajenas al agua, responde educadamente que solo hablas del pozo.'
      ),
    );
    // Iniciamos el chat
    _chat = _model.startChat();
  }

  Future<String?> sendMessage(String message) async {
    try {
      final response = await _chat?.sendMessage(Content.text(message));
      return response?.text;
    } catch (e) {
      return "Error de conexión. Intenta más tarde.";
    }
  }
}