import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:final_mobile/screens/customer/payment/stripe_checkout_webview.dart';

import '../core/network/graphql_service.dart';
import '../graphql/mutations/booking_mutations.dart';
import '../graphql/mutations/payment_mutations.dart';

import 'package:provider/provider.dart';
import 'package:final_mobile/providers/booking_provider.dart';

class BookingForm extends StatefulWidget {
  final String tourId;
  const BookingForm({super.key, required this.tourId});

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  int adults = 1;
  int children = 0;
  String paymentMethod = 'cash';
  String voucher = '';
  bool loading = false;
  bool showSuccess = false;
  String? errorMessage;

  Future<void> submitBooking() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    final client = GraphQLService.clientNotifier.value;
    if (client == null) {
      setState(() {
        loading = false;
        errorMessage = 'GraphQL client chưa được khởi tạo';
      });
      return;
    }

    final passengers = [
      ...List.generate(adults, (_) => {'name': 'Adult', 'age': 30, 'type': 'adult'}),
      ...List.generate(children, (_) => {'name': 'Child', 'age': 10, 'type': 'child'}),
    ];

    try {
      final result = await client.mutate(
        MutationOptions(
          document: gql(mutationCreateBooking),
          variables: {
            'input': {
              'tour': widget.tourId,
              'passengers': passengers,
              'voucher': voucher.isNotEmpty ? voucher : null,
              'paymentMethod': paymentMethod,
            },
          },
        ),
      );

      if (result.hasException) throw result.exception!;
      final bookingId = result.data?['createBooking']?['id'];

      if (paymentMethod == 'credit_card') {
        final checkoutResult = await client.mutate(MutationOptions(
          document: gql(mutationCheckout),
          variables: {
            'bookingId': bookingId,
            'method': 'Stripe',
          },
        ));

        if (checkoutResult.hasException) throw checkoutResult.exception!;

        final payUrl = checkoutResult.data?['checkout']?['payUrl'];
        final paymentId = checkoutResult.data?['checkout']?['payment']?['id'];

        if (payUrl == null || paymentId == null) {
          throw 'Không nhận được đường dẫn thanh toán hoặc paymentId.';
        }

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StripeCheckoutWebView(
              payUrl: payUrl,
              paymentId: paymentId,
            ),
          ),
        );

        if (result == true) {
          final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
          await bookingProvider.fetchBookings();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Thanh toán thành công qua Stripe!')),
            );
          }
        } else {
          throw '❌ Thanh toán chưa hoàn tất hoặc bị hủy.';
        }
      } else {
        setState(() {
          showSuccess = true;
          adults = 1;
          children = 0;
          paymentMethod = 'cash';
          voucher = '';
        });
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => showSuccess = false);
        });
      }
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPassengers = adults + children;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header với style đẹp hơn
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.event_note, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                'Đặt Tour',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Success message (giữ nguyên)
        if (showSuccess)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Expanded(child: Text('Đặt tour thành công!')),
              ],
            ),
          ),

        // Passenger section với style đẹp hơn
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.people, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Số lượng khách',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPassengerPicker(
                      'Người lớn (18+)',
                      adults,
                          (val) => setState(() => adults = val),
                      min: 1,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPassengerPicker(
                      'Trẻ em (0-17)',
                      children,
                          (val) => setState(() => children = val),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Voucher input với style đẹp hơn
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Mã giảm giá (tùy chọn)',
            prefixIcon: const Icon(Icons.card_giftcard, color: Colors.orange),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          onChanged: (value) => voucher = value,
        ),

        const SizedBox(height: 12),

        // Payment section với style đẹp hơn
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.payment, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Phương thức thanh toán',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              buildPaymentRadio('momo', '📱 MoMo'),
              buildPaymentRadio('vnpay', '🏦 VNPay'),
              buildPaymentRadio('credit_card', '💳 Thẻ tín dụng (Stripe)'),
              buildPaymentRadio('cash', '💵 Tiền mặt'),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Error message (giữ nguyên)
        if (errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),

        if (errorMessage != null) const SizedBox(height: 12),

        // Submit button với style đẹp hơn
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: loading ? null : submitBooking,
            icon: loading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.check, color: Colors.white),
            label: Text(
              loading ? 'Đang xử lý...' : 'Đặt tour ($totalPassengers khách)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: loading ? Colors.grey : Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: loading ? 0 : 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerPicker(String label, int value, void Function(int) onChanged, {int min = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => onChanged((value > min) ? value - 1 : min),
              icon: const Icon(Icons.remove),
              style: IconButton.styleFrom(
                backgroundColor: value > min ? Colors.blue.shade100 : Colors.grey.shade200,
                foregroundColor: value > min ? Colors.blue : Colors.grey,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildPaymentRadio(String value, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: paymentMethod == value ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: paymentMethod == value ? Colors.blue : Colors.grey.shade300,
          width: paymentMethod == value ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: paymentMethod,
        onChanged: (val) => setState(() => paymentMethod = val!),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: paymentMethod == value ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        activeColor: Colors.blue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
