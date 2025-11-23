import 'dart:convert';
import 'package:front_flutter/src/core/services/storage_service.dart';
import 'package:http/http.dart' as http;

class CoupleService {
  // TODO: Replace with your actual Spring Backend URL
  static const String _backendUrl = 'http://localhost:8080';

  Future<String> generateInvitationCode() async {
    try {
      final String? accessToken = await StorageService().getToken();
      
      if (accessToken == null) {
        throw Exception('No access token found. Please login again.');
      }

      final response = await http.post(
        Uri.parse('$_backendUrl/api/couple/invitations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['invitationCode'] ?? 'CODE_NOT_FOUND';
      } else {
        throw Exception('Failed to generate code: ${response.body}');
      }
    } catch (e) {
      print('CoupleService Error: $e');
      rethrow;
    }
  }
}
