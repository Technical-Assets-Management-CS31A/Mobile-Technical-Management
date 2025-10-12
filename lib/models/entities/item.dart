// Enums to match backend API
enum ItemCategory {
  Electronics,
  Keys,
  MediaEquipment,
  Tools,
  Miscellaneous;

  String get displayName {
    switch (this) {
      case ItemCategory.Electronics:
        return 'Electronics';
      case ItemCategory.Keys:
        return 'Keys';
      case ItemCategory.MediaEquipment:
        return 'Media Equipment';
      case ItemCategory.Tools:
        return 'Tools';
      case ItemCategory.Miscellaneous:
        return 'Miscellaneous';
    }
  }

  static ItemCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'electronics':
        return ItemCategory.Electronics;
      case 'keys':
        return ItemCategory.Keys;
      case 'mediaequipment':
      case 'media_equipment':
      case 'media equipment':
        return ItemCategory.MediaEquipment;
      case 'tools':
        return ItemCategory.Tools;
      case 'miscellaneous':
        return ItemCategory.Miscellaneous;
      default:
        return ItemCategory.Miscellaneous;
    }
  }
}

enum ItemCondition {
  New,
  Good,
  Defective,
  Refurbished,
  NeedRepair;

  String get displayName {
    switch (this) {
      case ItemCondition.New:
        return 'New';
      case ItemCondition.Good:
        return 'Good';
      case ItemCondition.Defective:
        return 'Defective';
      case ItemCondition.Refurbished:
        return 'Refurbished';
      case ItemCondition.NeedRepair:
        return 'Need Repair';
    }
  }

  String get colorCode {
    switch (this) {
      case ItemCondition.New:
        return '#4CAF50'; // Green
      case ItemCondition.Good:
        return '#2196F3'; // Blue
      case ItemCondition.Defective:
        return '#F44336'; // Red
      case ItemCondition.Refurbished:
        return '#9C27B0'; // Purple
      case ItemCondition.NeedRepair:
        return '#FF9800'; // Orange
    }
  }

  static ItemCondition fromString(String value) {
    switch (value.toLowerCase()) {
      case 'new':
        return ItemCondition.New;
      case 'good':
        return ItemCondition.Good;
      case 'defective':
        return ItemCondition.Defective;
      case 'refurbished':
        return ItemCondition.Refurbished;
      case 'needrepair':
      case 'need_repair':
      case 'need repair':
        return ItemCondition.NeedRepair;
      default:
        return ItemCondition.Good;
    }
  }
}

class Item {
  final String id; // Changed from int to String to match backend
  final String serialNumber;
  final String? image; // Changed from itemImage to image, nullable
  final String itemName;
  final String itemType;
  final String? itemModel; // Made nullable
  final String itemMake;
  final String? description; // Made nullable
  final ItemCategory category; // Changed from String to enum
  final ItemCondition condition; // Changed from String to enum
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'].toString(),
      serialNumber: json['serialNumber'] ?? '',
      image: json['image'],
      itemName: json['itemName'] ?? '',
      itemType: json['itemType'] ?? '',
      itemModel: json['itemModel'],
      itemMake: json['itemMake'] ?? '',
      description: json['description'],
      category: ItemCategory.fromString(json['category'] ?? ''),
      condition: ItemCondition.fromString(json['condition'] ?? ''),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper method for creating items (without ID and timestamps)
  Map<String, dynamic> toCreateJson() {
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

  // Helper method for updating items (without timestamps)
  Map<String, dynamic> toUpdateJson() {
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

  // Helper method for updating items as form data (for multipart requests)
  Map<String, String> toUpdateFormData() {
    return {
      'SerialNumber': serialNumber,
      'Image': image ?? '',
      'ItemName': itemName,
      'ItemType': itemType,
      'ItemModel': itemModel ?? '',
      'ItemMake': itemMake,
      'Description': description ?? '',
      'Category': category.name,
      'Condition': condition.name,
    };
  }

  // Copy with method for updates
  Item copyWith({
    String? id,
    String? serialNumber,
    String? image,
    String? itemName,
    String? itemType,
    String? itemModel,
    String? itemMake,
    String? description,
    ItemCategory? category,
    ItemCondition? condition,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      image: image ?? this.image,
      itemName: itemName ?? this.itemName,
      itemType: itemType ?? this.itemType,
      itemModel: itemModel ?? this.itemModel,
      itemMake: itemMake ?? this.itemMake,
      description: description ?? this.description,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
