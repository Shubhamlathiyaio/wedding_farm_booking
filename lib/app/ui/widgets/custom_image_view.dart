import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageView extends StatelessWidget {
  const ImageView(
    this.imagePath, {
    super.key,
    this.fit = BoxFit.cover,
    this.radius,
    this.width,
    this.height,
    this.color,
  });

  final String? imagePath;
  final double? radius;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildPlaceholder();
    }

    Widget widget;
    if (imagePath!.startsWith('http')) {
      widget = CachedNetworkImage(
        imageUrl: imagePath!,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, __) => _buildPlaceholder(),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      );
    } else {
      widget = Image.asset(
        imagePath!,
        fit: fit,
        width: width,
        height: height,
        color: color,
      );
    }

    if (radius != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius!),
        child: widget,
      );
    }
    return widget;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFF008450), size: 40),
      ),
    );
  }
}
