import 'dart:convert';
import 'package:front_flutter/src/core/errors/exceptions.dart';
import 'package:front_flutter/src/core/services/api_service.dart';
import 'package:front_flutter/src/features/home/models/home_response.dart';

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
        '/api/couples',
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
  
  Future<bool> disconnectCouple() async {
    try {
      final response = await ApiService().delete('/api/couples');
      
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Disconnect failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('CoupleService Disconnect Error: $e');
      return false;
    }
  }

  Future<bool> updateAdditionalInfo(String startDate) async {
    try {
      final response = await ApiService().put(
        '/api/couples/additional-info',
        body: jsonEncode({'startDate': startDate}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Update additional info failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('CoupleService Update Info Error: $e');
      return false;
    }
  }

  Future<HomeResponse?> getHomeEvents() async {
    try {
      final response = await ApiService().get('/api/home');
      
      if (response.statusCode == 200) {
         final data = jsonDecode(utf8.decode(response.bodyBytes));
         print('Home Events Response: $data');
         if (data['data'] == null) {
           return null;
         }
         return HomeResponse.fromJson(data['data']);
      }
      
      if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 4002 || response.statusCode == 4003) {
        throw UnauthorizedException();
      }
      
      return null;
    } catch (e) {
      print('Get Home Events Error: $e');
      if (e is UnauthorizedException) rethrow;
      return null;
    }
  }

  Future<HomeCoupleInfo?> getHomeCoupleInfo() async {
    try {
      // Assuming the endpoint for couple info is /api/home/couples based on previous context
      // or user might have meant the existing one was for couple info.
      // User said: "Existing couple info fetching is changed to HomeCoupleInfo"
      // I'll use /api/home/couples for this.
      final response = await ApiService().get('/api/home/couples');
      
      if (response.statusCode == 200) {
         final data = jsonDecode(utf8.decode(response.bodyBytes));
         print('Home Couple Info Response: $data');
         if (data['data'] == null) {
           return null;
         }
         return HomeCoupleInfo.fromJson(data['data']);
      }
      
      if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 4002 || response.statusCode == 4003) {
        throw UnauthorizedException();
      }

      return null;
    } catch (e) {
      print('Get Home Couple Info Error: $e');
      if (e is UnauthorizedException) rethrow;
      return null;
    }
  }
}
