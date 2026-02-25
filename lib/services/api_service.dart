import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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

  static Map<String, dynamic> _analysisBody(AnalysisResponse analysis) => {
    'subject': {
      'subjectType': analysis.subject.subjectType,
      'description': analysis.subject.description,
      'confidence': analysis.subject.confidence,
    },
    'detections': analysis.detections.map((d) => {
      'className': d.className,
      'severity': d.severity,
      'confidenceScore': d.confidenceScore,
      'details': {
        'description': d.details.description,
        'recommendations': {
          'biological': d.details.recommendations.biological
              .map((r) => {'solution': r.solution}).toList(),
          'chemical': d.details.recommendations.chemical
              .map((r) => {'solution': r.solution}).toList(),
          'cultural': d.details.recommendations.cultural
              .map((r) => {'solution': r.solution}).toList(),
        }
      }
    }).toList(),
  };

  /// Retourne les bytes WAV + texte wolof.
  /// Étape 1 : génère le texte Wolof via le backend (Gemini, texte seul).
  /// Étape 2 : synthétise l'audio directement via le Space HF xTTS GalsenAI.
  static Future<(Uint8List, String)> fetchVoiceAudio(AnalysisResponse analysis) async {
    // --- Étape 1 : texte Wolof ---
    final textUri = Uri.parse('$kApiBaseUrl/api/v12/voice-text');
    final textResponse = await http.post(
      textUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_analysisBody(analysis)),
    ).timeout(kRequestTimeout);

    if (textResponse.statusCode != 200) {
      throw ApiException(
        statusCode: textResponse.statusCode,
        message: 'Erreur génération texte Wolof',
      );
    }

    final wolofText =
        (jsonDecode(textResponse.body) as Map<String, dynamic>)['text'] as String;

    // --- Étape 2 : synthèse audio via Space HF ---
    final audioBytes = await _synthesizeWolof(wolofText);
    return (audioBytes, wolofText);
  }

  /// Appelle le Space HuggingFace xTTS GalsenAI via l'API REST Gradio.
  /// Retourne les bytes WAV de l'audio synthétisé.
  static Future<Uint8List> _synthesizeWolof(String text) async {
    // 1. Soumettre la requête de prédiction
    final predictUri = Uri.parse('$kHfSpaceBaseUrl/call/predict');
    final predictResponse = await http
        .post(
          predictUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'data': [
              text,
              {
                'path': kWolofReferenceAudioUrl,
                'meta': {'_type': 'gradio.FileData'},
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (predictResponse.statusCode != 200) {
      throw ApiException(
        statusCode: predictResponse.statusCode,
        message: 'Erreur soumission TTS : ${predictResponse.body}',
      );
    }

    final eventId =
        (jsonDecode(predictResponse.body) as Map<String, dynamic>)['event_id']
            as String;

    // 2. Attendre le résultat via SSE
    final audioUrl = await _waitForAudioUrl(eventId);

    // 3. Télécharger l'audio
    final audioResponse =
        await http.get(Uri.parse(audioUrl)).timeout(kTtsTimeout);
    if (audioResponse.statusCode != 200) {
      throw ApiException(
        statusCode: audioResponse.statusCode,
        message: 'Erreur téléchargement audio',
      );
    }
    return audioResponse.bodyBytes;
  }

  /// Écoute le flux SSE du Space HF et retourne l'URL de l'audio généré.
  static Future<String> _waitForAudioUrl(String eventId) async {
    final sseUri = Uri.parse('$kHfSpaceBaseUrl/call/predict/$eventId');
    final client = http.Client();
    try {
      final request = http.Request('GET', sseUri);
      final streamed = await client.send(request).timeout(kTtsTimeout);

      if (streamed.statusCode != 200) {
        throw ApiException(
          statusCode: streamed.statusCode,
          message: 'Erreur flux SSE Space HF',
        );
      }

      String? lastEvent;
      final lines = streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (line.startsWith('event:')) {
          lastEvent = line.substring(6).trim();
        } else if (line.startsWith('data:') && lastEvent == 'complete') {
          final dataStr = line.substring(5).trim();
          if (dataStr.isEmpty || dataStr == 'null') continue;
          final dataList = jsonDecode(dataStr) as List<dynamic>;
          if (dataList.isNotEmpty) {
            final audioInfo = dataList[0] as Map<String, dynamic>;
            final url = audioInfo['url'] as String?;
            if (url != null && url.isNotEmpty) return url;
          }
        }
      }
      throw const ApiException(statusCode: 502, message: 'Aucune URL audio reçue');
    } finally {
      client.close();
    }
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
