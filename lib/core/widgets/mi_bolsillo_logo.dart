import 'package:material_ui/material_ui.dart';

enum MiBolsilloLogoVariant { icon, horizontal, vertical, androidBadge }

/// Renders the official Mi Bolsillo logo assets adapted for light and dark themes.
class MiBolsilloLogo extends StatelessWidget {
  const MiBolsilloLogo({
    super.key,
    this.variant = MiBolsilloLogoVariant.horizontal,
    this.height = 36,
    this.forceDarkSurface = false,
  });

  final MiBolsilloLogoVariant variant;
  final double height;
  final bool forceDarkSurface;

  @override
  Widget build(BuildContext context) {
    final isDark =
        forceDarkSurface || Theme.of(context).brightness == Brightness.dark;

    switch (variant) {
      case MiBolsilloLogoVariant.icon:
        return Semantics(
          label: 'Logo oficial de Mi Bolsillo',
          child: Image.asset(
            'assets/images/logo_icon.png',
            height: height,
            fit: BoxFit.contain,
          ),
        );
      case MiBolsilloLogoVariant.androidBadge:
        return Semantics(
          label: 'Ícono oficial de Mi Bolsillo',
          child: Image.asset(
            'assets/images/logo_android.png',
            height: height,
            width: height,
            fit: BoxFit.contain,
          ),
        );
      case MiBolsilloLogoVariant.vertical:
        return Semantics(
          label: 'Mi Bolsillo',
          child: Image.asset(
            isDark
                ? 'assets/images/logo_vertical_dark.png'
                : 'assets/images/logo_vertical_light.png',
            height: height,
            fit: BoxFit.contain,
          ),
        );
      case MiBolsilloLogoVariant.horizontal:
        if (!isDark) {
          return Semantics(
            label: 'Mi Bolsillo',
            child: Image.asset(
              'assets/images/logo_horizontal.png',
              height: height,
              fit: BoxFit.contain,
            ),
          );
        }
        return Semantics(
          label: 'Mi Bolsillo',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_android.png',
                height: height,
                width: height,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                'Mi Bolsillo',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
    }
  }
}
