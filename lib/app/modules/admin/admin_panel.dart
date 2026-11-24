import 'dart:io';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/location_controller.dart';
import '../../controllers/services_controller.dart';
import '../../data/models.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/image_viewer.dart';
import '../post/full_screen_post_viewer.dart';

ApiService get _api => Get.find<ApiService>();

/// Fetches full shop detail and opens the shared Owner Detail screen.
Future<void> _openShopDetail(String id) async {
  try {
    final d = await _api.getShopDetail(id);
    Get.toNamed(AppRoutes.ownerDetail, arguments: ShopModel.fromJson(d));
  } catch (e) {
    Get.snackbar('Error', 'Could not open shop', snackPosition: SnackPosition.BOTTOM);
  }
}

/// 'YYYY-MM-DD HH:MM:SS' -> 'dd/MM/yyyy, hh:mm am/pm'
String _fmtDateTime(String? raw) {
  final d = DateTime.tryParse(raw ?? '');
  if (d == null) return '';
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ampm = d.hour >= 12 ? 'PM' : 'AM';
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}, $h12:$mm $ampm';
}

// ═════════════════════════════════════════════════════════════════════════
// DASHBOARD
// ═════════════════════════════════════════════════════════════════════════
class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <List<dynamic>>[
      [Icons.people_alt_outlined, 'Users', AppRoutes.adminUsersList],
      [Icons.store_outlined, 'Shops', AppRoutes.adminShopsList],
      [Icons.design_services_outlined, 'Services', AppRoutes.adminServicesList],
      [Icons.dynamic_feed_outlined, 'Posts', AppRoutes.adminPostsList],
      [Icons.view_carousel_outlined, 'Banners', AppRoutes.adminBannersList],
      [Icons.mail_outline, 'Contact Us', AppRoutes.adminContactsList],
      [Icons.location_on_outlined, 'Locations', AppRoutes.adminLocationsList],
      [Icons.image_outlined, 'Service Banners', AppRoutes.adminServiceBannersList],
      [Icons.system_update_outlined, 'App Update', AppRoutes.adminAppVersionsList],
      [Icons.currency_rupee, 'Pricing', AppRoutes.adminPricingList],
      [Icons.upload_file_outlined, 'Import Shops', AppRoutes.adminImport],
    ];
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: const BrandAppBar(title: 'Admin Panel'),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.1,
        children: items.map((it) {
          return InkWell(
            onTap: () => Get.toNamed(it[2] as String),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(color: AppColors.goldBg, shape: BoxShape.circle),
                    child: Icon(it[0] as IconData, color: AppColors.gold, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(it[1] as String,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// small shared helpers
Widget _adminScaffold(String title, Widget body, {List<Widget>? actions}) => Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: BrandAppBar(title: title, actions: actions),
      body: body,
    );

Widget _loader() => const Center(child: CircularProgressIndicator(color: AppColors.gold));

/// Normalises a DB date value ('2026-03-25' / '2026-03-25T00:00:00' / null) to
/// a plain 'YYYY-MM-DD' string ('' when empty).
String adminDateStr(dynamic v) {
  if (v == null) return '';
  final s = '$v';
  if (s.isEmpty || s == 'null') return '';
  return s.split('T').first;
}

/// A tappable date field for the admin sheets.
Widget adminDatePicker(BuildContext context, String label, String value, ValueChanged<String> onPicked) {
  return InkWell(
    onTap: () async {
      final now = DateTime.now();
      final init = DateTime.tryParse(value) ?? now;
      final d = await showDatePicker(
        context: context,
        initialDate: init,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 5),
      );
      if (d != null) {
        final m = d.month.toString().padLeft(2, '0');
        final day = d.day.toString().padLeft(2, '0');
        onPicked('${d.year}-$m-$day');
      }
    },
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Row(children: [
        const Icon(Icons.event, size: 16, color: AppColors.gold),
        const SizedBox(width: 8),
        Expanded(child: Text(value.isEmpty ? label : value,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 12.5, color: value.isEmpty ? AppColors.textSecondary : AppColors.textPrimary))),
        if (value.isNotEmpty)
          GestureDetector(onTap: () => onPicked(''), child: const Icon(Icons.close, size: 15, color: AppColors.textMuted)),
      ]),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════
// USERS (list + filter)
// ═════════════════════════════════════════════════════════════════════════
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _q = TextEditingController();
  final _location = Get.find<LocationController>();
  String _status = '';        // '' | active | inactive
  String? _state;
  String? _city;
  String? _userType;
  bool _activeNow = false;     // filter: only users currently active (have an FCM token)
  List<dynamic> _all = [];     // loaded for current q/state/city/type (all statuses)
  bool _loading = true;

  static const _userTypes = [
    'Interior Designer', 'Architect', 'Builder', 'End Customer', 'Shop Owner',
  ];

  @override
  void initState() { super.initState(); _location.loadStates(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _all = await _api.getUsers(q: _q.text.trim(), state: _state, city: _city, userType: _userType);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  bool _isActive(Map u) => (u['status'] ?? 'active') == 'active';
  bool _hasFcm(Map u) =>
      u['has_fcm'] == 1 || u['has_fcm'] == true || u['has_fcm'] == '1';

  List<dynamic> get _shown {
    var list = _all;
    if (_status.isNotEmpty) {
      list = list.where((e) => (Map.from(e)['status'] ?? '') == _status).toList();
    }
    if (_activeNow) {
      list = list.where((e) => _hasFcm(Map.from(e))).toList();
    }
    return list;
  }

  int get _activeCount => _all.where((e) => _isActive(Map.from(e))).length;
  int get _inactiveCount => _all.length - _activeCount;
  int get _activeNowCount => _all.where((e) => _hasFcm(Map.from(e))).length;

  Future<void> _export() async {
    try {
      Get.snackbar('Exporting', 'Preparing Excel file…', snackPosition: SnackPosition.BOTTOM);
      final csv = await _api.exportUsersCsv(
        q: _q.text.trim(), status: _status, state: _state, city: _city,
        userType: _userType, hasFcm: _activeNow,
      );
      // Reflect the Currently-Active filter in the file name.
      final name = _activeNow ? 'currently_active_users.csv' : 'users_export.csv';
      final file = File('${Directory.systemTemp.path}/$name');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)],
          text: _activeNow ? 'Currently Active users' : 'Users export');
    } catch (e) {
      Get.snackbar('Export failed', '$e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    return _adminScaffold('Users', Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: BrandTextField(controller: _q, hint: 'Search name / email / mobile', prefixIcon: Icons.search)),
            const SizedBox(width: 8),
            IconButton(onPressed: _load, icon: const Icon(Icons.search, color: AppColors.gold)),
          ]),
        ),
        // Counts
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            _countCard('Total', _all.length, AppColors.gold),
            const SizedBox(width: 8),
            _countCard('Active', _activeCount, Colors.green),
            const SizedBox(width: 8),
            _countCard('Inactive', _inactiveCount, AppColors.error),
          ]),
        ),
        const SizedBox(height: 10),
        // Status chips (no "blocked") + Currently Active (has FCM token)
        Wrap(spacing: 8, runSpacing: 4, children: [
          ...['', 'active', 'inactive'].map((s) {
            final sel = _status == s;
            return ChoiceChip(
              label: Text(s.isEmpty ? 'All' : s),
              selected: sel,
              onSelected: (_) => setState(() => _status = s),
            );
          }),
          ChoiceChip(
            avatar: Icon(Icons.circle,
                size: 10,
                color: _activeNow ? Colors.white : Colors.green),
            label: Text('Currently Active ($_activeNowCount)'),
            selected: _activeNow,
            selectedColor: Colors.green,
            labelStyle: TextStyle(
                color: _activeNow ? Colors.white : null,
                fontWeight: FontWeight.w600),
            onSelected: (_) => setState(() => _activeNow = !_activeNow),
          ),
        ]),
        const SizedBox(height: 8),
        // State + City filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Expanded(child: Obx(() => _dropdown('State', _state, ['All', ..._location.stateNames], (v) {
              setState(() { _state = (v == 'All') ? null : v; _city = null; });
              if (_state != null) _location.loadDistricts(_state!); else _location.districts.clear();
              _load();
            }))),
            const SizedBox(width: 8),
            Expanded(child: Obx(() => _dropdown('City', _city, ['All', ..._location.districtNames], (v) {
              setState(() => _city = (v == 'All') ? null : v);
              _load();
            }))),
          ]),
        ),
        const SizedBox(height: 8),
        // Type of User filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _dropdown('Type of User', _userType, ['All', ..._userTypes], (v) {
            setState(() => _userType = (v == 'All') ? null : v);
            _load();
          }),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _loading ? _loader() : ListView.builder(
            itemCount: shown.length,
            itemBuilder: (_, i) {
              final u = Map<String, dynamic>.from(shown[i]);
              return ListTile(
                onTap: () async {
                  await Get.to(() => AdminUserDetailScreen(user: u));
                  _load(); // refresh (e.g. after a delete)
                },
                leading: SafeNetworkImage(
                  url: '${u['profile_image'] ?? ''}'.isEmpty
                      ? 'https://ui-avatars.com/api/?name=U&background=D4A853&color=fff'
                      : '${u['profile_image']}',
                  width: 42, height: 42, borderRadius: BorderRadius.circular(21),
                ),
                title: Text('${u['full_name'] ?? ''}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text([
                  '${u['mobile_number'] ?? ''}',
                  if ('${u['city'] ?? ''}'.isNotEmpty) '${u['city']}',
                  if ('${u['user_type'] ?? ''}'.isNotEmpty) '${u['user_type']}',
                ].join(' · ')),
                trailing: (u['is_admin'] == 1 || u['is_admin'] == true)
                    ? const Chip(label: Text('Admin'), backgroundColor: AppColors.goldBg)
                    : const Icon(Icons.chevron_right, color: AppColors.textMuted),
              );
            },
          ),
        ),
      ],
    ), actions: [BrandAppBarAction(icon: Icons.file_download_outlined, onTap: _export)]);
  }

  Widget _countCard(String label, int n, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text('$n', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
      );

  Widget _dropdown(String hint, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textSecondary)),
          items: items.map((s) => DropdownMenuItem(value: s == 'All' ? null : s,
              child: Text(s, style: GoogleFonts.poppins(fontSize: 12.5)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// USER DETAIL (info + their shops)
// ═════════════════════════════════════════════════════════════════════════
class AdminUserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const AdminUserDetailScreen({super.key, required this.user});
  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  List<dynamic> _shops = [];
  bool _loading = true;
  late bool _isAdmin;
  bool _savingAdmin = false;

  @override
  void initState() {
    super.initState();
    _isAdmin = widget.user['is_admin'] == 1 || widget.user['is_admin'] == true;
    _load();
  }

  Future<void> _toggleAdmin(bool v) async {
    if (_savingAdmin) return;
    setState(() { _isAdmin = v; _savingAdmin = true; });
    try {
      await _api.updateUser('${widget.user['id']}', {'is_admin': v ? 1 : 0});
      widget.user['is_admin'] = v ? 1 : 0; // keep the list in sync
      Get.snackbar('Updated',
          v ? 'Admin access granted' : 'Admin access removed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: v ? Colors.green : null,
          colorText: v ? Colors.white : null);
    } catch (e) {
      setState(() => _isAdmin = !v); // revert
      Get.snackbar('Failed', '$e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _savingAdmin = false);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid = int.tryParse('${widget.user['id']}');
      if (uid != null) _shops = await _api.getShops(userId: uid);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return _adminScaffold('User Details', ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: GestureDetector(
            onTap: () => showImageViewer('${u['profile_image'] ?? ''}'),
            child: SafeNetworkImage(
              url: '${u['profile_image'] ?? ''}'.isEmpty
                  ? 'https://ui-avatars.com/api/?name=U&background=D4A853&color=fff'
                  : '${u['profile_image']}',
              width: 90, height: 90, borderRadius: BorderRadius.circular(45),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text('${u['full_name'] ?? ''}',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700))),
        const SizedBox(height: 16),
        _info('Mobile', '${u['mobile_number'] ?? '-'}',
            actionIcon: Icons.call,
            onAction: () => _launch('tel:${u['mobile_number'] ?? ''}')),
        _info('Email', '${u['email'] ?? '-'}',
            actionIcon: Icons.mail_outline,
            onAction: () => _launch('mailto:${u['email'] ?? ''}')),
        _info('City', '${u['city'] ?? '-'}'),
        _info('State', '${u['state'] ?? '-'}'),
        _info('Type', '${u['user_type']?.toString().isNotEmpty == true ? u['user_type'] : '-'}'),
        _info('Status', '${u['status'] ?? '-'}'),
        // Admin access — grant/revoke.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            SizedBox(width: 80,
                child: Text('Admin', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary))),
            Expanded(
              child: Text(_isAdmin ? 'Has admin access' : 'Regular user',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            Switch(
              value: _isAdmin,
              activeColor: AppColors.gold,
              onChanged: _savingAdmin ? null : _toggleAdmin,
            ),
          ]),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Text('Shops', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: AppColors.goldBg, borderRadius: BorderRadius.circular(20)),
            child: Text('${_shops.length}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.gold)),
          ),
        ]),
        const SizedBox(height: 10),
        if (_loading)
          _loader()
        else if (_shops.isEmpty)
          Text('No shops listed', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary))
        else
          ..._shops.map((e) {
            final s = Map<String, dynamic>.from(e);
            return Card(
              color: Colors.white,
              child: ListTile(
                onTap: () => _openShopDetail('${s['id']}'),
                title: Text('${s['shop_name'] ?? ''}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('${s['service_name'] ?? ''} · ${s['city'] ?? ''}'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ),
            );
          }),
        const SizedBox(height: 26),
        OutlinedButton.icon(
          onPressed: _confirmDelete,
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          label: Text('Delete User',
              style: GoogleFonts.poppins(
                  color: AppColors.error, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.error),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 20),
      ],
    ));
  }

  void _confirmDelete() {
    final u = widget.user;
    Get.dialog(AlertDialog(
      title: const Text('Delete User'),
      content: Text(
          'Delete "${u['full_name'] ?? 'this user'}" and ALL their shops? This cannot be undone.'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Get.back(); // close dialog
            try {
              await _api.deleteUser('${u['id']}');
              Get.back(result: true); // close detail → list refreshes
              Get.snackbar('Deleted', 'User and their shops removed',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green, colorText: Colors.white);
            } catch (e) {
              Get.snackbar('Failed', '$e', snackPosition: SnackPosition.BOTTOM);
            }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
  }

  Widget _info(String k, String v, {IconData? actionIcon, VoidCallback? onAction}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          SizedBox(width: 80, child: Text(k, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary))),
          Expanded(child: Text(v, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500))),
          if (actionIcon != null && v.trim().isNotEmpty && v.trim() != '-')
            GestureDetector(
              onTap: onAction,
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: AppColors.goldBg, shape: BoxShape.circle),
                child: Icon(actionIcon, size: 17, color: AppColors.gold),
              ),
            ),
        ]),
      );

  Future<void> _launch(String uri) async {
    final u = Uri.parse(uri);
    // Try launching directly (don't gate on canLaunchUrl — it can wrongly
    // return false due to package visibility). Fall back to clipboard.
    bool ok = false;
    try {
      ok = await launchUrl(u, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      final value = uri.replaceFirst(RegExp(r'^(mailto:|tel:)'), '');
      await Clipboard.setData(ClipboardData(text: value));
      Get.snackbar('No app found', 'Copied "$value" to clipboard',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════
// SHOPS (list + filter + add + delete)
// ═════════════════════════════════════════════════════════════════════════
class AdminShopsScreen extends StatefulWidget {
  const AdminShopsScreen({super.key});
  @override
  State<AdminShopsScreen> createState() => _AdminShopsScreenState();
}

class _AdminShopsScreenState extends State<AdminShopsScreen> {
  final _q = TextEditingController();
  final _location = Get.find<LocationController>();
  List<dynamic> _shops = [];
  List<Map<String, dynamic>> _services = []; // {id, name, shops_count}
  int? _serviceId;
  String? _state;
  String? _city;
  int? _activeFilter; // null = all, 1 = active, 0 = inactive
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadServices(); _location.loadStates(); _load(); }

  Future<void> _loadServices() async {
    try {
      final data = await _api.getServices();
      final s = Map<String, dynamic>.from(data['services'] ?? {});
      final all = [...(s['premium'] ?? []), ...(s['free'] ?? [])];
      _services = all.map((e) => Map<String, dynamic>.from(e)).toList();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Load ALL (active + inactive) so admin can see and toggle both.
      _shops = await _api.getShops(
          q: _q.text.trim(), serviceId: _serviceId, state: _state, city: _city, includeInactive: true);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  bool _isActive(Map s) => s['is_active'] == 1 || s['is_active'] == true;
  List<dynamic> get _shownShops => _activeFilter == null
      ? _shops
      : _shops.where((e) => _isActive(Map.from(e)) == (_activeFilter == 1)).toList();
  int get _activeCount => _shops.where((e) => _isActive(Map.from(e))).length;
  int get _inactiveCount => _shops.length - _activeCount;

  Future<void> _toggleActive(Map<String, dynamic> s) async {
    final newVal = _isActive(s) ? 0 : 1;
    try {
      await _api.updateShop('${s['id']}', {'is_active': newVal});
      await _load();
    } catch (e) {
      Get.snackbar('Failed', '$e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Widget _filterBox({required IconData icon, required Widget child}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(icon, size: 18, color: AppColors.gold),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonHideUnderline(child: child)),
          ]),
        ),
      );

  Widget _statusChip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      );

  /// Opens the full Edit Shop screen for any shop (admin can edit shops even
  /// when the owner user hasn't made changes), then refreshes the list.
  Future<void> _editShop(String id) async {
    await Get.toNamed(AppRoutes.updateShop, arguments: id);
    _load();
  }

  Future<void> _delete(String id) async {
    Get.dialog(AlertDialog(
      title: const Text('Delete Shop'),
      content: const Text('Delete this shop and all its data?'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(onPressed: () async {
          Get.back();
          try { await _api.deleteShop(id); await _load(); }
          catch (e) { Get.snackbar('Failed', '$e', snackPosition: SnackPosition.BOTTOM); }
        }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _adminScaffold('Shops', Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: BrandTextField(controller: _q, hint: 'Search shops', prefixIcon: Icons.search)),
            IconButton(onPressed: _load, icon: const Icon(Icons.search, color: AppColors.gold)),
          ]),
        ),
        // Filter by service (with shop counts)
        _filterBox(
          icon: Icons.design_services_outlined,
          child: DropdownButton<int?>(
            isExpanded: true,
            value: _serviceId,
            hint: Text('All services', style: GoogleFonts.poppins(fontSize: 13)),
            items: [
              DropdownMenuItem<int?>(value: null, child: Text('All services', style: GoogleFonts.poppins(fontSize: 13))),
              ..._services.map((s) => DropdownMenuItem<int?>(
                    value: int.tryParse('${s['id']}'),
                    child: Text('${s['name']}  (${s['shops_count'] ?? 0})', style: GoogleFonts.poppins(fontSize: 13)),
                  )),
            ],
            onChanged: (v) { setState(() => _serviceId = v); _load(); },
          ),
        ),
        const SizedBox(height: 8),
        // Filter by state + city
        Obx(() => _filterBox(
              icon: Icons.map,
              child: DropdownButton<String?>(
                isExpanded: true,
                value: _state,
                hint: Text('All states', style: GoogleFonts.poppins(fontSize: 13)),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text('All states', style: GoogleFonts.poppins(fontSize: 13))),
                  ..._location.stateNames.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s, style: GoogleFonts.poppins(fontSize: 13)))),
                ],
                onChanged: (v) {
                  setState(() { _state = v; _city = null; });
                  if (v != null) _location.loadDistricts(v); else _location.districts.clear();
                  _load();
                },
              ),
            )),
        const SizedBox(height: 8),
        Obx(() => _filterBox(
              icon: Icons.location_city,
              child: DropdownButton<String?>(
                isExpanded: true,
                value: _city,
                hint: Text('All cities', style: GoogleFonts.poppins(fontSize: 13)),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text('All cities', style: GoogleFonts.poppins(fontSize: 13))),
                  ..._location.districtNames.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c, style: GoogleFonts.poppins(fontSize: 13)))),
                ],
                onChanged: (v) { setState(() => _city = v); _load(); },
              ),
            )),
        const SizedBox(height: 8),
        // Active / Inactive filter with counts
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(spacing: 8, children: [
            _statusChip('All (${_shops.length})', _activeFilter == null, () => setState(() => _activeFilter = null)),
            _statusChip('Active ($_activeCount)', _activeFilter == 1, () => setState(() => _activeFilter = 1)),
            _statusChip('Inactive ($_inactiveCount)', _activeFilter == 0, () => setState(() => _activeFilter = 0)),
          ]),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _loading ? _loader() : ListView.builder(
            itemCount: _shownShops.length,
            itemBuilder: (_, i) {
              final s = Map<String, dynamic>.from(_shownShops[i]);
              final thumb = '${s['thumbnail'] ?? ''}';
              final active = _isActive(s);
              return ListTile(
                onTap: () => _openShopDetail('${s['id']}'),
                leading: SafeNetworkImage(
                    url: thumb,
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(8),
                    fallbackAsset: kLifestyleLogoAsset),
                title: Text('${s['shop_name'] ?? ''}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('${s['service_name'] ?? ''} · ${s['city'] ?? ''} · ${s['owner_name'] ?? ''}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  // Active/inactive toggle
                  Switch(
                    value: active,
                    activeColor: Colors.green,
                    onChanged: (_) => _toggleActive(s),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                    onSelected: (v) {
                      if (v == 'edit') _editShop('${s['id']}');
                      if (v == 'delete') _delete('${s['id']}');
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit, size: 18, color: AppColors.gold),
                          SizedBox(width: 10), Text('Edit Shop'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          SizedBox(width: 10), Text('Delete'),
                        ]),
                      ),
                    ],
                  ),
                ]),
              );
            },
          ),
        ),
      ],
    ), actions: [
      BrandAppBarAction(icon: Icons.add_business, onTap: () async {
        await Get.to(() => const AdminAddShopScreen());
        _load();
      }),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════
// ADMIN ADD SHOP (assign to a user, no payment)
// ═════════════════════════════════════════════════════════════════════════
class AdminAddShopScreen extends StatefulWidget {
  const AdminAddShopScreen({super.key});
  @override
  State<AdminAddShopScreen> createState() => _AdminAddShopScreenState();
}

class _AdminAddShopScreenState extends State<AdminAddShopScreen> {
  final _location = Get.find<LocationController>();
  final _servicesCtrl = Get.find<ServicesController>();

  final _shopName = TextEditingController();
  final _owner = TextEditingController();
  final _mobile = TextEditingController();
  final _other = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _desc = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  int? _userId;
  String? _state;
  String? _city;
  final Set<String> _serviceNames = {}; // selected service names
  bool _loadingUsers = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _location.loadStates();
    if (_servicesCtrl.categories.isEmpty) _servicesCtrl.load();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final list = await _api.getUsers();
      _users = list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loadingUsers = false);
  }

  List<int> get _serviceIds {
    final ids = <int>[];
    for (final name in _serviceNames) {
      for (final s in _servicesCtrl.categories) {
        if (s.name == name) {
          final id = int.tryParse(s.id);
          if (id != null) ids.add(id);
          break;
        }
      }
    }
    return ids;
  }

  Future<void> _save() async {
    if (_userId == null) { Get.snackbar('Required', 'Select a user', snackPosition: SnackPosition.BOTTOM); return; }
    if (_shopName.text.trim().isEmpty || _owner.text.trim().isEmpty || _mobile.text.trim().isEmpty) {
      Get.snackbar('Required', 'Shop name, owner and mobile are required', snackPosition: SnackPosition.BOTTOM); return;
    }
    if (_state == null || _city == null) { Get.snackbar('Required', 'Select State and City', snackPosition: SnackPosition.BOTTOM); return; }
    if (_serviceIds.isEmpty) { Get.snackbar('Required', 'Select at least one service', snackPosition: SnackPosition.BOTTOM); return; }

    setState(() => _busy = true);
    try {
      await _api.createShop({
        'user_id': _userId,
        'service_ids': _serviceIds,
        'shop_name': _shopName.text.trim(),
        'owner_name': _owner.text.trim(),
        'owner_mobile': _mobile.text.trim(),
        'alternative_number': _other.text.trim(),
        'email': _email.text.trim(),
        'address': _address.text.trim(),
        'state': _state,
        'city': _city,
        'district': _city,
        'story_description': _desc.text.trim(),
      });
      Get.back();
      Get.snackbar('Created', 'Shop assigned successfully',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Failed', '$e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _adminScaffold('Add Shop (Admin)', ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Assign to User', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        DropdownSearch<Map<String, dynamic>>(
          enabled: !_loadingUsers,
          items: (filter, infiniteScrollProps) => _users,

          itemAsString: (u) =>
          '${u['full_name'] ?? ''} · ${u['mobile_number'] ?? ''}',

          selectedItem: _userId == null
              ? null
              : _users.cast<Map<String, dynamic>?>().firstWhere(
                (u) => int.tryParse('${u?['id']}') == _userId,
            orElse: () => null,
          ),

          compareFn: (a, b) =>
          '${a['id']}' == '${b['id']}',

          onChanged: (u) {
            setState(() {
              _userId = u == null
                  ? null
                  : int.tryParse('${u['id']}');
            });
          },

          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              hintText: _loadingUsers
                  ? 'Loading users…'
                  : 'Select user *',
              prefixIcon: const Icon(
                Icons.person,
                color: AppColors.gold,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),

          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search user...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            itemBuilder: (context, user, isDisabled, isSelected) {
              final imageUrl = '${user['profile_image'] ?? ''}'.trim();

              return ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.goldBg,
                  backgroundImage:
                  imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty
                      ? Image.asset("assets/images/lifestylelogo.png")
                      : null,
                ),

                title: Text(
                  '${user['full_name'] ?? ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Type : ${user['user_type'] ?? ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Mobile Number : ${user['mobile_number'] ?? ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Text('Shop Details', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        BrandTextField(controller: _shopName, hint: 'Shop / Firm Name *', prefixIcon: Icons.store),
        const SizedBox(height: 10),
        BrandTextField(controller: _owner, hint: 'Owner Name *', prefixIcon: Icons.person_outline),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: BrandTextField(controller: _mobile, hint: 'Mobile *', prefixIcon: Icons.phone, keyboardType: TextInputType.phone)),
          const SizedBox(width: 10),
          Expanded(child: BrandTextField(controller: _other, hint: 'Other No.', prefixIcon: Icons.phone_iphone, keyboardType: TextInputType.phone)),
        ]),
        const SizedBox(height: 10),
        BrandTextField(controller: _email, hint: 'Email', prefixIcon: Icons.email),
        const SizedBox(height: 10),
        BrandTextField(controller: _address, hint: 'Address', prefixIcon: Icons.home, maxLines: 2),
        const SizedBox(height: 10),
        Obx(() => _boxDropdown<String>(
              hint: 'State *', icon: Icons.map, value: _state,
              items: _location.stateNames.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
              onChanged: (v) { setState(() { _state = v; _city = null; }); if (v != null) _location.loadDistricts(v); },
            )),
        const SizedBox(height: 10),
        Obx(() => _boxDropdown<String>(
              hint: 'City *', icon: Icons.location_city, value: _city,
              items: _location.districtNames.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _city = v),
            )),
        const SizedBox(height: 10),
        BrandTextField(controller: _desc, hint: 'Description', prefixIcon: Icons.notes, maxLines: 3),
        const SizedBox(height: 18),
        Text('Type of Service', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Obx(() => Wrap(
              spacing: 8, runSpacing: 8,
              children: _servicesCtrl.categories.map((cat) {
                final sel = _serviceNames.contains(cat.name);
                return FilterChip(
                  label: Text(cat.name),
                  selected: sel,
                  onSelected: (_) => setState(() => sel ? _serviceNames.remove(cat.name) : _serviceNames.add(cat.name)),
                );
              }).toList(),
            )),
        const SizedBox(height: 22),
        GradientButton(
          label: _busy ? 'Saving…' : 'Create Shop',
          icon: Icons.check,
          loading: _busy,
          onTap: _save,
        ),
        const SizedBox(height: 30),
      ],
    ));
  }

  Widget _boxDropdown<T>({
    required String hint,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.gold),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              hint: Text(hint, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// SERVICES (list + create + update)
// ═════════════════════════════════════════════════════════════════════════
class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});
  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  List<dynamic> _all = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getServices(includeInactive: true);
      final s = Map<String, dynamic>.from(data['services'] ?? {});
      _all = [...(s['premium'] ?? []), ...(s['free'] ?? [])];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  bool _isActive(Map s) => s['is_active'] == 1 || s['is_active'] == true;

  Future<void> _edit({Map<String, dynamic>? existing}) async {
    final name = TextEditingController(text: existing?['name']?.toString() ?? '');
    final desc = TextEditingController(text: existing?['description']?.toString() ?? '');
    final icon = TextEditingController(text: existing?['icon']?.toString() ?? '');
    final order = TextEditingController(text: '${existing?['sort_order'] ?? 0}');
    // category: premium=1, free=2 (per seed)
    int categoryId = (existing?['category_slug'] == 'premium') ? 1 : 2;
    File? iconFile;
    bool busy = false;

    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(ctx).viewInsets.bottom + 18),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(existing == null ? 'Create Service' : 'Update Service',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          BrandTextField(controller: name, hint: 'Service Name *', prefixIcon: Icons.label),
          const SizedBox(height: 10),
          // Select icon image (upload) OR paste URL
          InkWell(
            onTap: () async {
              final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
              if (x != null) { iconFile = File(x.path); setSheet(() {}); }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconFile != null ? AppColors.goldBg : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconFile != null ? AppColors.goldLight : Colors.grey.shade300),
              ),
              child: Row(children: [
                Icon(iconFile != null ? Icons.check_circle : Icons.image_outlined,
                    size: 18, color: iconFile != null ? AppColors.gold : Colors.black54),
                const SizedBox(width: 8),
                Text(iconFile != null ? 'Image selected' : 'Select icon image',
                    style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          BrandTextField(controller: icon, hint: 'or paste Icon URL (optional)', prefixIcon: Icons.link),
          const SizedBox(height: 10),
          BrandTextField(controller: desc, hint: 'Description', prefixIcon: Icons.notes, maxLines: 2),
          const SizedBox(height: 10),
          BrandTextField(controller: order, hint: 'Sequence (0 = first)', prefixIcon: Icons.sort, keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          Row(children: [
            const Text('Category:'),
            const SizedBox(width: 10),
            ChoiceChip(label: const Text('Premium'), selected: categoryId == 1, onSelected: (_) => setSheet(() => categoryId = 1)),
            const SizedBox(width: 8),
            ChoiceChip(label: const Text('Free'), selected: categoryId == 2, onSelected: (_) => setSheet(() => categoryId = 2)),
          ]),
          const SizedBox(height: 16),
          GradientButton(
            label: busy ? 'Saving…' : 'Save', icon: Icons.check, loading: busy,
            onTap: () async {
              if (busy) return;
              if (name.text.trim().isEmpty) { Get.snackbar('Required', 'Name is required', snackPosition: SnackPosition.BOTTOM); return; }
              setSheet(() => busy = true);
              try {
                final fields = {
                  'name': name.text.trim(),
                  'description': desc.text.trim(),
                  'icon': icon.text.trim(),
                  'category_id': '$categoryId',
                  'sort_order': order.text.trim().isEmpty ? '0' : order.text.trim(),
                };
                if (existing == null) {
                  await _api.createServiceForm(fields: fields, icon: iconFile);
                } else {
                  await _api.updateService('${existing['id']}', fields);
                  if (iconFile != null) {
                    await _api.uploadServiceIcon('${existing['id']}', iconFile!);
                  }
                }
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
              } catch (e) {
                Get.snackbar('Failed', '$e', snackPosition: SnackPosition.BOTTOM);
              } finally { setSheet(() => busy = false); }
            },
          ),
          const SizedBox(height: 8),
        ]),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _adminScaffold('Services',
      _loading ? _loader() : ListView.builder(
        itemCount: _all.length,
        itemBuilder: (_, i) {
          final s = Map<String, dynamic>.from(_all[i]);
          final active = _isActive(s);
          return ListTile(
            title: Row(
              children: [
                Flexible(
                  child: Text('${s['name'] ?? ''}',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: active ? null : Colors.grey)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: active ? Colors.green.withOpacity(0.12) : Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(active ? 'Active' : 'Hidden',
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.green.shade700 : Colors.grey.shade600)),
                ),
              ],
            ),
            subtitle: Text('${s['category_slug'] ?? ''} · ${s['shops_count'] ?? 0} shops'),
            trailing: IconButton(icon: const Icon(Icons.edit, color: AppColors.gold),
                onPressed: () => _edit(existing: s)),
          );
        },
      ),
      actions: [BrandAppBarAction(icon: Icons.add, onTap: () => _edit())],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// POSTS (list + delete)
// ═════════════════════════════════════════════════════════════════════════
class AdminPostsScreen extends StatefulWidget {
  const AdminPostsScreen({super.key});
  @override
  State<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends State<AdminPostsScreen> {
  List<PostModel> _posts = [];
  bool _loading = true;
  String _period = 'all'; // all | latest | today | week

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getPosts(viewerId: Get.find<SessionService>().userId);
      _posts = list.map((e) => PostModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<PostModel> _byPeriod(String period) {
    final now = DateTime.now();
    if (period == 'today') {
      return _posts.where((p) =>
          p.createdAt.year == now.year &&
          p.createdAt.month == now.month &&
          p.createdAt.day == now.day).toList();
    }
    if (period == 'week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      return _posts.where((p) => p.createdAt.isAfter(weekAgo)).toList();
    }
    return _posts; // all / latest = every post
  }

  /// Posts filtered by the selected period (feed is already newest-first).
  List<PostModel> get _filtered => _byPeriod(_period);
  int _countFor(String period) => _byPeriod(period).length;

  Future<void> _delete(PostModel p) async {
    Get.dialog(AlertDialog(
      title: const Text('Delete Post'),
      content: Text('Delete ${p.userName}\'s post?'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(onPressed: () async {
          Get.back();
          try { await _api.deletePost(p.id, Get.find<SessionService>().userId ?? 0); await _load(); }
          catch (e) { Get.snackbar('Failed', '$e', snackPosition: SnackPosition.BOTTOM); }
        }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return _adminScaffold('Latest Posts', Column(children: [
      // Total count + date filters
      Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.dynamic_feed, color: AppColors.gold),
            const SizedBox(width: 8),
            Text('Total Posts', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            Text('${list.length}', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.gold)),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            ['all', 'All'], ['latest', 'Latest'], ['today', 'Today'], ['week', 'Week'],
          ].map((f) {
            final sel = _period == f[0];
            return ChoiceChip(
              label: Text('${f[1]} (${_countFor(f[0])})'),
              selected: sel,
              onSelected: (_) => setState(() => _period = f[0]),
            );
          }).toList()),
        ]),
      ),
      Expanded(
        child: _loading ? _loader() : list.isEmpty
          ? Center(child: Text('No posts for this period', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final p = list[i];
          final media = p.media.isNotEmpty ? p.media.first : null;
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(width: 56, height: 56,
                  child: (media == null || media.isVideo)
                      ? Container(color: Colors.black12, child: const Icon(Icons.play_circle_fill, color: Colors.black45))
                      : SafeNetworkImage(url: media.url)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.userName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
              ])),
              IconButton(icon: const Icon(Icons.visibility_outlined, color: AppColors.gold),
                  onPressed: () => Get.to(() => FullScreenPostViewer(post: p), fullscreenDialog: true)),
              IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _delete(p)),
            ]),
          );
        },
      ),
      ),
    ]));
  }
}

// ═════════════════════════════════════════════════════════════════════════
// BANNERS (list + add + delete)
// ═════════════════════════════════════════════════════════════════════════
class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});
  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  List<dynamic> _banners = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _banners = await _api.getBanners(all: true); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit({Map<String, dynamic>? existing}) async {
    final title = TextEditingController(text: existing?['title']?.toString() ?? '');
    final subtitle = TextEditingController(text: existing?['subtitle']?.toString() ?? '');
    final image = TextEditingController(text: existing?['image_url']?.toString() ?? '');
    final link = TextEditingController(text: existing?['link_url']?.toString() ?? '');
    File? file;
    bool active = existing == null ? true : (existing['is_active'] == 1 || existing['is_active'] == true);
    String start = adminDateStr(existing?['start_date']);
    String end = adminDateStr(existing?['end_date']);
    bool busy = false;

    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(ctx).viewInsets.bottom + 18),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(existing == null ? 'Add Banner' : 'Update Banner', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            BrandTextField(controller: title, hint: 'Title ', prefixIcon: Icons.title),
            const SizedBox(height: 10),
            BrandTextField(controller: subtitle, hint: 'Subtitle', prefixIcon: Icons.subtitles),
            const SizedBox(height: 10),
            if (existing == null)
              InkWell(
                onTap: () async {
                  final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (x != null) { file = File(x.path); setSheet(() {}); }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: file != null ? AppColors.goldBg : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: file != null ? AppColors.goldLight : Colors.grey.shade300),
                  ),
                  child: Row(children: [
                    Icon(file != null ? Icons.check_circle : Icons.upload_file, size: 18, color: file != null ? AppColors.gold : Colors.black54),
                    const SizedBox(width: 8),
                    Text(file != null ? 'Image selected' : 'Upload banner image', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            if (existing == null) const SizedBox(height: 10),
            BrandTextField(controller: image, hint: existing == null ? 'or paste Image URL' : 'Image URL', prefixIcon: Icons.link),
            const SizedBox(height: 10),
            BrandTextField(controller: link, hint: 'Tap Link URL (optional)', prefixIcon: Icons.touch_app),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: adminDatePicker(context, 'Start date', start, (v) => setSheet(() => start = v))),
              const SizedBox(width: 10),
              Expanded(child: adminDatePicker(context, 'End date', end, (v) => setSheet(() => end = v))),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Enabled (show to users)', style: GoogleFonts.poppins(fontSize: 13)),
              value: active, activeColor: AppColors.gold,
              onChanged: (v) => setSheet(() => active = v),
            ),
            const SizedBox(height: 10),
            GradientButton(label: busy ? 'Saving…' : 'Save', icon: Icons.check, loading: busy, onTap: () async {
              if (busy) return;
              // if (title.text.trim().isEmpty || (existing == null && file == null && image.text.trim().isEmpty)) {
              //   Get.snackbar('Required', 'Title and an image are required', snackPosition: SnackPosition.BOTTOM); return;
              // }
              if (existing == null && file == null && image.text.trim().isEmpty) {
                Get.snackbar(
                  'Required',
                  'Banner image is required',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              setSheet(() => busy = true);
              try {
                if (existing == null) {
                  await _api.createBannerUpload(fields: {
                    'title': title.text.trim(),
                    'subtitle': subtitle.text.trim(),
                    'image_url': image.text.trim(),
                    'link_url': link.text.trim(),
                    'is_active': active ? '1' : '0',
                    'start_date': start,
                    'end_date': end,
                  }, file: file);
                } else {
                  await _api.updateBanner('${existing['id']}', {
                    'title': title.text.trim(),
                    'subtitle': subtitle.text.trim(),
                    'image_url': image.text.trim(),
                    'link_url': link.text.trim(),
                    'is_active': active ? 1 : 0,
                    'start_date': start,
                    'end_date': end,
                  });
                }
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
              } catch (e) { Get.snackbar('Failed', '$e', snackPosition: SnackPosition.BOTTOM); }
              finally { setSheet(() => busy = false); }
            }),
            const SizedBox(height: 8),
          ]),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _adminScaffold('Banners',
      _loading ? _loader() : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _banners.length,
        itemBuilder: (_, i) {
          final b = Map<String, dynamic>.from(_banners[i]);
          final active = b['is_active'] == 1 || b['is_active'] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.hardEdge,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                SizedBox(height: 120, width: double.infinity, child: SafeNetworkImage(url: '${b['image_url']}')),
                Positioned(top: 8, right: 8, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: (active ? Colors.green : AppColors.error).withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                  child: Text(active ? 'Enabled' : 'Disabled', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                )),
              ]),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${b['title'] ?? ''}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    Text('${b['subtitle'] ?? ''}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                    if (adminDateStr(b['start_date']).isNotEmpty || adminDateStr(b['end_date']).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${adminDateStr(b['start_date']).isEmpty ? '—' : adminDateStr(b['start_date'])}  →  ${adminDateStr(b['end_date']).isEmpty ? '—' : adminDateStr(b['end_date'])}',
                            style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.gold)),
                      ),
                  ])),
                  IconButton(icon: const Icon(Icons.edit, color: AppColors.gold), onPressed: () => _edit(existing: b)),
                  IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: () async {
                    try { await _api.deleteBanner('${b['id']}'); await _load(); }
                    catch (e) { Get.snackbar('Failed', '$e', snackPosition: SnackPosition.BOTTOM); }
                  }),
                ]),
              ),
            ]),
          );
        },
      ),
      actions: [BrandAppBarAction(icon: Icons.add, onTap: () => _edit())],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// SERVICE BANNERS (per-service banners)
// ═════════════════════════════════════════════════════════════════════════
class AdminServiceBannersScreen extends StatefulWidget {
  const AdminServiceBannersScreen({super.key});
  @override
  State<AdminServiceBannersScreen> createState() => _AdminServiceBannersScreenState();
}

class _AdminServiceBannersScreenState extends State<AdminServiceBannersScreen> {
  List<Map<String, dynamic>> _services = [];
  int? _serviceId;
  List<dynamic> _banners = [];
  bool _loading = false;

  @override
  void initState() { super.initState(); _loadServices(); }

  Future<void> _loadServices() async {
    try {
      final data = await _api.getServices();
      final s = Map<String, dynamic>.from(data['services'] ?? {});
      _services = [...(s['premium'] ?? []), ...(s['free'] ?? [])]
          .map((e) => Map<String, dynamic>.from(e)).toList();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _loadBanners() async {
    if (_serviceId == null) return;
    setState(() => _loading = true);
    try { _banners = await _api.getServiceBanners(_serviceId!, all: true); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit({Map<String, dynamic>? existing}) async {
    final title = TextEditingController(text: existing?['title']?.toString() ?? '');
    final image = TextEditingController(text: existing?['image_url']?.toString() ?? '');
    final link = TextEditingController(text: existing?['link_url']?.toString() ?? '');
    File? file;
    int? sel = existing != null ? int.tryParse('${existing['service_id']}') : _serviceId;
    bool active = existing == null ? true : (existing['is_active'] == 1 || existing['is_active'] == true);
    String start = adminDateStr(existing?['start_date']);
    String end = adminDateStr(existing?['end_date']);
    bool busy = false;
    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(ctx).viewInsets.bottom + 18),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(existing == null ? 'Add Service Banner' : 'Update Service Banner', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            // Service type dropdown (only when creating)
            if (existing == null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                child: Row(children: [
                  const Icon(Icons.design_services_outlined, size: 20, color: AppColors.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: sel,
                        hint: Text('Select Service Type *', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
                        items: _services.map((s) => DropdownMenuItem<int>(
                              value: int.tryParse('${s['id']}'),
                              child: Text('${s['name']}', style: GoogleFonts.poppins(fontSize: 13)),
                            )).toList(),
                        onChanged: (v) => setSheet(() => sel = v),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
            ],
            BrandTextField(controller: title, hint: 'Title (optional)', prefixIcon: Icons.title),
            const SizedBox(height: 10),
            if (existing == null) ...[
              InkWell(
                onTap: () async {
                  final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (x != null) { file = File(x.path); setSheet(() {}); }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: file != null ? AppColors.goldBg : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: file != null ? AppColors.goldLight : Colors.grey.shade300),
                  ),
                  child: Row(children: [
                    Icon(file != null ? Icons.check_circle : Icons.upload_file, size: 18, color: file != null ? AppColors.gold : Colors.black54),
                    const SizedBox(width: 8),
                    Text(file != null ? 'Image selected' : 'Upload banner image', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
            ],
            BrandTextField(controller: image, hint: existing == null ? 'or paste Image URL' : 'Image URL', prefixIcon: Icons.link),
            const SizedBox(height: 10),
            BrandTextField(controller: link, hint: 'Tap Link URL (optional)', prefixIcon: Icons.touch_app),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: adminDatePicker(context, 'Start date', start, (v) => setSheet(() => start = v))),
              const SizedBox(width: 10),
              Expanded(child: adminDatePicker(context, 'End date', end, (v) => setSheet(() => end = v))),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Enabled (show to users)', style: GoogleFonts.poppins(fontSize: 13)),
              value: active, activeColor: AppColors.gold,
              onChanged: (v) => setSheet(() => active = v),
            ),
            const SizedBox(height: 10),
            GradientButton(label: busy ? 'Saving…' : 'Save', icon: Icons.check, loading: busy, onTap: () async {
              if (busy) return;
              if (existing == null && sel == null) {
                Get.snackbar('Required', 'Select a service type', snackPosition: SnackPosition.BOTTOM); return;
              }
              if (existing == null && file == null && image.text.trim().isEmpty) {
                Get.snackbar('Required', 'Upload an image or paste a URL', snackPosition: SnackPosition.BOTTOM); return;
              }
              setSheet(() => busy = true);
              try {
                if (existing == null) {
                  await _api.createServiceBanner(fields: {
                    'service_id': '$sel',
                    'title': title.text.trim(),
                    'image_url': image.text.trim(),
                    'link_url': link.text.trim(),
                    'is_active': active ? '1' : '0',
                    'start_date': start,
                    'end_date': end,
                  }, file: file);
                  setState(() => _serviceId = sel);
                } else {
                  await _api.updateServiceBanner('${existing['id']}', {
                    'title': title.text.trim(),
                    'image_url': image.text.trim(),
                    'link_url': link.text.trim(),
                    'is_active': active ? 1 : 0,
                    'start_date': start,
                    'end_date': end,
                  });
                }
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadBanners();
              } catch (e) { Get.snackbar('Failed', '$e', snackPosition: SnackPosition.BOTTOM); }
              finally { setSheet(() => busy = false); }
            }),
            const SizedBox(height: 8),
          ]),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _adminScaffold('Service Banners', Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.design_services_outlined, size: 18, color: AppColors.gold),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _serviceId,
                  hint: Text('Select a service', style: GoogleFonts.poppins(fontSize: 13)),
                  items: _services.map((s) => DropdownMenuItem<int>(
                        value: int.tryParse('${s['id']}'),
                        child: Text('${s['name']}', style: GoogleFonts.poppins(fontSize: 13)),
                      )).toList(),
                  onChanged: (v) { setState(() => _serviceId = v); _loadBanners(); },
                ),
              ),
            ),
          ]),
        ),
      ),
      Expanded(
        child: _serviceId == null
            ? Center(child: Text('Select a service to manage its banners', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)))
            : _loading
                ? _loader()
                : _banners.isEmpty
                    ? Center(child: Text('No banners for this service', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _banners.length,
                        itemBuilder: (_, i) {
                          final b = Map<String, dynamic>.from(_banners[i]);
                          final active = b['is_active'] == 1 || b['is_active'] == true;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            clipBehavior: Clip.hardEdge,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Stack(children: [
                                SizedBox(height: 120, width: double.infinity, child: SafeNetworkImage(url: '${b['image_url']}')),
                                Positioned(top: 8, right: 8, child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: (active ? Colors.green : AppColors.error).withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                                  child: Text(active ? 'Enabled' : 'Disabled', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                                )),
                              ]),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(children: [
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('${b['title'] ?? ''}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                    if (adminDateStr(b['start_date']).isNotEmpty || adminDateStr(b['end_date']).isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text('${adminDateStr(b['start_date']).isEmpty ? '—' : adminDateStr(b['start_date'])}  →  ${adminDateStr(b['end_date']).isEmpty ? '—' : adminDateStr(b['end_date'])}',
                                            style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.gold)),
                                      ),
                                  ])),
                                  IconButton(icon: const Icon(Icons.edit, color: AppColors.gold), onPressed: () => _edit(existing: b)),
                                  IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: () async {
                                    try { await _api.deleteServiceBanner('${b['id']}'); await _loadBanners(); }
                                    catch (e) { Get.snackbar('Failed', '$e', snackPosition: SnackPosition.BOTTOM); }
                                  }),
                                ]),
                              ),
                            ]),
                          );
                        },
                      ),
      ),
    ]), actions: [BrandAppBarAction(icon: Icons.add, onTap: () => _edit())]);
  }
}

// ═════════════════════════════════════════════════════════════════════════
// PRICING (shop listing charges)
// ═════════════════════════════════════════════════════════════════════════
class AdminPricingScreen extends StatefulWidget {
  const AdminPricingScreen({super.key});
  @override
  State<AdminPricingScreen> createState() => _AdminPricingScreenState();
}

class _AdminPricingScreenState extends State<AdminPricingScreen> {
  final _first = TextEditingController();
  final _add = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await _api.getPricingSettings();
      _first.text = '${s['first_shop_price'] ?? 3000}';
      _add.text = '${s['additional_shop_price'] ?? 1000}';
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.updatePricingSettings({
        'first_shop_price': int.tryParse(_first.text.trim()) ?? 0,
        'additional_shop_price': int.tryParse(_add.text.trim()) ?? 0,
      });
      Get.snackbar('Saved', 'Pricing updated', snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Failed', '$e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _adminScaffold('Pricing',
      _loading ? _loader() : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Shop listing charges', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('These amounts are charged when a user lists shops. Users pay the first-shop price for their first shop, then the additional price for every extra service/shop.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          BrandTextField(controller: _first, hint: 'First shop price (₹)', prefixIcon: Icons.looks_one_outlined, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          BrandTextField(controller: _add, hint: 'Additional shop price (₹)', prefixIcon: Icons.add_circle_outline, keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          GradientButton(label: _saving ? 'Saving…' : 'Save Pricing', icon: Icons.save, loading: _saving, onTap: _save),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.goldBg, borderRadius: BorderRadius.circular(12)),
            child: Text(
              'Example: 5 services on the first listing = ₹${(int.tryParse(_first.text) ?? 0) + 4 * (int.tryParse(_add.text) ?? 0)}.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// APP VERSIONS (force / soft update)
// ═════════════════════════════════════════════════════════════════════════
class AdminAppVersionsScreen extends StatefulWidget {
  const AdminAppVersionsScreen({super.key});
  @override
  State<AdminAppVersionsScreen> createState() => _AdminAppVersionsScreenState();
}

class _AdminAppVersionsScreenState extends State<AdminAppVersionsScreen> {
  List<dynamic> _versions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _versions = await _api.getAppVersions(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit({Map<String, dynamic>? existing}) async {
    final version = TextEditingController(text: existing?['version_name']?.toString() ?? '');
    final build = TextEditingController(text: '${existing?['build_number'] ?? ''}');
    final desc = TextEditingController(text: existing?['description']?.toString() ?? '');
    final release = TextEditingController(text: '${existing?['release_date'] ?? ''}'.split('T').first);
    String platform = existing?['platform']?.toString() ?? 'Android';
    bool force = existing?['is_force_update'] == true;
    bool active = existing == null ? true : existing['is_active'] == true;
    bool busy = false;

    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(ctx).viewInsets.bottom + 18),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(existing == null ? 'Add Version' : 'Update Version',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Row(children: [
              ChoiceChip(label: const Text('Android'), selected: platform == 'Android', onSelected: (_) => setSheet(() => platform = 'Android')),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('iOS'), selected: platform == 'iOS', onSelected: (_) => setSheet(() => platform = 'iOS')),
            ]),
            const SizedBox(height: 10),
            BrandTextField(controller: version, hint: 'Version name * (e.g. 1.0.1)', prefixIcon: Icons.tag),
            const SizedBox(height: 10),
            BrandTextField(controller: build, hint: 'Build number *', prefixIcon: Icons.numbers, keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            BrandTextField(controller: desc, hint: 'Description', prefixIcon: Icons.notes, maxLines: 2),
            const SizedBox(height: 10),
            BrandTextField(controller: release, hint: 'Release date (YYYY-MM-DD)', prefixIcon: Icons.event),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Force update', style: GoogleFonts.poppins(fontSize: 13)),
              value: force, activeColor: AppColors.gold,
              onChanged: (v) => setSheet(() => force = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Active', style: GoogleFonts.poppins(fontSize: 13)),
              value: active, activeColor: AppColors.gold,
              onChanged: (v) => setSheet(() => active = v),
            ),
            const SizedBox(height: 10),
            GradientButton(label: busy ? 'Saving…' : 'Save', icon: Icons.check, loading: busy, onTap: () async {
              if (busy) return;
              if (version.text.trim().isEmpty || build.text.trim().isEmpty) {
                Get.snackbar('Required', 'Version name and build number are required', snackPosition: SnackPosition.BOTTOM); return;
              }
              setSheet(() => busy = true);
              try {
                final body = {
                  'platform': platform,
                  'version_name': version.text.trim(),
                  'build_number': int.tryParse(build.text.trim()) ?? 0,
                  'description': desc.text.trim(),
                  'is_force_update': force,
                  'is_active': active,
                  'release_date': release.text.trim().isEmpty ? null : release.text.trim(),
                };
                if (existing == null) { await _api.createAppVersion(body); }
                else { await _api.updateAppVersion('${existing['id']}', body); }
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
              } catch (e) { Get.snackbar('Failed', '$e', snackPosition: SnackPosition.BOTTOM); }
              finally { setSheet(() => busy = false); }
            }),
            const SizedBox(height: 8),
          ]),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _adminScaffold('App Update',
      _loading ? _loader() : _versions.isEmpty
          ? Center(child: Text('No versions yet', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _versions.length,
              itemBuilder: (_, i) {
                final v = Map<String, dynamic>.from(_versions[i]);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${v['platform']} · v${v['version_name']} (build ${v['build_number']})',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('${v['description'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, children: [
                        if (v['is_active'] == true) _pill('Active', Colors.green),
                        if (v['is_force_update'] == true) _pill('Force', AppColors.error),
                      ]),
                    ])),
                    IconButton(icon: const Icon(Icons.edit, color: AppColors.gold), onPressed: () => _edit(existing: v)),
                  ]),
                );
              },
            ),
      actions: [BrandAppBarAction(icon: Icons.add, onTap: () => _edit())],
    );
  }

  Widget _pill(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
      );
}

// ═════════════════════════════════════════════════════════════════════════
// LOCATIONS (manage states + cities)
// ═════════════════════════════════════════════════════════════════════════
class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({super.key});
  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen> {
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _cities = [];
  Map<String, dynamic>? _selectedState;
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadStates(); }

  Future<void> _loadStates() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getStatesRaw();
      _states = list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadCities(int stateId) async {
    try {
      final list = await _api.getDistricts(stateId);
      _cities = list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) { _cities = []; }
    if (mounted) setState(() {});
  }

  // ---- state add/edit ----
  Future<void> _editState({Map<String, dynamic>? existing}) async {
    final name = TextEditingController(text: existing?['name']?.toString() ?? '');
    final code = TextEditingController(text: existing?['code']?.toString() ?? '');
    await _sheet(existing == null ? 'Add State' : 'Update State', [
      (setSheet) => BrandTextField(controller: name, hint: 'State Name *', prefixIcon: Icons.map),
      (setSheet) => BrandTextField(controller: code, hint: 'Code (e.g. MH)', prefixIcon: Icons.tag),
    ], () async {
      if (name.text.trim().isEmpty) { Get.snackbar('Required', 'State name is required', snackPosition: SnackPosition.BOTTOM); return false; }
      final body = {'name': name.text.trim(), 'code': code.text.trim()};
      if (existing == null) { await _api.createState(body); }
      else { await _api.updateState('${existing['id']}', body); }
      await _loadStates();
      return true;
    });
  }

  // ---- city add/edit ----
  Future<void> _editCity({Map<String, dynamic>? existing}) async {
    if (_selectedState == null) { Get.snackbar('Select state', 'Pick a state first', snackPosition: SnackPosition.BOTTOM); return; }
    final name = TextEditingController(text: existing?['name']?.toString() ?? '');
    await _sheet(existing == null ? 'Add City' : 'Update City', [
      (setSheet) => BrandTextField(controller: name, hint: 'City Name *', prefixIcon: Icons.location_city),
    ], () async {
      if (name.text.trim().isEmpty) { Get.snackbar('Required', 'City name is required', snackPosition: SnackPosition.BOTTOM); return false; }
      final body = {'name': name.text.trim(), 'state_id': _selectedState!['id']};
      if (existing == null) { await _api.createDistrict(body); }
      else { await _api.updateDistrict('${existing['id']}', body); }
      await _loadCities(int.parse('${_selectedState!['id']}'));
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _adminScaffold('Locations',
      _loading
          ? _loader()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Summary strip ──
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.goldLight, AppColors.goldDim],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _summaryStat('${_states.length}', 'States', Icons.map_outlined),
                      Container(width: 1, height: 34, color: Colors.white30),
                      _summaryStat(
                        _selectedState == null ? '—' : '${_cities.length}',
                        _selectedState == null
                            ? 'Cities'
                            : 'in ${_selectedState!['name']}',
                        Icons.location_city_outlined,
                      ),
                    ],
                  ),
                ),

                // ── States ──
                _sectionRow('States', 'Add State', () => _editState()),
                SizedBox(
                  height: 46,
                  child: _states.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('No states yet — add one',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _states.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) => _stateChip(_states[i]),
                        ),
                ),

                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1, color: AppColors.cardBorder),
                ),

                // ── Cities ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedState == null
                              ? 'Cities'
                              : 'Cities in ${_selectedState!['name']}',
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (_selectedState != null)
                        _addBtn('Add City', () => _editCity()),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedState == null
                      ? _emptyState(Icons.touch_app_outlined, 'Select a state',
                          'Tap a state above to manage its cities')
                      : _cities.isEmpty
                          ? _emptyState(Icons.location_off_outlined,
                              'No cities yet',
                              'Add the first city for ${_selectedState!['name']}')
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 20),
                              itemCount: _cities.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) => _cityCard(_cities[i]),
                            ),
                ),
              ],
            ),
    );
  }

  Widget _summaryStat(String value, String label, IconData icon) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.1)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.85), fontSize: 10.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionRow(String title, String action, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          const Spacer(),
          _addBtn(action, onTap),
        ],
      ),
    );
  }

  Widget _addBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.goldBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.goldLight.withOpacity(0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 15, color: AppColors.gold),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold)),
          ],
        ),
      ),
    );
  }

  Widget _stateChip(Map<String, dynamic> s) {
    final sel = _selectedState != null && _selectedState!['id'] == s['id'];
    return GestureDetector(
      onTap: () {
        setState(() => _selectedState = s);
        _loadCities(int.parse('${s['id']}'));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.gold : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: sel ? AppColors.gold : AppColors.cardBorder),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sel)
              const Padding(
                padding: EdgeInsets.only(right: 5),
                child: Icon(Icons.check, size: 15, color: Colors.white),
              ),
            Text('${s['name']}',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : AppColors.textPrimary)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _editState(existing: s),
              child: Icon(Icons.edit,
                  size: 14, color: sel ? Colors.white70 : AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cityCard(Map<String, dynamic> c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.goldBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_city, size: 19, color: AppColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${c['name']}',
                style: GoogleFonts.poppins(
                    fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
          InkWell(
            onTap: () => _editCity(existing: c),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.edit, size: 19, color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: AppColors.cardBorder),
          const SizedBox(height: 12),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 11.5, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  /// Generic add/edit sheet; builders receive setSheet; onSubmit returns true to close.
  Future<void> _sheet(String title, List<Widget Function(void Function(void Function()))> builders, Future<bool> Function() onSubmit) async {
    bool busy = false;
    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(ctx).viewInsets.bottom + 18),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ...builders.map((b) => Padding(padding: const EdgeInsets.only(bottom: 10), child: b(setSheet))),
          const SizedBox(height: 6),
          GradientButton(label: busy ? 'Saving…' : 'Save', icon: Icons.check, loading: busy, onTap: () async {
            if (busy) return;
            setSheet(() => busy = true);
            try {
              final ok = await onSubmit();
              if (ok && ctx.mounted) Navigator.pop(ctx);
            } catch (e) { Get.snackbar('Failed', '$e', snackPosition: SnackPosition.BOTTOM); }
            finally { setSheet(() => busy = false); }
          }),
          const SizedBox(height: 8),
        ]),
      )),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// CONTACTS (list)
// ═════════════════════════════════════════════════════════════════════════
class AdminContactsScreen extends StatefulWidget {
  const AdminContactsScreen({super.key});
  @override
  State<AdminContactsScreen> createState() => _AdminContactsScreenState();
}

class _AdminContactsScreenState extends State<AdminContactsScreen> {
  List<dynamic> _all = [];
  bool _loading = true;
  String _status = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _all = await _api.getContacts(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<dynamic> get _shown => _status.isEmpty
      ? _all
      : _all.where((e) => '${Map.from(e)['status'] ?? ''}' == _status).toList();

  int _countFor(String s) => s.isEmpty
      ? _all.length
      : _all.where((e) => '${Map.from(e)['status'] ?? ''}' == s).length;

  Future<void> _setStatus(String id, String status) async {
    try {
      await _api.updateContact(id, {'status': status});
      await _load();
      Get.snackbar('Updated', 'Status set to ${status.replaceAll('_', ' ')}',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Failed', '$e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _adminScaffold('Contact Us', Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['', 'new', 'in_progress', 'resolved', 'closed'].map((s) {
                final sel = _status == s;
                final label = (s.isEmpty ? 'All' : s.replaceAll('_', ' '));
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$label (${_countFor(s)})'),
                    selected: sel,
                    onSelected: (_) => setState(() => _status = s),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: _loading ? _loader() : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _shown.length,
            itemBuilder: (_, i) {
              final c = Map<String, dynamic>.from(_shown[i]);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text('${c['name'] ?? ''}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700))),
                    PopupMenuButton<String>(
                      onSelected: (v) => _setStatus('${c['id']}', v),
                      itemBuilder: (_) => ['new', 'in_progress', 'resolved', 'closed']
                          .map((s) => PopupMenuItem(value: s, child: Text(s.replaceAll('_', ' ')))).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.goldBg, borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('${c['status'] ?? ''}'.replaceAll('_', ' '),
                              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w600)),
                          const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.gold),
                        ]),
                      ),
                    ),
                  ]),
                  Text('${c['mobile_number'] ?? ''} · ${c['email'] ?? ''}',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text('${c['message'] ?? ''}', style: GoogleFonts.poppins(fontSize: 12.5)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(_fmtDateTime('${c['created_at'] ?? ''}'),
                        style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.textMuted)),
                  ]),
                ]),
              );
            },
          ),
        ),
      ],
    ));
  }
}

// ═════════════════════════════════════════════════════════════════════════
// IMPORT SHOPS (bulk from Excel)
// ═════════════════════════════════════════════════════════════════════════
class AdminImportScreen extends StatefulWidget {
  const AdminImportScreen({super.key});
  @override
  State<AdminImportScreen> createState() => _AdminImportScreenState();
}

class _AdminImportScreenState extends State<AdminImportScreen> {
  final _location = Get.find<LocationController>();
  final _services = Get.find<ServicesController>();

  ServiceCategory? _service;
  String? _state;
  String? _city;
  String _userType = 'Shop Owner';
  String _fileName = '';
  List<Map<String, String>> _rows = [];
  bool _busy = false;

  static const _userTypes = [
    'Interior Designer', 'Architect', 'Builder', 'End Customer', 'Shop Owner',
  ];

  @override
  void initState() {
    super.initState();
    if (_services.categories.isEmpty) _services.load();
    _location.loadStates();
  }

  /// Reads any excel cell type to a clean string (handles phone-as-number).
  /// Uses dynamic `.value` access so it works across excel package versions.
  String _cellStr(xls.Data? d) {
    final v = d?.value;
    if (v == null) return '';
    dynamic inner;
    try {
      inner = (v as dynamic).value; // TextCellValue.value(String), IntCellValue.value(int)…
    } catch (_) {
      inner = null;
    }
    final val = inner ?? v;
    if (val is double) {
      return val == val.roundToDouble() ? val.toInt().toString() : val.toString();
    }
    if (val is int) return val.toString();
    return val.toString().trim();
  }

  Future<void> _pickFile() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );
      if (res == null || res.files.isEmpty) return;
      final f = res.files.first;
      final bytes = f.bytes;
      if (bytes == null) {
        Get.snackbar('Error', 'Could not read the file',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final book = xls.Excel.decodeBytes(bytes);
      final rows = <Map<String, String>>[];
      for (final t in book.tables.keys) {
        final sheet = book.tables[t]!;
        // Row 0 is the header — start at 1.
        for (int r = 1; r < sheet.maxRows; r++) {
          final cells = sheet.rows[r];
          String c(int i) => i < cells.length ? _cellStr(cells[i]) : '';
          final firm = c(0), name = c(1), addr = c(2),
              phone = c(3), alt = c(4), email = c(5);
          if (firm.isEmpty && name.isEmpty && phone.isEmpty) continue;
          rows.add({
            'firm': firm, 'name': name, 'address': addr,
            'phone': phone, 'alt': alt, 'email': email,
          });
        }
        break; // first sheet only
      }
      setState(() { _fileName = f.name; _rows = rows; });
      Get.snackbar('Parsed', '${rows.length} rows found',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Parse error', '$e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _import() async {
    if (_busy) return;
    if (_service == null) {
      Get.snackbar('Required', 'Select a service', snackPosition: SnackPosition.BOTTOM); return;
    }
    if (_state == null || _city == null) {
      Get.snackbar('Required', 'Select state and city', snackPosition: SnackPosition.BOTTOM); return;
    }
    if (_rows.isEmpty) {
      Get.snackbar('No data', 'Pick an Excel file first', snackPosition: SnackPosition.BOTTOM); return;
    }
    setState(() => _busy = true);
    try {
      final res = await _api.importShops(
        serviceId: int.parse(_service!.id),
        state: _state!,
        city: _city!,
        userType: _userType,
        rows: _rows,
      );
      _showResult(res);
    } catch (e) {
      Get.snackbar('Import failed', '$e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showResult(Map<String, dynamic> r) {
    final errors = (r['errors'] is List) ? List.from(r['errors']) : [];
    Get.dialog(AlertDialog(
      title: const Text('Import Complete'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shops created: ${r['shops_created'] ?? 0}'),
            Text('New users: ${r['users_created'] ?? 0}'),
            Text('Existing users reused: ${r['users_reused'] ?? 0}'),
            Text('Skipped: ${r['skipped'] ?? 0}'),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Issues (${errors.length}):',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              ...errors.take(12).map((e) =>
                  Text('• $e', style: const TextStyle(fontSize: 11))),
              if (errors.length > 12) Text('…and ${errors.length - 12} more'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
            setState(() { _rows = []; _fileName = ''; });
          },
          child: const Text('OK'),
        ),
      ],
    ));
  }

  Widget _ddWrap({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return _adminScaffold('Import Shops', ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Bulk-import shops from an Excel sheet.\nColumns (in order): Firm · Name · Address · Phone · Alternative · Email. Row 1 is treated as the header.',
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        _ddWrap(
          child: DropdownButton<ServiceCategory>(
            isExpanded: true, underline: const SizedBox(), value: _service,
            hint: const Text('Select Service *'),
            items: _services.categories
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                .toList(),
            onChanged: (v) => setState(() => _service = v),
          ),
        ),
        const SizedBox(height: 10),
        Obx(() => _ddWrap(
              child: DropdownButton<String>(
                isExpanded: true, underline: const SizedBox(), value: _state,
                hint: const Text('Select State *'),
                items: _location.stateNames
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  setState(() { _state = v; _city = null; });
                  if (v != null) _location.loadDistricts(v);
                },
              ),
            )),
        const SizedBox(height: 10),
        Obx(() => _ddWrap(
              child: DropdownButton<String>(
                isExpanded: true, underline: const SizedBox(),
                value: (_city != null && _location.districtNames.contains(_city))
                    ? _city : null,
                hint: const Text('Select City *'),
                items: _location.districtNames
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _city = v),
              ),
            )),
        const SizedBox(height: 10),
        // User type for the imported owners.
        _ddWrap(
          child: DropdownButton<String>(
            isExpanded: true, underline: const SizedBox(), value: _userType,
            hint: const Text('User Type'),
            items: _userTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _userType = v ?? 'Shop Owner'),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.upload_file, color: AppColors.gold),
          label: Text(_fileName.isEmpty ? 'Pick Excel File (.xlsx)' : _fileName,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(color: AppColors.gold, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.goldLight),
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        if (_rows.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.goldBg, borderRadius: BorderRadius.circular(12)),
            child: Text('${_rows.length} rows ready to import',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          ..._rows.take(5).map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• ${r['firm']} — ${r['name']} (${r['phone']})',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 11.5)),
              )),
          if (_rows.length > 5)
            Text('…and ${_rows.length - 5} more',
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 20),
        GradientButton(
          label: _busy ? 'Importing…' : 'Import ${_rows.length} Shops',
          icon: Icons.cloud_upload,
          loading: _busy,
          onTap: _import,
        ),
      ],
    ));
  }
}
