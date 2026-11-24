import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.cardBg,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Image.asset(
                  "assets/images/Banner.png",
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      height: 80,
                      child: Image.asset(
                        "assets/images/lifestylelogo.png",
                      ),
                    ),
                  ),
                ),
              ],
            ),


            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  const SizedBox(height: 30),
                  Text('Welcome',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 4,
                      )),
                  const SizedBox(height: 8),
                  Text('Login with your WhatsApp number to continue',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      )),
                  const SizedBox(height: 10),
                  BrandTextField(
                    controller: c.mobileCtrl,
                    hint: 'WhatsApp Number',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 22),
                  Obx(() => CustomTextButton(
                    label: 'Send OTP',
                    loading: c.isLoading.value,
                    onTap: c.sendOtp,
                  )),
                  const SizedBox(height: 30),
                  Text(
                    'By continuing you agree to our Terms & Privacy Policy',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),

                ],
              ),
            ),

            Image.asset("assets/images/Backgraund.png"),

          ],
        ),
      ),
    );
  }
}
