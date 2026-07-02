class EmployeeShift {
  final int? id;
  final int employeeId;
  final String employeeName;
  final DateTime clockIn;
  final DateTime? clockOut;

  EmployeeShift({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.clockIn,
    this.clockOut,
  });

  Duration get duration {
    final end = clockOut ?? DateTime.now();
    return end.difference(clockIn);
  }

  bool get isActive => clockOut == null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'clockIn': clockIn.toIso8601String(),
      'clockOut': clockOut?.toIso8601String(),
    };
  }

  factory EmployeeShift.fromMap(Map<String, dynamic> map) {
    return EmployeeShift(
      id: map['id'],
      employeeId: map['employeeId'],
      employeeName: map['employeeName'],
      clockIn: DateTime.parse(map['clockIn']),
      clockOut:
          map['clockOut'] != null ? DateTime.parse(map['clockOut']) : null,
    );
  }
}
