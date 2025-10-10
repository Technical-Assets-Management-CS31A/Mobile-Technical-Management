import '../entities/item.dart';

/// Response model for single item operations
class ItemResponse {
  final bool success;
  final String message;
  final Item? data;
  final List<String>? errors;

  ItemResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ItemResponse.fromJson(Map<String, dynamic> json) {
    return ItemResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? Item.fromJson(json['data']) : null,
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
      'errors': errors,
    };
  }
}

/// Response model for item list operations
class ItemListResponse {
  final bool success;
  final String message;
  final List<Item>? data;
  final List<String>? errors;
  final int? totalCount;
  final int? page;
  final int? pageSize;

  ItemListResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.totalCount,
    this.page,
    this.pageSize,
  });

  factory ItemListResponse.fromJson(Map<String, dynamic> json) {
    return ItemListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List).map((item) => Item.fromJson(item)).toList()
          : null,
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
      totalCount: json['totalCount'],
      page: json['page'],
      pageSize: json['pageSize'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.map((item) => item.toJson()).toList(),
      'errors': errors,
      'totalCount': totalCount,
      'page': page,
      'pageSize': pageSize,
    };
  }
}

/// Response model for item statistics
class ItemStatsResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final List<String>? errors;

  ItemStatsResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ItemStatsResponse.fromJson(Map<String, dynamic> json) {
    return ItemStatsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'errors': errors,
    };
  }
}

/// Request model for creating items
class CreateItemRequest {
  final String serialNumber;
  final String? image;
  final String itemName;
  final String itemType;
  final String? itemModel;
  final String itemMake;
  final String? description;
  final ItemCategory category;
  final ItemCondition condition;

  CreateItemRequest({
    required this.serialNumber,
    this.image,
    required this.itemName,
    required this.itemType,
    this.itemModel,
    required this.itemMake,
    this.description,
    required this.category,
    required this.condition,
  });

  Map<String, dynamic> toJson() {
    return {
      'serialNumber': serialNumber,
      'image': image,
      'itemName': itemName,
      'itemType': itemType,
      'itemModel': itemModel,
      'itemMake': itemMake,
      'description': description,
      'category': category.name,
      'condition': condition.name,
    };
  }
}

/// Request model for updating items
class UpdateItemRequest {
  final String id;
  final String serialNumber;
  final String? image;
  final String itemName;
  final String itemType;
  final String? itemModel;
  final String itemMake;
  final String? description;
  final ItemCategory category;
  final ItemCondition condition;

  UpdateItemRequest({
    required this.id,
    required this.serialNumber,
    this.image,
    required this.itemName,
    required this.itemType,
    this.itemModel,
    required this.itemMake,
    this.description,
    required this.category,
    required this.condition,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'image': image,
      'itemName': itemName,
      'itemType': itemType,
      'itemModel': itemModel,
      'itemMake': itemMake,
      'description': description,
      'category': category.name,
      'condition': condition.name,
    };
  }
}
