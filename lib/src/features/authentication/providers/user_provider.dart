import 'package:flutter/material.dart';
import 'package:front_flutter/src/core/errors/exceptions.dart';
import 'package:front_flutter/src/features/couple/services/couple_service.dart';
import 'package:front_flutter/src/features/home/models/home_response.dart';

class UserProvider extends ChangeNotifier {
  AccountInfo? _accountInfo;
  CoupleInfo? _coupleInfo;

  AccountInfo? get accountInfo => _accountInfo;
  CoupleInfo? get coupleInfo => _coupleInfo;
  List<EventInfo> get eventInfos => _homeData?.eventInfos ?? [];
  bool get isCouple => _coupleInfo != null;
  String get name => _accountInfo?.name ?? '';

  HomeResponse? _homeData;

  Future<void> fetchHomeData() async {
    try {
      final coupleService = CoupleService();
      
      // Fetch both concurrently
      final results = await Future.wait([
        coupleService.getHomeEvents(),
        coupleService.getHomeCoupleInfo(),
      ]);

      final homeEvents = results[0] as HomeResponse?;
      final homeCoupleInfo = results[1] as HomeCoupleInfo?;

      if (homeEvents != null) {
        _homeData = homeEvents;
      }
      
      if (homeCoupleInfo != null) {
        _accountInfo = homeCoupleInfo.accountInfo;
        _coupleInfo = homeCoupleInfo.coupleInfo;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error fetching home data: $e');
      if (e is UnauthorizedException) rethrow;
    }
  }
  
  // Deprecated: Use fetchHomeData instead
  Future<void> checkCoupleStatus() async {
    await fetchHomeData();
  }
}
