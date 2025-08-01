import 'package:flutter/material.dart';
import '../models/voucher.dart';

class VoucherCard extends StatelessWidget {
  final Voucher voucher;
  final VoidCallback? onTap;

  const VoucherCard({super.key, required this.voucher, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(voucher.code),
        subtitle: Text('Giá trị: ${voucher.value} (${voucher.type})'),
        onTap: onTap,
      ),
    );
  }
}
