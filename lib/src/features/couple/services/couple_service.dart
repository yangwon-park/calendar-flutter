import 'dart:convert';
import 'package:front_flutter/src/core/services/api_service.dart';

class CoupleService {
  Future<String> generateInvitationCode() async {
    print('CoupleService: generateInvitationCode called');
    try {
      final response = await ApiService().post(
        '/api/couple/invitations',
      );
      print('CoupleService response status: ${response.statusCode}');
      print('CoupleService response body: ${response.body}');

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
  Future<bool> connectCouple(String code) async {
    try {
      final response = await ApiService().post(
        '/api/couple/connect',
        body: jsonEncode({'invitationCode': code}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Connect failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('CoupleService Connect Error: $e');
      return false;
    }
  }
}
