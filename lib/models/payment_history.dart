class PaymentRecord {
  final String id;
  final String plan;
  final double amount;
  final DateTime timestamp;
  final String status; // success, failed, pending

  PaymentRecord({
    required this.id,
    required this.plan,
    required this.amount,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'plan': plan,
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
        'status': status,
      };

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
        id: json['id'] ?? '',
        plan: json['plan'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
        status: json['status'] ?? 'pending',
      );
}
