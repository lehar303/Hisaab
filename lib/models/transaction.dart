class Transaction {
  final int? id;
  final String txnType;
  final double amount;
  final String party;
  final String date;
  final String rawSms;
  final int? categoryId;
  final String? categoryName;
  final String? categoryParent;

  const Transaction({
    this.id,
    required this.txnType,
    required this.amount,
    required this.party,
    required this.date,
    required this.rawSms,
    this.categoryId,
    this.categoryName,
    this.categoryParent,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      txnType: map['txn_type'] as String,
      amount: map['amount'] as double,
      party: map['party'] as String,
      date: map['date'] as String,
      rawSms: map['raw_sms'] as String,
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String?,
      categoryParent: map['category_parent'] as String?,
    );
  }
}