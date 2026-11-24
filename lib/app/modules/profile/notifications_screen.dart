import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/dummy_data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _icon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.chat_bubble;
      case 'follow':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return AppColors.info;
      case 'follow':
        return AppColors.accentGreen;
      default:
        return AppColors.textSecondary;
    }
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final list = DummyData.notifications;
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: const BrandAppBar(title: 'Notifications'),
      body: list.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_off,
              title: 'No Notifications',
              subtitle: 'You\'re all caught up!')
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final n = list[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: n.read
                        ? Colors.white.withOpacity(.6)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: n.read
                            ? Colors.transparent
                            : AppColors.accentGreen.withOpacity(.4)),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          SafeNetworkImage(
                              url: n.userAvatar,
                              width: 44,
                              height: 44,
                              borderRadius: BorderRadius.circular(22)),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: _color(n.type),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                              ),
                              child: Icon(_icon(n.type),
                                  color: Colors.white, size: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textPrimary),
                              children: [
                                TextSpan(
                                    text: '${n.userName} ',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                TextSpan(text: n.message),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(_ago(n.time),
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      )),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
