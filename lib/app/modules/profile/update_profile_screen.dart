import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/location_controller.dart';
import '../../data/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_pick_edit.dart';
import '../../widgets/common_widgets.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  late final auth = Get.find<AuthController>();
  final _api = Get.find<ApiService>();
  final _location = Get.find<LocationController>();

  late final TextEditingController nameCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController mobileCtrl;

  String? _state;
  String? _city;
  String? _userType;

  static const _userTypes = [
    'Interior Designer', 'Architect', 'Builder', 'End Customer', 'Shop Owner',
  ];

  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final u = auth.user.value!;
    nameCtrl = TextEditingController(text: u.name);
    emailCtrl = TextEditingController(text: u.email);
    mobileCtrl = TextEditingController(text: u.mobile);
    // Defensive: on a hot-reloaded (stale) user object the new `state`
    // field can be null — guard so it never crashes.
    String stateVal = '';
    String cityVal = '';
    String typeVal = '';
    try { stateVal = u.state; } catch (_) {}
    try { cityVal = u.city; } catch (_) {}
    try { typeVal = u.userType; } catch (_) {}
    _state = stateVal.isEmpty ? null : stateVal;
    _city = cityVal.isEmpty ? null : cityVal;
    _userType = (typeVal.isEmpty || !_userTypes.contains(typeVal)) ? null : typeVal;
    _location.loadStates();
    if (_state != null) _location.loadDistricts(_state!);
  }

  Future<void> _pickAndUploadImage() async {
    // Camera/Gallery chooser + image editor (shared helper).
    final edited = await pickAndEditImage(context);
    if (edited == null) return;
    setState(() => _uploading = true);
    try {
      final map = await _api.updateProfileImage(auth.user.value!.id, edited);
      await auth.setUser(UserModel.fromJson(map));
      Get.snackbar('Updated', 'Profile image updated',
          snackPosition: SnackPosition.BOTTOM);
    } on ApiException catch (e) {
      Get.snackbar('Failed', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar('Error', 'Could not upload image',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final map = await _api.updateUser(auth.user.value!.id, {
        'full_name': nameCtrl.text.trim(),
        'mobile_number': mobileCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'state': _state ?? '',
        'city': _city ?? '',
        'user_type': _userType ?? '',
      });
      await auth.setUser(UserModel.fromJson(map));
      Get.back();
      Get.snackbar('Saved', 'Profile updated', snackPosition: SnackPosition.BOTTOM);
    } on ApiException catch (e) {
      Get.snackbar('Failed', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar('Error', 'Could not save profile',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: const BrandAppBar(title: 'User Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Obx(() {
          final u = auth.user.value!;
          return Column(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _uploading ? null : _pickAndUploadImage,
                  child: Stack(
                    children: [
                      SafeNetworkImage(
                          url: u.avatar,
                          width: 100,
                          height: 100,
                          borderRadius: BorderRadius.circular(50)),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          decoration: const BoxDecoration(
                              color: AppColors.accentGreen,
                              shape: BoxShape.circle),
                          padding: const EdgeInsets.all(7),
                          child: _uploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              BrandTextField(
                  controller: nameCtrl,
                  hint: 'Full Name',
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
                  prefixIcon: Icons.email),
              const SizedBox(height: 12),
              Obx(() => _dropdown(
                    hint: 'State',
                    icon: Icons.map,
                    value: _state,
                    items: _location.stateNames,
                    onChanged: (v) {
                      setState(() { _state = v; _city = null; });
                      if (v != null) _location.loadDistricts(v);
                    },
                  )),
              const SizedBox(height: 12),
              Obx(() => _dropdown(
                    hint: 'City',
                    icon: Icons.location_city,
                    value: _city,
                    items: _location.districtNames,
                    onChanged: (v) => setState(() => _city = v),
                  )),
              const SizedBox(height: 12),
              _dropdown(
                hint: 'Type of User',
                icon: Icons.badge_outlined,
                value: _userType,
                items: _userTypes,
                onChanged: (v) => setState(() => _userType = v),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: _saving ? 'Saving...' : 'Save Changes',
                icon: Icons.save,
                onTap: _save,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _dropdown({
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // Guard: only pass a value that exists in items (avoids assertion).
    final safeValue = (value != null && items.contains(value)) ? value : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accentGreen),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: safeValue,
                hint: Text(hint, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
