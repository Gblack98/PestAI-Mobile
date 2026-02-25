import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config.dart';
import '../models.dart';

// ignore_for_file: avoid_print

class ApiService {
  /// Envoie une image à l'API PestAI et retourne le résultat structuré.
  ///
  /// Throws [ApiException] en cas d'erreur HTTP.
  /// Throws [FormatException] si la réponse n'est pas du JSON valide.
  static Future<AnalysisResponse> analyze({
    required File imageFile,
    required AnalysisType analysisType,
  }) async {
    final uri = Uri.parse('$kApiBaseUrl/api/v12/analyze');
    final request = http.MultipartRequest('POST', uri);

    request.fields['analysis_type'] = analysisType.value;
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'png' : 'jpeg';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', mime),
      ),
    );

    final streamed = await request.send().timeout(kRequestTimeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AnalysisResponse.fromJson(json);
    }

    // Extraction du message d'erreur de l'API
    String errorMessage;
    try {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = errorJson['detail']?.toString() ?? 'Erreur inconnue';
    } catch (_) {
      errorMessage = response.body;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage,
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';

  String get userFriendlyMessage {
    return switch (statusCode) {
      415 => 'Format d\'image non supporté.',
      429 => 'Quota API dépassé. Réessaie dans quelques instants.',
      502 => 'Le modèle IA a renvoyé une réponse invalide.',
      503 => 'Service IA temporairement indisponible.',
      _ => message,
    };
  }
}
