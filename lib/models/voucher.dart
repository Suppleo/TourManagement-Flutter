class Voucher {
  final String id;
  final String code;
  final String type;
  final double value;
  final String? conditions;
  final String? validFrom;
  final String? validTo;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  Voucher({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.conditions,
    this.validFrom,
    this.validTo,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
    id: json['id'],
    code: json['code'],
    type: json['type'],
    value: (json['value'] as num).toDouble(),
    conditions: json['conditions'],
    validFrom: json['validFrom'],
    validTo: json['validTo'],
    status: json['status'],
    createdAt: json['createdAt'],
    updatedAt: json['updatedAt'],
  );
}
