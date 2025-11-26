class HomeResponse {
  final AccountInfo accountInfo;
  final CoupleInfo? coupleInfo;

  HomeResponse({
    required this.accountInfo,
    this.coupleInfo,
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      accountInfo: AccountInfo.fromJson(json['accountInfo']),
      coupleInfo: json['coupleInfo'] != null
          ? CoupleInfo.fromJson(json['coupleInfo'])
          : null,
    );
  }
}

class AccountInfo {
  final String name;

  AccountInfo({required this.name});

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      name: json['name'],
    );
  }
}

class CoupleInfo {
  final int partnerId;
  final String partnerName;
  final DateTime startDate;
  final int daysCount;

  CoupleInfo({
    required this.partnerId,
    required this.partnerName,
    required this.startDate,
    required this.daysCount,
  });

  factory CoupleInfo.fromJson(Map<String, dynamic> json) {
    return CoupleInfo(
      partnerId: json['partnerId'],
      partnerName: json['partnerName'],
      startDate: DateTime.parse(json['startDate']),
      daysCount: json['daysCount'],
    );
  }
}
