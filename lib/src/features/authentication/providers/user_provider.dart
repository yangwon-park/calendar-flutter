import 'package:flutter/material.dart';
import 'package:front_flutter/src/features/couple/services/couple_service.dart';
import 'package:front_flutter/src/features/home/models/home_response.dart';

class UserProvider extends ChangeNotifier {
  AccountInfo? _accountInfo;
  CoupleInfo? _coupleInfo;

  AccountInfo? get accountInfo => _accountInfo;
  CoupleInfo? get coupleInfo => _coupleInfo;
  bool get isCouple => _coupleInfo != null;
  String get name => _accountInfo?.name ?? '';

  Future<void> fetchHomeData() async {
    try {
      final homeData = await CoupleService().getHomeData();
      if (homeData != null) {
        _accountInfo = homeData.accountInfo;
        _coupleInfo = homeData.coupleInfo;
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching home data: $e');
    }
  }
  
  // Deprecated: Use fetchHomeData instead
  Future<void> checkCoupleStatus() async {
    await fetchHomeData();
  }
}
