import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';
import 'post_share.dart' show kAppPlayStoreLink;

bool _isVideo(String url) {
  final u = url.toLowerCase().split('?').first;
  return u.endsWith('.mp4') ||
      u.endsWith('.mov') ||
      u.endsWith('.webm') ||
      u.endsWith('.m3u8') ||
      u.endsWith('.mkv');
}

String _imgExt(String url) {
  final clean = url.toLowerCase().split('?').first;
  for (final e in ['png', 'jpg', 'jpeg', 'webp', 'gif']) {
    if (clean.endsWith('.$e')) return e;
  }
  return 'jpg';
}

/// Builds a human-readable summary of the whole shop.
String buildShopShareText(ShopModel s) {
  final b = StringBuffer();
  b.writeln(s.firmName);
  if (s.categories.isNotEmpty) b.writeln(s.categories.join(', '));
  b.writeln();

  if (s.ownerName.isNotEmpty) b.writeln('Owner: ${s.ownerName}');
  if (s.mobile.isNotEmpty) b.writeln('Mobile: ${s.mobile}');
  if (s.otherMobile.isNotEmpty) b.writeln('Alt. Mobile: ${s.otherMobile}');
  if (s.email.isNotEmpty) b.writeln('Email: ${s.email}');

  final loc = [
    if (s.address.isNotEmpty) s.address,
    if (s.location.isNotEmpty) s.location,
    if (s.city.isNotEmpty) s.city,
  ].join(', ');
  if (loc.isNotEmpty) b.writeln('Address: $loc');

  if (s.description.isNotEmpty) {
    b.writeln();
    b.writeln('About:');
    b.writeln(s.description.trim());
  }

  if (s.products.isNotEmpty) {
    b.writeln();
    b.writeln('Products:');
    for (final p in s.products) {
      final price = p.price > 0 ? ' — ₹${p.price}' : '';
      b.writeln('• ${p.name}$price');
    }
  }

  if (s.clientList.isNotEmpty) {
    b.writeln();
    b.writeln('Trusted by:');
    for (final c in s.clientList) {
      if (c.name.isNotEmpty) b.writeln('• ${c.name}');
    }
  }

  b.writeln();
  b.writeln('Get the app: $kAppPlayStoreLink');
  b.write('Shared via Life Style Exposure');
  return b.toString();
}

/// Shares the shop: full details text + the shop's photos as attachments.
/// Downloads photos to a temp dir first so they travel with the share sheet.
/// Falls back to text-only sharing if there are no photos or downloads fail.
Future<void> shareShopWithDetails(ShopModel s) async {
  final text = buildShopShareText(s);

  // Pick a single image — the shop's main photo (first non-video gallery
  // image, falling back to the thumbnail).
  String shopImage = '';
  for (final u in [...s.profileImages, s.thumbnail]) {
    if (u.trim().isNotEmpty && !_isVideo(u)) {
      shopImage = u;
      break;
    }
  }

  if (shopImage.isEmpty) {
    await Share.share(text);
    return;
  }

  Get.snackbar('Preparing…', 'Getting the shop details ready to share',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1));

  try {
    final resp = await http
        .get(Uri.parse(shopImage))
        .timeout(const Duration(seconds: 20));
    if (resp.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/shop_${s.id}.${_imgExt(shopImage)}');
      await file.writeAsBytes(resp.bodyBytes);
      await Share.shareXFiles([XFile(file.path)], text: text);
    } else {
      await Share.share(text);
    }
  } catch (_) {
    await Share.share(text);
  }
}
