import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';

/// Full-screen, pinch-to-zoom image viewer.
class ImageViewerScreen extends StatelessWidget {
  final String url;
  const ImageViewerScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoView(
            imageProvider: NetworkImage(url),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4,
            initialScale: PhotoViewComputedScale.contained,
            loadingBuilder: (_, __) => const Center(
              child: SizedBox(
                width: 32, height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              ),
            ),
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 60),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the zoomable viewer for [url] (no-op if empty).
void showImageViewer(String url) {
  if (url.trim().isEmpty) return;
  Get.to(() => ImageViewerScreen(url: url),
      transition: Transition.fadeIn, fullscreenDialog: true);
}
