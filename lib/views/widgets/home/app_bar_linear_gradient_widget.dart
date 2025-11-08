import 'package:flutter/material.dart';

class AppBarLinearGradientWidget extends StatelessWidget {
  const AppBarLinearGradientWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6C757D), // #6c757d
            Color(0xFF224ABE), // #224abe
          ],
          stops: [0.10, 1.0],
        ),
      ),
    );
  }
}
