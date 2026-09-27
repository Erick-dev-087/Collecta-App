import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// Collecta brand mark (circular arc + checkmark) rendered from the SVG asset.
class CollectaLogo extends StatelessWidget {
  const CollectaLogo({super.key, this.size = 40, this.radius = 12});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset('assets/icons/logo.svg', fit: BoxFit.contain),
    );
  }
}

/// Full brand lockup: mark + "Collecta" wordmark and a small caption.
class CollectaWordmark extends StatelessWidget {
  const CollectaWordmark({
    super.key,
    this.caption = 'FINOPS ENGINE',
    this.onDark = false,
    this.size = 36,
  });

  final String caption;
  final bool onDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final titleColor = onDark ? Colors.white : AppColors.slateInk;
    final capColor = onDark ? AppColors.mintNeon : AppColors.emeraldDeep;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CollectaLogo(size: size),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Collecta',
                style: TextStyle(
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: titleColor,
                  height: 1.05,
                )),
            Text(caption,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: capColor,
                )),
          ],
        ),
      ],
    );
  }
}
