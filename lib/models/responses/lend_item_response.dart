import '../entities/lend_item.dart';

class LendItemResponse {
  final bool success;
  final String message;
  final LendItem? data;

  LendItemResponse({required this.success, required this.message, this.data});

  factory LendItemResponse.fromJson(Map<String, dynamic> json) {
    return LendItemResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? LendItem.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data?.toJson()};
  }
}

class LendItemListResponse {
  final bool success;
  final String message;
  final List<LendItem>? data;
  final int? totalCount;
  final int? currentPage;
  final int? totalPages;

  LendItemListResponse({
    required this.success,
    required this.message,
    this.data,
    this.totalCount,
    this.currentPage,
    this.totalPages,
  });

  factory LendItemListResponse.fromJson(Map<String, dynamic> json) {
    List<LendItem>? items;
    if (json['data'] != null) {
      if (json['data'] is List) {
        items = (json['data'] as List)
            .map((item) => LendItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    return LendItemListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: items,
      totalCount: json['totalCount'],
      currentPage: json['currentPage'],
      totalPages: json['totalPages'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.map((item) => item.toJson()).toList(),
      'totalCount': totalCount,
      'currentPage': currentPage,
      'totalPages': totalPages,
    };
  }
}
