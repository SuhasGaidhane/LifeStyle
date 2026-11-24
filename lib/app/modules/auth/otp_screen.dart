import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../controllers/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AuthController>();
    final mobile = (Get.arguments as String?) ?? '+91 1234567890';
    return Scaffold(
      backgroundColor: AppColors.cardBg,

      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Column(
                children: [
                  Text('Verify OTP',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 10),
                  Text('Enter the 6-digit code sent to',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      )),
                  const SizedBox(height: 4),
                  Text(mobile,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 35),
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: c.otpCtrl,
                    animationType: AnimationType.fade,
                    keyboardType: TextInputType.number,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(10),
                      fieldHeight: 56,
                      fieldWidth: 56,
                      activeColor: AppColors.accentGreen,
                      inactiveColor: Colors.grey.shade300,
                      selectedColor: AppColors.primaryNavy,
                      activeFillColor: Colors.white,
                      inactiveFillColor: Colors.white,
                      selectedFillColor: Colors.white,
                    ),
                    enableActiveFill: true,
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 22),
                  Obx(() => CustomTextButton(
                    label: 'Verify & Login',
                    loading: c.isLoading.value,
                    onTap: c.verifyOtp,
                  )),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Didn\'t receive code? ',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textBlack,
                          )),
                      GestureDetector(
                        onTap: c.resendOtp,
                        child: Text('Resend',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.primaryRed,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ],
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
