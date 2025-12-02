class HomeResponse {
  final List<EventInfo> eventInfos;

  HomeResponse({
    this.eventInfos = const [],
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      eventInfos: json['eventInfos'] != null
          ? (json['eventInfos'] as List)
              .map((e) => EventInfo.fromJson(e))
              .toList()
          : [],
    );
  }
}

class HomeCoupleInfo {
  final AccountInfo accountInfo;
  final CoupleInfo? coupleInfo;

  HomeCoupleInfo({
    required this.accountInfo,
    this.coupleInfo,
  });

  factory HomeCoupleInfo.fromJson(Map<String, dynamic> json) {
    return HomeCoupleInfo(
      accountInfo: AccountInfo.fromJson(json['accountInfo']),
      coupleInfo: json['coupleInfo'] != null
          ? CoupleInfo.fromJson(json['coupleInfo'])
          : null,
    );
  }
}

class EventInfo {
  final int calendarId;
  final int categoryId; // Changed to int as per user request (Long -> int)
  final DateTime eventAt;

  EventInfo({
    required this.calendarId,
    required this.categoryId,
    required this.eventAt,
  });

  factory EventInfo.fromJson(Map<String, dynamic> json) {
    return EventInfo(
      calendarId: json['calendarId'],
      categoryId: json['categoryId'], // Assuming int
      eventAt: DateTime.parse(json['eventAt']),
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
