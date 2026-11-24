import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:video_player/video_player.dart';

import '../../controllers/post_controller.dart';

class UploadPostScreen extends StatefulWidget {
  const UploadPostScreen({super.key});

  @override
  State<UploadPostScreen> createState() => _UploadPostScreenState();
}

class _UploadPostScreenState extends State<UploadPostScreen> {
  final TextEditingController descCtrl = TextEditingController();

  final List<File> images = [];
  final List<File> videos = [];

  bool loading = false;

  // ─────────────────────────────────────────────────────────────
  // PICK IMAGES
  // ─────────────────────────────────────────────────────────────
  /// Ask the user to choose Gallery or Camera before picking image(s).
  void chooseImageSource() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              subtitle: const Text('Choose one or more photos'),
              onTap: () { Navigator.pop(ctx); pickFromGallery(); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              subtitle: const Text('Take a new photo'),
              onTap: () { Navigator.pop(ctx); pickFromCamera(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> pickFromGallery() async {
    final files = await ImagePicker().pickMultiImage(imageQuality: 100);
    if (files.isEmpty) return;
    for (final img in files) {
      await openEditor(File(img.path));
    }
  }

  Future<void> pickFromCamera() async {
    final XFile? shot = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );
    if (shot == null) return;
    await openEditor(File(shot.path));
  }

  // ─────────────────────────────────────────────────────────────
  // PICK VIDEOS
  // ─────────────────────────────────────────────────────────────
  Future<void> pickVideo() async {
    final picker = ImagePicker();

    final XFile? file = await picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (file == null) return;

    setState(() {
      videos.add(File(file.path));
    });
  }

  // ─────────────────────────────────────────────────────────────
  // OPEN IMAGE EDITOR
  // ─────────────────────────────────────────────────────────────
  Future<void> openEditor(File imageFile) async {
    final Uint8List bytes = await imageFile.readAsBytes();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProImageEditor.memory(
          bytes,

          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List editedBytes) async {

              final tempDir = Directory.systemTemp;

              final editedFile = await File(
                '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png',
              ).create();

              await editedFile.writeAsBytes(editedBytes);

              if (!mounted) return;

              setState(() {
                images.add(editedFile);
              });

              Navigator.pop(context);
            },
          ),

          configs: const ProImageEditorConfigs(),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UPLOAD POST
  // ─────────────────────────────────────────────────────────────
  Future<void> uploadPost() async {
    if (images.isEmpty && videos.isEmpty && descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add media or a description")),
      );
      return;
    }
    if (loading) return;
    setState(() => loading = true);
    final c = Get.isRegistered<PostController>()
        ? Get.find<PostController>()
        : Get.put(PostController());
    await c.uploadPost(
      media: [...images, ...videos],
      description: descCtrl.text,
    );
    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    descCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F8FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Create Post",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ─────────────────────────────
              // TITLE
              // ─────────────────────────────
              const Text(
                "Upload Media",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Add photos and videos for your post",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              // ─────────────────────────────
              // BUTTONS
              // ─────────────────────────────
              Row(
                children: [

                  Expanded(
                    child: GestureDetector(
                      onTap: chooseImageSource,

                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),

                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [

                            const Icon(
                              Icons.image_outlined,
                              size: 38,
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              "Select Images",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: GestureDetector(
                      onTap: pickVideo,

                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),

                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [

                            const Icon(
                              Icons.video_collection_outlined,
                              size: 38,
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              "Select Video",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ─────────────────────────────
              // IMAGES PREVIEW
              // ─────────────────────────────
              if (images.isNotEmpty) ...[

                const Text(
                  "Images",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  height: 120,

                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,

                    separatorBuilder: (_, __) =>
                    const SizedBox(width: 12),

                    itemBuilder: (_, i) {

                      return Stack(
                        children: [

                          ClipRRect(
                            borderRadius:
                            BorderRadius.circular(18),

                            child: Image.file(
                              images[i],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),

                          Positioned(
                            top: 6,
                            right: 6,

                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  images.removeAt(i);
                                });
                              },

                              child: Container(
                                padding:
                                const EdgeInsets.all(5),

                                decoration:
                                const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),

                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 26),
              ],

              // ─────────────────────────────
              // VIDEOS PREVIEW
              // ─────────────────────────────
              if (videos.isNotEmpty) ...[

                const Text(
                  "Videos",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  height: 120,

                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: videos.length,

                    separatorBuilder: (_, __) =>
                    const SizedBox(width: 12),

                    itemBuilder: (_, i) {

                      return Stack(
                        children: [

                          Container(
                            width: 120,
                            height: 120,

                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius:
                              BorderRadius.circular(18),
                            ),

                            child: const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          Positioned(
                            top: 6,
                            right: 6,

                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  videos.removeAt(i);
                                });
                              },

                              child: Container(
                                padding:
                                const EdgeInsets.all(5),

                                decoration:
                                const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),

                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 26),
              ],

              // ─────────────────────────────
              // DESCRIPTION
              // ─────────────────────────────
              const Text(
                "Description",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),

                child: TextField(
                  controller: descCtrl,
                  maxLines: 6,

                  decoration: const InputDecoration(
                    hintText:
                    "Write something about your post...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ─────────────────────────────
              // UPLOAD BUTTON
              // ─────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton(
                  onPressed: loading ? null : uploadPost,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(18),
                    ),
                  ),

                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text(
                          "Upload Post",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// VIDEO PREVIEW WIDGET
// ─────────────────────────────────────────────────────────────
class VideoPreviewCard extends StatefulWidget {
  final File file;

  const VideoPreviewCard({
    super.key,
    required this.file,
  });

  @override
  State<VideoPreviewCard> createState() =>
      _VideoPreviewCardState();
}

class _VideoPreviewCardState
    extends State<VideoPreviewCard> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(18),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),

      child: SizedBox(
        width: 120,
        height: 120,

        child: VideoPlayer(controller),
      ),
    );
  }
}