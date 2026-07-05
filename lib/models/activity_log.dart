class ActivityLog {
  final int? id;
  final DateTime date;
  final int? employeeId;
  final String employeeName;
  final String action;
  final String description;

  ActivityLog({
    this.id,
    required this.date,
    this.employeeId,
    required this.employeeName,
    required this.action,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'employeeId': employeeId,
      'employeeName': employeeName,
      'action': action,
      'description': description,
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'],
      date: DateTime.parse(map['date']),
      employeeId: map['employeeId'],
      employeeName: map['employeeName'],
      action: map['action'],
      description: map['description'],
    );
  }
}
