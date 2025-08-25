class ItemList {
  final String itemImage;
  final String itemSerialNumber;
  final String itemName;
  final String itemCategory;
  final String itemCondition;

  ItemList({
    required this.itemImage,
    required this.itemSerialNumber,
    required this.itemName,
    required this.itemCategory,
    required this.itemCondition,
  });

  factory ItemList.fromJson(Map<String, dynamic> json) {
    return ItemList(
      itemImage: json['item_image'],
      itemSerialNumber: json['item_serial_number'],
      itemName: json['item_name'],
      itemCategory: json['item_category'],
      itemCondition: json['item_condition'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_image': itemImage,
      'item_serial_number': itemSerialNumber,
      'item_name': itemName,
      'item_category': itemCategory,
      'item_condition': itemCondition,
    };
  }
}

