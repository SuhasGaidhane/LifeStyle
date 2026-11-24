// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:image_cropper/image_cropper.dart';
//
// import '../../theme/app_theme.dart';
//
// /// Full image editor screen.
// ///
// /// Features:
// /// 1. Loads the picked image from `Get.arguments` (file path)
// /// 2. Crop the image via image_cropper
// /// 3. Add a draggable text overlay
// /// 4. Change font family, font size, text color
// /// 5. Save returns a Map { path, overlay } back to the caller
// class ImageEditorScreen extends StatefulWidget {
//   const ImageEditorScreen({super.key});
//
//   @override
//   State<ImageEditorScreen> createState() => _ImageEditorScreenState();
// }
//
// class _ImageEditorScreenState extends State<ImageEditorScreen> {
//   late String imagePath;
//   String overlayText = '';
//   Offset textPosition = const Offset(50, 50);
//   double fontSize = 24;
//   Color textColor = Colors.white;
//   String fontFamily = 'Poppins';
//   bool textBg = true;
//   final textCtrl = TextEditingController();
//
//   final fonts = [
//     'Poppins',
//     'Roboto',
//     'Lobster',
//     'Pacifico',
//     'Dancing Script',
//     'Bebas Neue',
//     'Oswald',
//   ];
//
//   final colors = [
//     Colors.white,
//     Colors.black,
//     Colors.red,
//     Colors.yellow,
//     Colors.green,
//     Colors.blue,
//     Colors.purple,
//     Colors.orange,
//     Colors.pink,
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     imagePath = Get.arguments as String;
//   }
//
//   Future<void> _crop() async {
//     try {
//       final cropped = await ImageCropper().cropImage(
//         sourcePath: imagePath,
//         compressQuality: 90,
//         uiSettings: [
//           AndroidUiSettings(
//             toolbarTitle: 'Crop Image',
//             toolbarColor: AppColors.primaryNavy,
//             toolbarWidgetColor: Colors.white,
//             initAspectRatio: CropAspectRatioPreset.original,
//             lockAspectRatio: false,
//           ),
//           IOSUiSettings(title: 'Crop Image'),
//         ],
//       );
//       if (cropped != null) {
//         setState(() => imagePath = cropped.path);
//       }
//     } catch (e) {
//       Get.snackbar('Crop unavailable', 'Cropper plugin not active in demo',
//           snackPosition: SnackPosition.BOTTOM);
//     }
//   }
//
//   void _addText() {
//     textCtrl.text = overlayText;
//     Get.dialog(
//       AlertDialog(
//         title: const Text('Add Text'),
//         content: TextField(
//           controller: textCtrl,
//           autofocus: true,
//           decoration: const InputDecoration(hintText: 'Type here…'),
//         ),
//         actions: [
//           TextButton(onPressed: Get.back, child: const Text('Cancel')),
//           ElevatedButton(
//             onPressed: () {
//               setState(() => overlayText = textCtrl.text);
//               Get.back();
//             },
//             child: const Text('Add'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   TextStyle _textStyle() {
//     final base = TextStyle(
//       fontSize: fontSize,
//       color: textColor,
//       fontWeight: FontWeight.w600,
//       shadows: [
//         Shadow(
//             color: Colors.black.withOpacity(.6),
//             blurRadius: 6,
//             offset: const Offset(1, 1)),
//       ],
//     );
//     try {
//       return GoogleFonts.getFont(fontFamily, textStyle: base);
//     } catch (_) {
//       return base;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         title: Text('Edit Photo', style: GoogleFonts.poppins()),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(result: {
//               'path': imagePath,
//               'overlay': overlayText.isEmpty ? null : overlayText,
//             }),
//             child: Text('Save',
//                 style: GoogleFonts.poppins(
//                     color: AppColors.accentYellow,
//                     fontWeight: FontWeight.w700)),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: Center(
//               child: AspectRatio(
//                 aspectRatio: 1,
//                 child: Stack(
//                   children: [
//                     Positioned.fill(
//                       child: imagePath.startsWith('http')
//                           ? Image.network(imagePath, fit: BoxFit.contain)
//                           : Image.file(File(imagePath),
//                               fit: BoxFit.contain),
//                     ),
//                     if (overlayText.isNotEmpty)
//                       Positioned(
//                         left: textPosition.dx,
//                         top: textPosition.dy,
//                         child: GestureDetector(
//                           onPanUpdate: (d) => setState(() {
//                             textPosition += d.delta;
//                           }),
//                           child: Container(
//                             padding: textBg
//                                 ? const EdgeInsets.symmetric(
//                                     horizontal: 8, vertical: 4)
//                                 : null,
//                             decoration: textBg
//                                 ? BoxDecoration(
//                                     color: Colors.black.withOpacity(.4),
//                                     borderRadius:
//                                         BorderRadius.circular(4),
//                                   )
//                                 : null,
//                             child: Text(overlayText, style: _textStyle()),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           // Tools panel
//           Container(
//             color: Colors.grey.shade900,
//             padding: const EdgeInsets.symmetric(vertical: 10),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _toolBtn(Icons.crop, 'Crop', _crop),
//                     _toolBtn(Icons.text_fields, 'Text', _addText),
//                     _toolBtn(
//                         textBg
//                             ? Icons.format_color_fill
//                             : Icons.format_color_reset,
//                         'BG',
//                         () => setState(() => textBg = !textBg)),
//                   ],
//                 ),
//                 if (overlayText.isNotEmpty) ...[
//                   const SizedBox(height: 14),
//                   // Font size slider
//                   Row(
//                     children: [
//                       const SizedBox(width: 12),
//                       const Icon(Icons.format_size,
//                           color: Colors.white70),
//                       Expanded(
//                         child: Slider(
//                           min: 12,
//                           max: 80,
//                           value: fontSize,
//                           activeColor: AppColors.accentYellow,
//                           onChanged: (v) => setState(() => fontSize = v),
//                         ),
//                       ),
//                       Text('${fontSize.toInt()}',
//                           style:
//                               const TextStyle(color: Colors.white70)),
//                       const SizedBox(width: 12),
//                     ],
//                   ),
//                   // Color row
//                   SizedBox(
//                     height: 40,
//                     child: ListView(
//                       scrollDirection: Axis.horizontal,
//                       padding: const EdgeInsets.symmetric(horizontal: 10),
//                       children: colors
//                           .map((c) => GestureDetector(
//                                 onTap: () =>
//                                     setState(() => textColor = c),
//                                 child: Container(
//                                   width: 30,
//                                   height: 30,
//                                   margin: const EdgeInsets.symmetric(
//                                       horizontal: 4),
//                                   decoration: BoxDecoration(
//                                     color: c,
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: textColor == c
//                                           ? AppColors.accentYellow
//                                           : Colors.white24,
//                                       width: textColor == c ? 3 : 1,
//                                     ),
//                                   ),
//                                 ),
//                               ))
//                           .toList(),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   // Font row
//                   SizedBox(
//                     height: 36,
//                     child: ListView(
//                       scrollDirection: Axis.horizontal,
//                       padding: const EdgeInsets.symmetric(horizontal: 10),
//                       children: fonts
//                           .map((f) => GestureDetector(
//                                 onTap: () =>
//                                     setState(() => fontFamily = f),
//                                 child: Container(
//                                   margin: const EdgeInsets.symmetric(
//                                       horizontal: 4),
//                                   padding: const EdgeInsets.symmetric(
//                                       horizontal: 12, vertical: 6),
//                                   decoration: BoxDecoration(
//                                     color: fontFamily == f
//                                         ? AppColors.accentYellow
//                                         : Colors.white12,
//                                     borderRadius:
//                                         BorderRadius.circular(20),
//                                   ),
//                                   child: Text(f,
//                                       style: GoogleFonts.getFont(f,
//                                           color: fontFamily == f
//                                               ? Colors.black
//                                               : Colors.white)),
//                                 ),
//                               ))
//                           .toList(),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _toolBtn(IconData icon, String label, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(8),
//       child: Padding(
//         padding: const EdgeInsets.all(8),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, color: Colors.white),
//             const SizedBox(height: 4),
//             Text(label,
//                 style: const TextStyle(
//                     color: Colors.white, fontSize: 11)),
//           ],
//         ),
//       ),
//     );
//   }
// }
