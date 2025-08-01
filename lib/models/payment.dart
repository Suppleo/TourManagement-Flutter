class Payment {
  final String id;
  final String booking;
  final String method;
  final double amount;
  final String status;
  final String? transactionId;
  final String? createdAt;
  final String? updatedAt;

  Payment({
    required this.id,
    required this.booking,
    required this.method,
    required this.amount,
    required this.status,
    this.transactionId,
    this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'],
    booking: json['booking'],
    method: json['method'],
    amount: (json['amount'] as num).toDouble(),
    status: json['status'],
    transactionId: json['transactionId'],
    createdAt: json['createdAt'],
    updatedAt: json['updatedAt'],
  );
}
