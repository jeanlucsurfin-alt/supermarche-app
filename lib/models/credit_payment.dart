class CreditPayment {
  final int? id;
  final int customerId;
  final double amount;
  final DateTime date;
  final String? note;

  CreditPayment({
    this.id,
    required this.customerId,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory CreditPayment.fromMap(Map<String, dynamic> map) {
    return CreditPayment(
      id: map['id'],
      customerId: map['customerId'],
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      note: map['note'],
    );
  }
}
