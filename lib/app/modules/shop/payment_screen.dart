import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../controllers/shop_controller.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _api = Get.find<ApiService>();
  late final Razorpay _razorpay;
  bool processing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ── Payment flow ────────────────────────────────────────────────────
  Future<void> _startPayment() async {
    if (processing) return;
    final c = Get.find<ShopController>();
    final uid = Get.find<SessionService>().userId;
    if (uid == null) {
      Get.snackbar('Not logged in', 'Please log in again',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (c.selectedCategories.isEmpty) {
      Get.snackbar('No service', 'Please select at least one service',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => processing = true);
    try {
      // 1. Ask the server to create an order (amount computed server-side).
      final order = await _api.createRazorpayOrder(
        userId: uid,
        count: c.selectedCategories.length,
      );

      // 2. Open Razorpay checkout with that order.
      final n = c.selectedCategories.length;
      _razorpay.open({
        'key': order['key_id'],
        'order_id': order['order_id'],
        'amount': order['amount'], // paise
        'currency': order['currency'] ?? 'INR',
        'name': 'Life Style Exposure',
        'description': 'Shop listing ($n service${n > 1 ? 's' : ''})',
        'prefill': {
          'contact': c.mobileCtrl.text.trim(),
          'email': c.emailCtrl.text.trim(),
        },
        'theme': {'color': '#D4A853'},
      });
      // processing stays true until a Razorpay callback fires.
    } on ApiException catch (e) {
      if (mounted) setState(() => processing = false);
      Get.snackbar('Payment error', e.message,
          snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      if (mounted) setState(() => processing = false);
      Get.snackbar('Error', 'Could not start payment. Try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse r) async {
    try {
      // 3. Verify the signature on the server before creating the shop.
      await _api.verifyRazorpayPayment(
        orderId: r.orderId ?? '',
        paymentId: r.paymentId ?? '',
        signature: r.signature ?? '',
      );
      // 4. Verified → create the shop(s).
      await Get.find<ShopController>().confirmPaymentAndCreateShops();
    } on ApiException catch (e) {
      Get.snackbar('Verification failed', e.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } catch (_) {
      Get.snackbar('Error',
          'Payment received but verification failed. Contact support with your payment id.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  void _onPaymentError(PaymentFailureResponse r) {
    if (mounted) setState(() => processing = false);
    final msg = (r.message == null || r.message!.isEmpty)
        ? 'Payment cancelled or failed'
        : r.message!;
    Get.snackbar('Payment failed', msg, snackPosition: SnackPosition.BOTTOM);
  }

  void _onExternalWallet(ExternalWalletResponse r) {
    // Razorpay handles the wallet flow; nothing extra needed here.
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ShopController>();
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: const BrandAppBar(title: 'Payment'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected Services',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: c.selectedCategories
                        .map((cat) => Chip(
                              label: Text(cat),
                              backgroundColor: AppColors.accentYellow,
                              labelStyle: GoogleFonts.poppins(fontSize: 11),
                            ))
                        .toList(),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Payable',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('₹${c.totalPrice}',
                          style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryNavy)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Razorpay info panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.goldLight.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.goldBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: AppColors.gold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Secure payment by Razorpay',
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                            'Pay with UPI, Cards, Net Banking or Wallets on the next secure screen.',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            GradientButton(
              label: processing ? 'Processing…' : 'Pay ₹${c.totalPrice}',
              icon: Icons.lock_outline,
              loading: processing,
              onTap: _startPayment,
            ),
            const SizedBox(height: 14),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('256-bit secure · Powered by Razorpay',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
