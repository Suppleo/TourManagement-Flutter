class Log {
  final String id;
  final String admin;
  final String action;
  final String? detail;
  final String? createdAt;

  Log({
    required this.id,
    required this.admin,
    required this.action,
    this.detail,
    this.createdAt,
  });

  factory Log.fromJson(Map<String, dynamic> json) => Log(
    id: json['id'],
    admin: json['admin'],
    action: json['action'],
    detail: json['detail'],
    createdAt: json['createdAt'],
  );
}
