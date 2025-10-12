class SummaryData {
  final int? totalItems;
  final int? totalLentItems;
  final int? totalActiveUsers;
  final int? totalItemsCategories;

  const SummaryData({
    this.totalItems,
    this.totalLentItems,
    this.totalActiveUsers,
    this.totalItemsCategories,
  });

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    return SummaryData(
      totalItems: json['totalItems'] as int?,
      totalLentItems: json['totalLentItems'] as int?,
      totalActiveUsers: json['totalActiveUsers'] as int?,
      totalItemsCategories: json['totalItemsCategories'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalItems': totalItems,
      'totalLentItems': totalLentItems,
      'totalActiveUsers': totalActiveUsers,
      'totalItemsCategories': totalItemsCategories,
    };
  }
}

class SummaryResponse {
  final bool success;
  final String message;
  final SummaryData? data;

  const SummaryResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory SummaryResponse.fromJson(Map<String, dynamic> json) {
    return SummaryResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] != null
          ? SummaryData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data?.toJson()};
  }
}
