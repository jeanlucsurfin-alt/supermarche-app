class CashClosing {
  final int? id;
  final int employeeId;
  final String employeeName;
  final double expectedCash;
  final double countedCash;
  final DateTime date;
  final String? note;

  CashClosing({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.expectedCash,
    required this.countedCash,
    required this.date,
    this.note,
  });

  double get difference => countedCash - expectedCash;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'expectedCash': expectedCash,
      'countedCash': countedCash,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory CashClosing.fromMap(Map<String, dynamic> map) {
    return CashClosing(
      id: map['id'],
      employeeId: map['employeeId'],
      employeeName: map['employeeName'],
      expectedCash: (map['expectedCash'] as num).toDouble(),
      countedCash: (map['countedCash'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      note: map['note'],
    );
  }
}
