import 'dart:ui';

extension ColorX on Color {
  Color changeOpacity(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0, 'Opacity must be between 0.0 and 1.0');
    return withAlpha((255.0 * opacity).round());
  }
}
