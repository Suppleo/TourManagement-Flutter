import 'payment.dart';
import 'user.dart';
import 'tour.dart';

class Booking {
  final String id;
  final User? user;
  final Tour? tour;
  final List<dynamic>? passengers;
  final String? voucher;
  final String? paymentMethod;
  final String? status;
  final String? paymentStatus;
  final bool? isDeleted;
  final String? createdAt;
  final String? updatedAt;

  final Payment? latestPayment; // ✅ THÊM

  Booking({
    required this.id,
    this.user,
    this.tour,
    this.passengers,
    this.voucher,
    this.paymentMethod,
    this.status,
    this.paymentStatus,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.latestPayment, // ✅ THÊM
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? json['_id'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      tour: json['tour'] != null ? Tour.fromJson(json['tour']) : null,
      passengers: json['passengers'] ?? [],
      voucher: json['voucher'],
      paymentMethod: json['paymentMethod'],
      status: json['status'],
      paymentStatus: json['paymentStatus'],
      isDeleted: json['isDeleted'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      latestPayment: json['latestPayment'] != null
          ? Payment.fromJson(json['latestPayment'])
          : null, // ✅ THÊM
    );
  }

  Booking copyWith({
    User? user,
    Tour? tour,
    List<dynamic>? passengers,
    String? voucher,
    String? paymentMethod,
    String? status,
    String? paymentStatus,
    bool? isDeleted,
    String? createdAt,
    String? updatedAt,
    Payment? latestPayment, // ✅ THÊM
  }) {
    return Booking(
      id: id,
      user: user ?? this.user,
      tour: tour ?? this.tour,
      passengers: passengers ?? this.passengers,
      voucher: voucher ?? this.voucher,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latestPayment: latestPayment ?? this.latestPayment,
    );
  }
}
