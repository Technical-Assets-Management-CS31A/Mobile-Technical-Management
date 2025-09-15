class InventoryList {
  final String category;
  final int itemTotalCount;
  final int itemTotalBorrowedCount;

  InventoryList({
    required this.category,
    required this.itemTotalCount,
    required this.itemTotalBorrowedCount,
  });

  factory InventoryList.fromJson(Map<String, dynamic> json) {
    return InventoryList(
      category: json['category'],
      itemTotalCount: json['item_total_count'],
      itemTotalBorrowedCount: json['item_total_borrowed_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'item_total_count': itemTotalCount,
      'item_total_borrowed_count': itemTotalBorrowedCount,
    };
  }

  int get availableCount => itemTotalCount - itemTotalBorrowedCount;
}

