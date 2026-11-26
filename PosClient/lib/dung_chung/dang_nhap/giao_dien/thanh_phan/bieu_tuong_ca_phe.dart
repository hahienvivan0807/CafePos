import 'package:flutter/material.dart';
import '../../../../nen_tang/giao_dien/bang_mau.dart';

/// Biểu tượng ly cà phê nhận diện thương hiệu cho màn 01 · Đăng nhập
class CoffeeLogoBadge extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final Color? borderColor;

  const CoffeeLogoBadge({
    super.key,
    this.size = 52,
    this.backgroundColor = AppColors.mossBadgeBg,
    this.iconColor = AppColors.warmCreamText,
    this.borderColor = AppColors.mossBorderLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.48, size * 0.48),
          painter: _CoffeeCupIconPainter(color: iconColor),
        ),
      ),
    );
  }
}

class _CoffeeCupIconPainter extends CustomPainter {
  final Color color;

  const _CoffeeCupIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Hơi ấm cà phê phía trên
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.06),
      Offset(size.width * 0.34, size.height * 0.14),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.54, size.height * 0.04),
      Offset(size.width * 0.54, size.height * 0.14),
      paint,
    );

    // Thân ly
    final cupPath = Path()
      ..moveTo(size.width * 0.18, size.height * 0.24)
      ..lineTo(size.width * 0.72, size.height * 0.24)
      ..lineTo(size.width * 0.72, size.height * 0.50)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.74,
        size.width * 0.45,
        size.height * 0.74,
      )
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.74,
        size.width * 0.18,
        size.height * 0.50,
      )
      ..close();

    canvas.drawPath(cupPath, paint);

    // Quai ly bên phải
    final handlePath = Path()
      ..moveTo(size.width * 0.72, size.height * 0.28)
      ..lineTo(size.width * 0.82, size.height * 0.28)
      ..quadraticBezierTo(
        size.width * 0.94,
        size.height * 0.28,
        size.width * 0.94,
        size.height * 0.42,
      )
      ..quadraticBezierTo(
        size.width * 0.94,
        size.height * 0.56,
        size.width * 0.82,
        size.height * 0.56,
      )
      ..lineTo(size.width * 0.72, size.height * 0.56);

    canvas.drawPath(handlePath, paint);

    // Đĩa lót ly
    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.88),
      Offset(size.width * 0.76, size.height * 0.88),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CoffeeCupIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
