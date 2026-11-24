import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/contact_controller.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final nameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  final _contact = Get.put(ContactController());
  final _api = Get.find<ApiService>();
  final _session = Get.find<SessionService>();

  List<dynamic> _myRequests = [];
  bool _loadingMine = true;

  @override
  void initState() {
    super.initState();
    _loadMine();
  }

  Future<void> _loadMine() async {
    final uid = _session.userId;
    if (uid == null) { setState(() => _loadingMine = false); return; }
    setState(() => _loadingMine = true);
    try {
      _myRequests = await _api.getContacts(userId: uid);
    } catch (_) {}
    if (mounted) setState(() => _loadingMine = false);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'resolved': return Colors.green;
      case 'in_progress': return AppColors.gold;
      case 'closed': return AppColors.textSecondary;
      default: return AppColors.primaryNavy;
    }
  }

  String _fmt(String? raw) {
    final d = DateTime.tryParse(raw ?? '');
    if (d == null) return '';
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year}, ${d.hour}:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: const BrandAppBar(title: 'Contact Us'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 5, bottom: 16, right: 16, left: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text('Send us a Message',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            BrandTextField(
                controller: nameCtrl,
                hint: 'Your Name',
                prefixIcon: Icons.person),
            const SizedBox(height: 12),
            BrandTextField(
                controller: mobileCtrl,
                hint: 'Mobile',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            BrandTextField(
                controller: emailCtrl,
                hint: 'Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            BrandTextField(
                controller: messageCtrl,
                hint: 'Message',
                prefixIcon: Icons.message,
                maxLines: 5),
            const SizedBox(height: 24),
            Obx(() => GradientButton(
              label: _contact.isSubmitting.value ? 'Sending...' : 'Submit',
              icon: Icons.send,
              onTap: () async {
                if (_contact.isSubmitting.value) return;
                if (nameCtrl.text.isEmpty ||
                    mobileCtrl.text.isEmpty ||
                    messageCtrl.text.isEmpty) {
                  Get.snackbar('Incomplete',
                      'Please fill name, mobile and message',
                      snackPosition: SnackPosition.BOTTOM);
                  return;
                }
                final ok = await _contact.submit(
                  name: nameCtrl.text.trim(),
                  mobile: mobileCtrl.text.trim(),
                  message: messageCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                );
                if (ok) {
                  messageCtrl.clear();
                  await _loadMine(); // refresh "Your Requests"
                  Get.snackbar('Sent', 'Thank you! We will contact you soon.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white);
                }
              },
            )),

            const SizedBox(height: 28),
            // Quick Action Cards
            Row(
              children: [
                Expanded(child: _quickCard(Icons.call, 'Call Us',
                    '9511677395\n9422835877', () => _launch('tel:9511677395'))),
                const SizedBox(width: 10),
                Expanded(child: _quickCard(Icons.email, 'Email',
                    'siddhi.ent22@gmail.com',
                        () => _launch('mailto:siddhi.ent22@gmail.com'))),
              ],
            ),
            const SizedBox(height: 10),
            _quickCard(
                Icons.location_on,
                'Visit Office',
                '37, Geeta Mandir Complex, Cotton Market, Subhash Road, Nagpur',
                () => _launch(
                    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('37, Geeta Mandir Complex, Cotton Market, Subhash Road, Nagpur')}')),

            // ── Your Requests (status + list) ───────────────────────────
            const SizedBox(height: 28),
            Text('Your Requests',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (_loadingMine)
              const Center(child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: AppColors.gold),
              ))
            else if (_myRequests.isEmpty)
              Text('You have not sent any request yet.',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary))
            else
              ..._myRequests.map((e) {
                final r = Map<String, dynamic>.from(e);
                final status = '${r['status'] ?? 'new'}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('${r['subject']?.toString().isNotEmpty == true ? r['subject'] : (r['message'] ?? '')}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(status.replaceAll('_', ' '),
                            style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: _statusColor(status))),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text('${r['message'] ?? ''}', maxLines: 3, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.schedule, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(_fmt('${r['created_at'] ?? ''}'),
                          style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.textMuted)),
                    ]),
                  ]),
                );
              }),
            const SizedBox(height: 50),

          ],
        ),
      ),
    );
  }

  Widget _quickCard(
      IconData icon, String title, String sub, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.accentGreen),
            ),
            const SizedBox(height: 8),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(sub,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 10.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _launch(String s) async {
    final uri = Uri.parse(s);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
