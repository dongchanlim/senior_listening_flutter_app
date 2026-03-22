import 'package:flutter/material.dart';

class LargeActionButton extends StatefulWidget {
  const LargeActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.height = 82,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final double height;

  @override
  State<LargeActionButton> createState() => _LargeActionButtonState();
}

class _LargeActionButtonState extends State<LargeActionButton> {
  bool _pressed = false;

  Color _darken(Color color, [double amount = 0.25]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _lighten(Color color, [double amount = 0.12]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.backgroundColor ?? Theme.of(context).colorScheme.primary;
    final shadowColor = _darken(baseColor, 0.18);
    final topColor = _lighten(baseColor, 0.06);
    const shadowHeight = 5.0;
    const radius = 30.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: SizedBox(
        width: double.infinity,
        height: widget.height + shadowHeight,
        child: Stack(
          children: [
            // Shadow / 3D bottom edge
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: shadowColor,
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
            // Main button surface
            AnimatedPositioned(
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              top: _pressed ? shadowHeight : 0,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [topColor, baseColor],
                  ),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, size: 30, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
