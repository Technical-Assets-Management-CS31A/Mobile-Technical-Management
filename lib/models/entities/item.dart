class Item {
  final int id;
  final String serialNumber;
  final String itemName;
  final String itemImage;
  final String itemCategory;
  final String condition;
  final String itemType;
  final String itemModel;
  final String itemMake;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.serialNumber,
    required this.itemName,
    required this.itemImage,
    required this.itemCategory,
    required this.condition,
    this.itemType = '',
    this.itemModel = '',
    this.itemMake = '',
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      serialNumber: json['serial_number'],
      itemName: json['item_name'],
      itemImage: json['item_image'],
      itemCategory: json['item_category'],
      condition: json['condition'],
      itemType: json['item_type'] ?? '',
      itemModel: json['item_model'] ?? '',
      itemMake: json['item_make'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serial_number': serialNumber,
      'item_name': itemName,
      'item_image': itemImage,
      'item_category': itemCategory,
      'condition': condition,
      'item_type': itemType,
      'item_model': itemModel,
      'item_make': itemMake,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
