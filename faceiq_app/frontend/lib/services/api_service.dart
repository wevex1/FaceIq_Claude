// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/analysis_result.dart';

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  // ─── Detect landmarks only (no ratio computation) ─────────────────────────
  static Future<Map<String, List<double>>> detectLandmarks({
    required XFile xfile,
    required String type, // 'frontal' or 'profile'
  }) async {
    final uri = Uri.parse('$_baseUrl/detect/$type');
    final request = http.MultipartRequest('POST', uri);
    final bytes = await xfile.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'image', bytes, filename: '$type.jpg',
    ));

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final j = jsonDecode(response.body) as Map<String, dynamic>;
      if (j['success'] == true) {
        return (j['landmarks'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
            k,
            (v as List).map((e) => (e as num).toDouble()).toList(),
          ),
        );
      }
      throw Exception(j['error'] ?? 'No face detected');
    }
    throw Exception('Server error ${response.statusCode}');
  }

  // ─── Analyze with (possibly edited) landmarks ─────────────────────────────
  static Future<CombinedResult> analyzeCombinedWithLandmarks({
    XFile? frontalXFile,
    XFile? profileXFile,
    Map<String, List<double>>? frontalLandmarks,
    Map<String, List<double>>? profileLandmarks,
  }) async {
    final uri = Uri.parse('$_baseUrl/analyze/combined_custom');
    final request = http.MultipartRequest('POST', uri);

    if (frontalXFile != null) {
      final bytes = await frontalXFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'frontal', bytes, filename: 'frontal.jpg',
      ));
    }
    if (profileXFile != null) {
      final bytes = await profileXFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'profile', bytes, filename: 'profile.jpg',
      ));
    }
    if (frontalLandmarks != null) {
      request.fields['frontal_landmarks'] = jsonEncode(frontalLandmarks);
    }
    if (profileLandmarks != null) {
      request.fields['profile_landmarks'] = jsonEncode(profileLandmarks);
    }

    final streamed =
        await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return CombinedResult.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Server error ${response.statusCode}: ${_parseError(response.body)}');
  }

  // ─── Legacy combined (no landmark editing) ────────────────────────────────
  static Future<CombinedResult> analyzeCombined({
    XFile? frontalXFile,
    XFile? profileXFile,
  }) async {
    return analyzeCombinedWithLandmarks(
      frontalXFile: frontalXFile,
      profileXFile: profileXFile,
    );
  }

  static Future<bool> isReachable() async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static String _parseError(String body) {
    try {
      return (jsonDecode(body) as Map)['detail']?.toString() ?? body;
    } catch (_) {
      return body;
    }
  }
}
