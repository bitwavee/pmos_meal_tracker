import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.subtitle,
    this.showWordmark = true,
  });

  final String? subtitle;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(
      'assets/images/pmos_logo.svg',
      width: 52,
      height: 52,
      fit: BoxFit.contain,
    );

    if (!showWordmark) {
      return icon;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PMOS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
