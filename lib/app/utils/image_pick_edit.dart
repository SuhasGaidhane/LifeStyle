import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

/// Shows a Gallery/Camera chooser, then opens the image editor on the picked
/// photo. Returns the edited image as a [File], or null if the user cancels
/// at any step. Reusable across shop editor, user profile, etc.
Future<File?> pickAndEditImage(BuildContext context) async {
  final source = await _chooseSource(context);
  if (source == null) return null;

  final XFile? picked =
      await ImagePicker().pickImage(source: source, imageQuality: 100);
  if (picked == null) return null;
  if (!context.mounted) return null;

  return _openEditor(context, File(picked.path));
}

/// Bottom sheet asking Gallery vs Camera.
Future<ImageSource?> _chooseSource(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Gallery'),
            subtitle: const Text('Choose a photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Camera'),
            subtitle: const Text('Take a new photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Opens ProImageEditor on [imageFile]; returns the edited image file.
Future<File?> _openEditor(BuildContext context, File imageFile) async {
  final Uint8List bytes = await imageFile.readAsBytes();
  if (!context.mounted) return null;

  File? result;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ProImageEditor.memory(
        bytes,
        callbacks: ProImageEditorCallbacks(
          onImageEditingComplete: (Uint8List editedBytes) async {
            final tempDir = Directory.systemTemp;
            final editedFile = await File(
              '${tempDir.path}/edit_${DateTime.now().millisecondsSinceEpoch}.png',
            ).create();
            await editedFile.writeAsBytes(editedBytes);
            result = editedFile;
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
        configs: const ProImageEditorConfigs(),
      ),
    ),
  );
  return result;
}
