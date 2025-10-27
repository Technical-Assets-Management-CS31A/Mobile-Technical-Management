import 'item.dart';

class LendItem {
  final String? id;
  final Item? item;
  final String? userId;
  final String? teacherId;
  final String borrowerFullName;
  final String borrowerRole;
  final String? teacherFullName;
  final String room;
  final String subjectTimeSchedule;
  final DateTime? lentAt;
  final DateTime? returnedAt;
  final String? status;
  final String? remarks;
  final bool? isHiddenFromUser;
  final String? barcode;
  final String? barcodeImage;

  LendItem({
    this.id,
    this.item,
    this.userId,
    this.teacherId,
    required this.borrowerFullName,
    required this.borrowerRole,
    this.teacherFullName,
    required this.room,
    required this.subjectTimeSchedule,
    this.lentAt,
    this.returnedAt,
    this.status,
    this.remarks,
    this.isHiddenFromUser,
    this.barcode,
    this.barcodeImage,
  });

  factory LendItem.fromJson(Map<String, dynamic> json) {
    return LendItem(
      id: json['id']?.toString(),
      item: json['item'] != null ? Item.fromJson(json['item']) : null,
      userId: json['userId']?.toString(),
      teacherId: json['teacherId']?.toString(),
      borrowerFullName: json['borrowerFullName'] ?? '',
      borrowerRole: json['borrowerRole'] ?? '',
      teacherFullName: json['teacherFullName'],
      room: json['room'] ?? '',
      subjectTimeSchedule: json['subjectTimeSchedule'] ?? '',
      lentAt: json['lentAt'] != null ? DateTime.parse(json['lentAt']) : null,
      returnedAt: json['returnedAt'] != null
          ? DateTime.parse(json['returnedAt'])
          : null,
      status: json['status'],
      remarks: json['remarks'],
      isHiddenFromUser: json['isHiddenFromUser'],
      barcode: json['barcode'],
      barcodeImage: json['barcodeImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (item != null) 'item': item!.toJson(),
      if (userId != null) 'userId': userId,
      if (teacherId != null) 'teacherId': teacherId,
      'borrowerFullName': borrowerFullName,
      'borrowerRole': borrowerRole,
      'teacherFullName': teacherFullName,
      'room': room,
      'subjectTimeSchedule': subjectTimeSchedule,
      if (lentAt != null) 'lentAt': lentAt!.toIso8601String(),
      if (returnedAt != null) 'returnedAt': returnedAt!.toIso8601String(),
      'status': status,
      'remarks': remarks,
      'isHiddenFromUser': isHiddenFromUser,
      'barcode': barcode,
      'barcodeImage': barcodeImage,
    };
  }

  // Helper method for creating lend items (without ID and nested objects)
  Map<String, dynamic> toCreateJson() {
    return {
      if (item != null) 'itemId': item!.id,
      'borrowerFullName': borrowerFullName,
      'borrowerRole': borrowerRole,
      'teacherFullName': teacherFullName ?? '',
      'room': room,
      'subjectTimeSchedule': subjectTimeSchedule,
      'remarks': remarks,
      'barcode': barcode,
    };
  }

  // Copy with method for updates
  LendItem copyWith({
    String? id,
    Item? item,
    String? userId,
    String? teacherId,
    String? borrowerFullName,
    String? borrowerRole,
    String? teacherFullName,
    String? room,
    String? subjectTimeSchedule,
    DateTime? lentAt,
    DateTime? returnedAt,
    String? status,
    String? remarks,
    bool? isHiddenFromUser,
    String? barcode,
    String? barcodeImage,
  }) {
    return LendItem(
      id: id ?? this.id,
      item: item ?? this.item,
      userId: userId ?? this.userId,
      teacherId: teacherId ?? this.teacherId,
      borrowerFullName: borrowerFullName ?? this.borrowerFullName,
      borrowerRole: borrowerRole ?? this.borrowerRole,
      teacherFullName: teacherFullName ?? this.teacherFullName,
      room: room ?? this.room,
      subjectTimeSchedule: subjectTimeSchedule ?? this.subjectTimeSchedule,
      lentAt: lentAt ?? this.lentAt,
      returnedAt: returnedAt ?? this.returnedAt,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      isHiddenFromUser: isHiddenFromUser ?? this.isHiddenFromUser,
      barcode: barcode ?? this.barcode,
      barcodeImage: barcodeImage ?? this.barcodeImage,
    );
  }

  // Helper getter for item ID
  String? get itemId => item?.id;

  // Helper getter for item name
  String? get itemName => item?.itemName;
}
