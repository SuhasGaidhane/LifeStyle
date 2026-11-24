import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/location_controller.dart';
import '../../controllers/services_controller.dart';
import '../../controllers/shop_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AddShopScreen extends StatefulWidget {
  const AddShopScreen({super.key});

  @override
  State<AddShopScreen> createState() => _AddShopScreenState();
}

class _AddShopScreenState extends State<AddShopScreen> {
  final c = Get.find<ShopController>();
  final _services = Get.find<ServicesController>();
  final _location = Get.find<LocationController>();

  @override
  void initState() {
    super.initState();
    c.prepareAddShop(); // load existing shop count + service list for pricing
    _location.loadStates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: const BrandAppBar(title: 'Add Shop'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Shop Details'),
            const SizedBox(height: 12),
            BrandTextField(
                controller: c.firmNameCtrl,
                hint: 'Firm Name *',
                prefixIcon: Icons.store),
            const SizedBox(height: 12),
            BrandTextField(
                controller: c.ownerNameCtrl,
                hint: 'Owner Name *',
                prefixIcon: Icons.person),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: BrandTextField(
                        controller: c.mobileCtrl,
                        hint: 'Mobile *',
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone)),
                const SizedBox(width: 10),
                Expanded(
                    child: BrandTextField(
                        controller: c.otherMobileCtrl,
                        hint: 'Other No.',
                        prefixIcon: Icons.phone_iphone,
                        keyboardType: TextInputType.phone)),
              ],
            ),
            const SizedBox(height: 12),
            BrandTextField(
                controller: c.emailCtrl,
                hint: 'Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            BrandTextField(
                controller: c.addressCtrl,
                hint: 'Address *',
                prefixIcon: Icons.home,
                maxLines: 2),
            const SizedBox(height: 12),
            // State + City dropdowns (drive Services-section filtering later)
            Obx(() => _dropdown(
                  label: 'State *',
                  icon: Icons.map,
                  value: c.selectedState.value.isEmpty ? null : c.selectedState.value,
                  items: _location.stateNames,
                  onChanged: (v) {
                    c.selectedState.value = v ?? '';
                    c.selectedCity.value = '';
                    if (v != null) _location.loadDistricts(v);
                  },
                )),
            const SizedBox(height: 12),
            Obx(() => _dropdown(
                  label: 'City *',
                  icon: Icons.location_city,
                  value: c.selectedCity.value.isEmpty ? null : c.selectedCity.value,
                  items: _location.districtNames,
                  onChanged: (v) => c.selectedCity.value = v ?? '',
                )),
            const SizedBox(height: 12),
            BrandTextField(
                controller: c.descCtrl,
                hint: 'Short Description',
                prefixIcon: Icons.notes,
                maxLines: 3),
            const SizedBox(height: 24),
            _sectionTitle('Select Type of Service'),
            const SizedBox(height: 6),
            Obx(() => Text(
                  c.existingShops.value > 0
                      ? 'You already have a shop — each additional service is ₹1000.'
                      : 'First service ₹3000, every additional service +₹1000.',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary),
                )),
            const SizedBox(height: 14),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: _services.categories.map((cat) {
                    final selected = c.isSelected(cat.name);
                    return InkWell(
                      onTap: () => c.toggleCategory(cat.name),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accentYellow
                              : Colors.white,
                          border: Border.all(
                              color: selected
                                  ? AppColors.accentYellow
                                  : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.add_circle_outline,
                                size: 16,
                                color: selected
                                    ? Colors.white
                                    : AppColors.accentGreen),
                            const SizedBox(width: 6),
                            Text(cat.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )),
            const SizedBox(height: 24),
            // Pricing summary card
            Obx(() => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accentGreen),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long,
                              color: AppColors.accentGreen),
                          const SizedBox(width: 8),
                          Text('Order Summary',
                              style: GoogleFonts.poppins(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...c.selectedCategories.asMap().entries.map((e) {
                        final i = e.key;
                        final cat = e.value;
                        final price = c.priceForLine(i);
                        final firstTime = c.existingShops.value == 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  (firstTime && i == 0)
                                      ? '$cat (1st)'
                                      : '$cat (additional)',
                                  style: GoogleFonts.poppins(fontSize: 13)),
                              Text('₹$price',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }),
                      if (c.selectedCategories.isNotEmpty) ...[
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            Text('₹${c.totalPrice}',
                                style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryNavy)),
                          ],
                        ),
                      ] else
                        Text('No categories selected yet',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                    ],
                  ),
                )),
            const SizedBox(height: 22),
            GradientButton(
              label: 'Continue to Payment',
              icon: Icons.arrow_forward,
              onTap: c.goToPayment,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));

  Widget _dropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accentGreen),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                hint: Text(label, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
                items: items
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.poppins(fontSize: 13))))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
