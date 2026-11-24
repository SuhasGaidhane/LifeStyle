import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';

String _shareExtFor(String url, {required bool isVideo}) {
  if (isVideo) return 'mp4';
  final clean = url.toLowerCase().split('?').first;
  for (final e in ['png', 'jpg', 'jpeg', 'webp', 'gif']) {
    if (clean.endsWith('.$e')) return e;
  }
  return 'jpg';
}

/// Play Store link shared alongside every post.
const String kAppPlayStoreLink =
    'https://play.google.com/store/apps/details?id=com.varia.lifestyle&pcampaignid=web_share';

/// Builds the share caption: uploader details + description + app link.
String buildPostShareText(PostModel p) {
  final b = StringBuffer();

  // Uploader details.
  final who = p.userName.trim();
  if (who.isNotEmpty) {
    b.write('Posted by $who');
    if (p.userCity.trim().isNotEmpty) b.write(' · ${p.userCity.trim()}');
    b.writeln();
  }
  if (p.contactNumber.trim().isNotEmpty) {
    b.writeln('Contact: ${p.contactNumber.trim()}');
  }

  if (p.description.trim().isNotEmpty) {
    if (b.isNotEmpty) b.writeln();
    b.writeln(p.description.trim());
  }

  b.writeln();
  b.writeln('Get the app: $kAppPlayStoreLink');
  b.write('Shared via Life Style Exposure');
  return b.toString();
}

/// Shares a post: caption text + all its images/videos as attachments.
/// Media is downloaded to a temp dir first so it travels with the share sheet.
/// Falls back to text-only sharing if there's no media or downloads fail.
Future<void> sharePostWithMedia(PostModel p) async {
  final caption = buildPostShareText(p);

  if (p.media.isEmpty) {
    await Share.share(caption);
    return;
  }

  Get.snackbar('Preparing…', 'Getting the post ready to share',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1));

  try {
    final dir = await getTemporaryDirectory();
    final files = <XFile>[];
    for (var i = 0; i < p.media.length; i++) {
      final m = p.media[i];
      if (m.url.trim().isEmpty) continue;
      try {
        final resp = await http
            .get(Uri.parse(m.url))
            .timeout(const Duration(seconds: 20));
        if (resp.statusCode != 200) continue;
        final ext = _shareExtFor(m.url, isVideo: m.isVideo);
        final file = File('${dir.path}/lse_${p.id}_$i.$ext');
        await file.writeAsBytes(resp.bodyBytes);
        files.add(XFile(file.path));
      } catch (_) {
        // Skip a file that fails to download; keep the rest.
      }
    }
    if (files.isNotEmpty) {
      await Share.shareXFiles(files, text: caption);
    } else {
      await Share.share(caption);
    }
  } catch (_) {
    await Share.share(caption);
  }
}
