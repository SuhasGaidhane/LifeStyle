import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..forward();
  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);


  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      // Logged-in users land straight on Home (user restored from GetStorage).
      final auth = Get.find<AuthController>();
      Get.offAllNamed(auth.isLoggedIn ? AppRoutes.home : AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/baground.png'),
              fit: BoxFit.cover,
              // colorFilter:
              //     ColorFilter.mode(Color(0xCCFBF8E8), BlendMode.lighten),
            ),
          ),
          child: FadeTransition(
            opacity: _fade,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  SizedBox(
                      height: 150,
                      child: Image.asset("assets/images/lifestylelogo.png")),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 100,
                  ),
                  Text('Concept By:',
                      style: GoogleFonts.poppins(
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                          decoration: TextDecoration.underline,
                          color: AppColors.textBlack)),
                  const SizedBox(height: 6),
                  SizedBox(
                      height: 70,
                      child: Image.asset("assets/images/sidheshLogo.png")),
                  const SizedBox(height: 30),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: AppColors.accentGreen,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
