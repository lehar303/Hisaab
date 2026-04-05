class Budget {
  final int? id;
  final String name;
  final double amount;
  final int month;
  final int year;
  final double carryover;

  const Budget({
    this.id,
    required this.name,
    required this.amount,
    required this.month,
    required this.year,
    required this.carryover,
  });

  double get effective => amount + carryover;

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      name: map['name'] as String,
      amount: map['amount'] as double,
      month: map['month'] as int,
      year: map['year'] as int,
      carryover: map['carryover'] as double,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'month': month,
      'year': year,
      'carryover': carryover,
    };
  }
}