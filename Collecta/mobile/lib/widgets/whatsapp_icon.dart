import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The official WhatsApp glyph (brand SVG), tinted. Never an emoji.
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 18, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/whatsapp.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
