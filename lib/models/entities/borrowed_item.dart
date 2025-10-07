class BorrowedItem {
  final int id;
  final String itemName;
  final String borrowedId;
  final String teacher;
  final String room;
  final String occupied;
  final String condition;
  final String eventDate;
  final String status;

  BorrowedItem({
    required this.id,
    required this.itemName,
    required this.borrowedId,
    required this.teacher,
    required this.room,
    required this.occupied,
    required this.condition,
    required this.eventDate,
    required this.status,
  });

  factory BorrowedItem.fromJson(Map<String, dynamic> json) {
    return BorrowedItem(
      id: json['id'],
      itemName: json['ItemName'],
      borrowedId: json['Borrowed_id'],
      teacher: json['Teacher'],
      room: json['Room'],
      occupied: json['Occupied'],
      condition: json['Condition'],
      eventDate: json['Event_Date'],
      status: json['Status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ItemName': itemName,
      'Borrowed_id': borrowedId,
      'Teacher': teacher,
      'Room': room,
      'Occupied': occupied,
      'Condition': condition,
      'Event_Date': eventDate,
      'Status': status,
    };
  }
}

