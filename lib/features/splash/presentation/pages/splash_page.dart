import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Requested White Background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using a local asset if available, or just a loader/text
            // Assuming 'assets/images/logo.png' exists based on manifest icon
            // But to be safe, use Icon or Text first.
            const Icon(Icons.storefront, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.primary),
             const SizedBox(height: 16),
             const Text("Memuat aplikasi...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
