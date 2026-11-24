import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/location_controller.dart';
import '../../controllers/shop_controller.dart';
import '../../data/models.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_pick_edit.dart';
import '../../utils/location_helper.dart';
import '../../widgets/common_widgets.dart';

/// Full shop editor: details + images + products + latest updates + clients.
class UpdateShopScreen extends StatefulWidget {
  const UpdateShopScreen({super.key});

  @override
  State<UpdateShopScreen> createState() => _UpdateShopScreenState();
}

class _UpdateShopScreenState extends State<UpdateShopScreen> {
  final _api = Get.find<ApiService>();
  final _picker = ImagePicker();
  final _location = Get.find<LocationController>();

  String? _selState;
  String? _selCity;

  late final String shopId;

  // detail sub-lists (raw maps with ids)
  Map<String, dynamic> _detail = {};
  List<dynamic> _images = [];
  List<dynamic> _products = [];
  List<dynamic> _updates = [];
  List<dynamic> _onsite = [];
  List<dynamic> _upcoming = [];
  List<dynamic> _clients = [];

  /// True when this shop's service is a PREMIUM service — controls which
  /// sections show (no products; adds Upcoming Project; renames On-Site Work).
  bool get _isPremium => _s(_detail, 'category_slug') == 'premium';

  bool _loading = true;
  bool _savingDetails = false;
  bool _detectingLoc = false;

  // detail controllers
  final _shopName = TextEditingController();
  final _owner = TextEditingController();
  final _mobile = TextEditingController();
  final _other = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _desc = TextEditingController();

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    shopId = (arg is ShopModel) ? arg.id : '${arg ?? ''}';
    _load();
  }

  @override
  void dispose() {
    for (final c in [_shopName, _owner, _mobile, _other, _email, _address,
        _lat, _lng, _desc]) {
      c.dispose();
    }
    super.dispose();
  }

  String _s(Map m, String k) => (m[k] ?? '').toString();

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await _api.getShopDetail(shopId);
      _detail = d;
      _images = (d['images'] is List) ? d['images'] : [];
      _products = (d['products'] is List) ? d['products'] : [];
      _updates = (d['latest_updates'] is List) ? d['latest_updates'] : [];
      _onsite = (d['onsite_works'] is List) ? d['onsite_works'] : [];
      _upcoming = (d['upcoming_projects'] is List) ? d['upcoming_projects'] : [];
      _clients = (d['clients'] is List) ? d['clients'] : [];

      _shopName.text = _s(d, 'shop_name');
      _owner.text = _s(d, 'owner_name');
      _mobile.text = _s(d, 'owner_mobile');
      _other.text = _s(d, 'alternative_number');
      _email.text = _s(d, 'email');
      _address.text = _s(d, 'address');
      _selState = _s(d, 'state').isEmpty ? null : _s(d, 'state');
      _selCity = _s(d, 'city').isEmpty ? null : _s(d, 'city');
      _location.loadStates();
      if (_selState != null) _location.loadDistricts(_selState!);
      _lat.text = _s(d, 'latitude');
      _lng.text = _s(d, 'longitude');
      _desc.text = _s(d, 'story_description');
    } catch (_) {
      Get.snackbar('Error', 'Could not load shop', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveDetails() async {
    setState(() => _savingDetails = true);
    try {
      await _api.updateShop(shopId, {
        'shop_name': _shopName.text.trim(),
        'owner_name': _owner.text.trim(),
        'owner_mobile': _mobile.text.trim(),
        'alternative_number': _other.text.trim(),
        'email': _email.text.trim(),
        'address': _address.text.trim(),
        'state': _selState ?? '',
        'city': _selCity ?? '',
        'district': _selCity ?? '',
        'latitude': _lat.text.trim().isEmpty ? null : _lat.text.trim(),
        'longitude': _lng.text.trim().isEmpty ? null : _lng.text.trim(),
        'story_description': _desc.text.trim(),
      });
      if (Get.isRegistered<ShopController>()) Get.find<ShopController>().loadMyShops();
      Get.snackbar('Saved', 'Shop details updated',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green, colorText: Colors.white);
    } on ApiException catch (e) {
      Get.snackbar('Failed', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar('Error', 'Could not save details', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _savingDetails = false);
    }
  }

  /// Camera/Gallery chooser + image editor (shared helper). Used for the
  /// owner photo, shop images, product/client images, and the image option
  /// in latest-updates / on-site work.
  /// Fills the latitude/longitude fields from the device's current GPS.
  Future<void> _detectLocation() async {
    if (_detectingLoc) return;
    setState(() => _detectingLoc = true);
    try {
      final loc = await detectCurrentLocation();
      _lat.text = loc.latitude.toStringAsFixed(7);
      _lng.text = loc.longitude.toStringAsFixed(7);
      Get.snackbar('Location detected',
          'Lat ${_lat.text}, Lng ${_lng.text}',
          snackPosition: SnackPosition.BOTTOM);
    } on LocationException catch (e) {
      Get.snackbar('Location', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar('Location', 'Could not detect location. Try again.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _detectingLoc = false);
    }
  }

  Future<File?> _pickImage() => pickAndEditImage(context);

  Future<File?> _pickVideo() async {
    final x = await _picker.pickVideo(source: ImageSource.gallery);
    return x == null ? null : File(x.path);
  }

  Future<void> _addChild(String type, {required String fileField, File? file, Map<String, String> fields = const {}}) async {
    try {
      await _api.addShopChild(shopId, type, fileField: fileField, file: file, fields: fields);
      await _load();
      Get.snackbar('Added', 'Saved successfully', snackPosition: SnackPosition.BOTTOM);
    } on ApiException catch (e) {
      Get.snackbar('Failed', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar('Error', 'Could not add', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _deleteChild(String type, String id) async {
    try {
      await _api.deleteShopChild(shopId, type, id);
      await _load();
    } catch (_) {
      Get.snackbar('Error', 'Could not delete', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: const BrandAppBar(title: 'Edit Shop'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ownerImageSection(),
                const SizedBox(height: 24),
                _title('Shop Details'),
                const SizedBox(height: 12),
                BrandTextField(controller: _shopName, hint: 'Shop / Firm Name', prefixIcon: Icons.store),
                const SizedBox(height: 10),
                BrandTextField(controller: _owner, hint: 'Owner Name', prefixIcon: Icons.person),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: BrandTextField(controller: _mobile, hint: 'Mobile', prefixIcon: Icons.phone, keyboardType: TextInputType.phone)),
                  const SizedBox(width: 10),
                  Expanded(child: BrandTextField(controller: _other, hint: 'Other No.', prefixIcon: Icons.phone_iphone, keyboardType: TextInputType.phone)),
                ]),
                const SizedBox(height: 10),
                BrandTextField(controller: _email, hint: 'Email', prefixIcon: Icons.email),
                const SizedBox(height: 10),
                BrandTextField(controller: _address, hint: 'Address', prefixIcon: Icons.home, maxLines: 2),
                const SizedBox(height: 10),
                Obx(() => _locDropdown(
                      hint: 'State',
                      icon: Icons.map,
                      value: _selState,
                      items: _location.stateNames,
                      onChanged: (v) {
                        setState(() { _selState = v; _selCity = null; });
                        if (v != null) _location.loadDistricts(v);
                      },
                    )),
                const SizedBox(height: 10),
                Obx(() => _locDropdown(
                      hint: 'City',
                      icon: Icons.location_city,
                      value: _selCity,
                      items: _location.districtNames,
                      onChanged: (v) => setState(() => _selCity = v),
                    )),
                const SizedBox(height: 10),
                // Location: enter manually below, or auto-detect from GPS.
                Row(children: [
                  Expanded(
                    child: Text('Shop Location (Lat / Long)',
                        style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ),
                  InkWell(
                    onTap: _detectingLoc ? null : _detectLocation,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.goldBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.goldLight.withOpacity(0.6)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        _detectingLoc
                            ? const SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.gold))
                            : const Icon(Icons.gps_fixed, size: 15, color: AppColors.gold),
                        const SizedBox(width: 6),
                        Text(_detectingLoc ? 'Detecting…' : 'Auto Detect',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gold)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: BrandTextField(controller: _lat, hint: 'Latitude', prefixIcon: Icons.my_location, keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: BrandTextField(controller: _lng, hint: 'Longitude', prefixIcon: Icons.my_location, keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 10),
                BrandTextField(controller: _desc, hint: 'Shop Description / Story', prefixIcon: Icons.notes, maxLines: 4),
                const SizedBox(height: 16),
                GradientButton(
                  label: _savingDetails ? 'Saving…' : 'Save Details',
                  icon: Icons.save,
                  loading: _savingDetails,
                  onTap: _saveDetails,
                ),
                const SizedBox(height: 28),

                // ---- Images ----
                _sectionHeader('Shop Images', onAdd: _addImageFlow),
                _mediaStrip(_images, 'image_url', 'images'),
                const SizedBox(height: 24),

                // ---- Products (hidden for premium services) ----
                if (!_isPremium) ...[
                  _sectionHeader('Products', onAdd: _addProductFlow),
                  _productList(),
                  const SizedBox(height: 24),
                ],

                // ---- Latest Updates ----
                _sectionHeader('Latest Updates', onAdd: _addUpdateFlow),
                _updateList(),
                const SizedBox(height: 24),

                // ---- On-Site Work / Completed Project ----
                _sectionHeader(
                    _isPremium ? 'Completed Project' : 'On-Site Work',
                    onAdd: _addOnsiteFlow),
                _onsiteList(),
                const SizedBox(height: 24),

                // ---- Upcoming Project (premium services only) ----
                if (_isPremium) ...[
                  _sectionHeader('Upcoming Project', onAdd: _addUpcomingFlow),
                  _upcomingList(),
                  const SizedBox(height: 24),
                ],

                // ---- Clients ----
                _sectionHeader('Clients', onAdd: _addClientFlow),
                _clientList(),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  // ---------------- sections UI ----------------

  Widget _title(String t) => Text(t,
      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary));

  Widget _locDropdown({
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safe = (value != null && items.contains(value)) ? value : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.accentGreen),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: safe,
              hint: Text(hint, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
              items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ]),
    );
  }

  // ---- Shop owner image (distinct from app profile) ----
  Widget _ownerImageSection() {
    final url = _s(_detail, 'owner_image');
    final isFallback = _detail['owner_image_is_fallback'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Shop Owner Image'),
        const SizedBox(height: 4),
        Text(
          isFallback
              ? 'Using your profile photo. Upload a dedicated owner photo below.'
              : 'The shop owner’s photo (separate from your app profile).',
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.goldLight, AppColors.goldDim]),
              ),
              child: SafeNetworkImage(
                url: url.isEmpty
                    ? 'https://ui-avatars.com/api/?name=Owner&background=D4A853&color=fff'
                    : url,
                width: 76,
                height: 76,
                borderRadius: BorderRadius.circular(38),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _uploadOwnerImage,
                      icon: const Icon(Icons.upload, size: 18, color: AppColors.gold),
                      label: Text('Upload Owner Photo',
                          style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.gold, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.goldLight)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _useProfileAsOwner,
                      icon: const Icon(Icons.person, size: 18, color: AppColors.textSecondary),
                      label: Text('Use my profile photo',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _uploadOwnerImage() async {
    final f = await _pickImage();
    if (f == null) return;
    await _addChild('owner-image', fileField: 'image', file: f);
  }

  Future<void> _useProfileAsOwner() async {
    final avatar = Get.find<SessionService>().user?.avatar ?? '';
    if (avatar.isEmpty) {
      Get.snackbar('No profile photo', 'Your profile has no image to use',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      await _api.updateShop(shopId, {'owner_image': avatar});
      await _load();
      if (Get.isRegistered<ShopController>()) Get.find<ShopController>().loadMyShops();
      Get.snackbar('Updated', 'Owner image set from your profile',
          snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar('Error', 'Could not update owner image',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Widget _sectionHeader(String t, {required VoidCallback onAdd}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _title(t),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.goldBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.goldLight.withOpacity(0.5)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add, size: 16, color: AppColors.gold),
                const SizedBox(width: 4),
                Text('Add', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gold)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaStrip(List<dynamic> items, String urlKey, String type) {
    if (items.isEmpty) return _emptyHint('No images yet');
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final m = Map<String, dynamic>.from(items[i]);
          return Stack(children: [
            SafeNetworkImage(url: '${m[urlKey]}', width: 96, height: 96, borderRadius: BorderRadius.circular(12)),
            Positioned(top: 4, right: 4, child: _deleteDot(() => _deleteChild(type, '${m['id']}'))),
          ]);
        },
      ),
    );
  }

  Widget _productList() {
    if (_products.isEmpty) return _emptyHint('No products yet');
    return Column(
      children: _products.map((e) {
        final m = Map<String, dynamic>.from(e);
        return _rowCard(
          image: '${m['image_url'] ?? ''}',
          title: '${m['name']}',
          subtitle: '₹${m['price']}  ·  ${m['description'] ?? ''}',
          onDelete: () => _deleteChild('products', '${m['id']}'),
        );
      }).toList(),
    );
  }

  Widget _updateList() {
    if (_updates.isEmpty) return _emptyHint('No updates yet');
    return Column(
      children: _updates.map((e) {
        final m = Map<String, dynamic>.from(e);
        final isVideo = '${m['media_type']}' == 'video';
        return _rowCard(
          image: isVideo ? '' : '${m['media_url'] ?? ''}',
          leadingIcon: isVideo ? Icons.play_circle_fill : null,
          title: '${m['title']}',
          subtitle: '${m['description'] ?? ''}',
          onDelete: () => _deleteChild('latest-updates', '${m['id']}'),
        );
      }).toList(),
    );
  }

  Widget _onsiteList() {
    if (_onsite.isEmpty) return _emptyHint('No on-site work yet');
    return Column(
      children: _onsite.map((e) {
        final m = Map<String, dynamic>.from(e);
        final isVideo = '${m['media_type']}' == 'video';
        return _rowCard(
          image: isVideo ? '' : '${m['media_url'] ?? ''}',
          leadingIcon: isVideo ? Icons.play_circle_fill : null,
          title: '${m['title']}',
          subtitle: '${m['description'] ?? ''}',
          onDelete: () => _deleteChild('onsite-works', '${m['id']}'),
        );
      }).toList(),
    );
  }

  Widget _upcomingList() {
    if (_upcoming.isEmpty) return _emptyHint('No upcoming projects yet');
    return Column(
      children: _upcoming.map((e) {
        final m = Map<String, dynamic>.from(e);
        final isVideo = '${m['media_type']}' == 'video';
        return _rowCard(
          image: isVideo ? '' : '${m['media_url'] ?? ''}',
          leadingIcon: isVideo ? Icons.play_circle_fill : null,
          title: '${m['title']}',
          subtitle: '${m['description'] ?? ''}',
          onDelete: () => _deleteChild('upcoming-projects', '${m['id']}'),
        );
      }).toList(),
    );
  }

  Widget _clientList() {
    if (_clients.isEmpty) return _emptyHint('No clients yet');
    return Column(
      children: _clients.map((e) {
        final m = Map<String, dynamic>.from(e);
        return _rowCard(
          image: '${m['image_url'] ?? ''}',
          title: '${m['name']}',
          subtitle: '${m['details'] ?? ''}',
          onDelete: () => _deleteChild('clients', '${m['id']}'),
        );
      }).toList(),
    );
  }

  Widget _rowCard({required String image, String? title, String? subtitle, IconData? leadingIcon, required VoidCallback onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: leadingIcon != null || image.isEmpty
              ? Container(width: 54, height: 54, color: Colors.black12, child: Icon(leadingIcon ?? Icons.image, color: Colors.black45))
              : SafeNetworkImage(url: image, width: 54, height: 54),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${title ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('${subtitle ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
        IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: onDelete),
      ]),
    );
  }

  Widget _deleteDot(VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
          child: const Icon(Icons.close, size: 14, color: Colors.white),
        ),
      );

  Widget _emptyHint(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(t, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
      );

  // ---------------- add flows ----------------

  Future<void> _addImageFlow() async {
    final f = await _pickImage();
    if (f == null) return;
    await _addChild('images', fileField: 'image', file: f);
  }

  Future<void> _addProductFlow() async {
    final name = TextEditingController();
    final price = TextEditingController();
    final desc = TextEditingController();
    File? file;
    await _formSheet(
      title: 'Add Product',
      builder: (setSheet) => [
        BrandTextField(controller: name, hint: 'Product Name *', prefixIcon: Icons.label),
        const SizedBox(height: 10),
        BrandTextField(controller: price, hint: 'Price', prefixIcon: Icons.currency_rupee, keyboardType: TextInputType.number),
        const SizedBox(height: 10),
        BrandTextField(controller: desc, hint: 'Description', prefixIcon: Icons.notes, maxLines: 2),
        const SizedBox(height: 10),
        _pickTile(file != null, 'Pick product image', () async { file = await _pickImage(); setSheet(() {}); }),
      ],
      onSubmit: () async {
        if (name.text.trim().isEmpty) { Get.snackbar('Required', 'Product name is required', snackPosition: SnackPosition.BOTTOM); return false; }
        await _addChild('products', fileField: 'image', file: file, fields: {
          'name': name.text.trim(), 'price': price.text.trim(), 'description': desc.text.trim(),
        });
        return true;
      },
    );
  }

  Future<void> _addUpdateFlow() async {
    final title = TextEditingController();
    final desc = TextEditingController();
    File? file;
    bool isVideo = false;
    await _formSheet(
      title: 'Add Latest Update',
      builder: (setSheet) => [
        BrandTextField(controller: title, hint: 'Title *', prefixIcon: Icons.title),
        const SizedBox(height: 10),
        BrandTextField(controller: desc, hint: 'Description', prefixIcon: Icons.notes, maxLines: 2),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _pickTile(file != null && !isVideo, 'Image', () async { file = await _pickImage(); isVideo = false; setSheet(() {}); })),
          const SizedBox(width: 10),
          Expanded(child: _pickTile(file != null && isVideo, 'Video', () async { file = await _pickVideo(); isVideo = true; setSheet(() {}); })),
        ]),
      ],
      onSubmit: () async {
        if (title.text.trim().isEmpty) { Get.snackbar('Required', 'Title is required', snackPosition: SnackPosition.BOTTOM); return false; }
        if (file == null) { Get.snackbar('Required', 'Pick an image or video', snackPosition: SnackPosition.BOTTOM); return false; }
        await _addChild('latest-updates', fileField: 'media', file: file, fields: {
          'title': title.text.trim(), 'description': desc.text.trim(),
        });
        return true;
      },
    );
  }

  Future<void> _addOnsiteFlow() async {
    final title = TextEditingController();
    final desc = TextEditingController();
    File? file;
    bool isVideo = false;
    await _formSheet(
      title: 'Add On-Site Work',
      builder: (setSheet) => [
        BrandTextField(controller: title, hint: 'Title *', prefixIcon: Icons.title),
        const SizedBox(height: 10),
        BrandTextField(controller: desc, hint: 'Description', prefixIcon: Icons.notes, maxLines: 2),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _pickTile(file != null && !isVideo, 'Image', () async { file = await _pickImage(); isVideo = false; setSheet(() {}); })),
          const SizedBox(width: 10),
          Expanded(child: _pickTile(file != null && isVideo, 'Video', () async { file = await _pickVideo(); isVideo = true; setSheet(() {}); })),
        ]),
      ],
      onSubmit: () async {
        if (title.text.trim().isEmpty) { Get.snackbar('Required', 'Title is required', snackPosition: SnackPosition.BOTTOM); return false; }
        if (file == null) { Get.snackbar('Required', 'Pick an image or video', snackPosition: SnackPosition.BOTTOM); return false; }
        await _addChild('onsite-works', fileField: 'media', file: file, fields: {
          'title': title.text.trim(), 'description': desc.text.trim(),
        });
        return true;
      },
    );
  }

  Future<void> _addUpcomingFlow() async {
    final title = TextEditingController();
    final desc = TextEditingController();
    File? file;
    bool isVideo = false;
    await _formSheet(
      title: 'Add Upcoming Project',
      builder: (setSheet) => [
        BrandTextField(controller: title, hint: 'Title *', prefixIcon: Icons.title),
        const SizedBox(height: 10),
        BrandTextField(controller: desc, hint: 'Description', prefixIcon: Icons.notes, maxLines: 2),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _pickTile(file != null && !isVideo, 'Image', () async { file = await _pickImage(); isVideo = false; setSheet(() {}); })),
          const SizedBox(width: 10),
          Expanded(child: _pickTile(file != null && isVideo, 'Video', () async { file = await _pickVideo(); isVideo = true; setSheet(() {}); })),
        ]),
      ],
      onSubmit: () async {
        if (title.text.trim().isEmpty) { Get.snackbar('Required', 'Title is required', snackPosition: SnackPosition.BOTTOM); return false; }
        if (file == null) { Get.snackbar('Required', 'Pick an image or video', snackPosition: SnackPosition.BOTTOM); return false; }
        await _addChild('upcoming-projects', fileField: 'media', file: file, fields: {
          'title': title.text.trim(), 'description': desc.text.trim(),
        });
        return true;
      },
    );
  }

  Future<void> _addClientFlow() async {
    final name = TextEditingController();
    final details = TextEditingController();
    File? file;
    await _formSheet(
      title: 'Add Client',
      builder: (setSheet) => [
        BrandTextField(controller: name, hint: 'Client Name *', prefixIcon: Icons.person),
        const SizedBox(height: 10),
        BrandTextField(controller: details, hint: 'Details', prefixIcon: Icons.notes, maxLines: 2),
        const SizedBox(height: 10),
        _pickTile(file != null, 'Pick client image', () async { file = await _pickImage(); setSheet(() {}); }),
      ],
      onSubmit: () async {
        if (name.text.trim().isEmpty) { Get.snackbar('Required', 'Client name is required', snackPosition: SnackPosition.BOTTOM); return false; }
        await _addChild('clients', fileField: 'image', file: file, fields: {
          'name': name.text.trim(), 'details': details.text.trim(),
        });
        return true;
      },
    );
  }

  Widget _pickTile(bool picked, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: picked ? AppColors.goldBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: picked ? AppColors.goldLight : Colors.grey.shade300),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(picked ? Icons.check_circle : Icons.upload_file, size: 18, color: picked ? AppColors.gold : Colors.black54),
          const SizedBox(width: 8),
          Text(picked ? 'Selected' : label, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  /// Generic add sheet. onSubmit returns true to close.
  Future<void> _formSheet({
    required String title,
    required List<Widget> Function(void Function(void Function()) setSheet) builder,
    required Future<bool> Function() onSubmit,
  }) async {
    bool busy = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 18, right: 18, top: 18,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title(title),
              const SizedBox(height: 14),
              ...builder(setSheet),
              const SizedBox(height: 18),
              GradientButton(
                label: busy ? 'Saving…' : 'Save',
                icon: Icons.check,
                loading: busy,
                onTap: () async {
                  if (busy) return;
                  setSheet(() => busy = true);
                  final ok = await onSubmit();
                  setSheet(() => busy = false);
                  if (ok && ctx.mounted) Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
