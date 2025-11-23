import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _invitationCodeKey = 'invitation_code';
  static const String _codeGenerationTimeKey = 'code_generation_time';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveInvitationCode(String code, DateTime timestamp) async {
    await _storage.write(key: _invitationCodeKey, value: code);
    await _storage.write(key: _codeGenerationTimeKey, value: timestamp.toIso8601String());
  }

  Future<String?> getInvitationCode() async {
    return await _storage.read(key: _invitationCodeKey);
  }

  Future<DateTime?> getCodeGenerationTime() async {
    final String? timeStr = await _storage.read(key: _codeGenerationTimeKey);
    if (timeStr != null) {
      return DateTime.parse(timeStr);
    }
    return null;
  }

  Future<void> clearInvitationCode() async {
    await _storage.delete(key: _invitationCodeKey);
    await _storage.delete(key: _codeGenerationTimeKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await clearInvitationCode();
  }
}
