import 'dart:convert';
import 'package:front_flutter/src/core/services/api_service.dart';

class CoupleService {
  Future<String> generateInvitationCode() async {
    try {
      final response = await ApiService().post(
        '/api/couple/invitations',
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
