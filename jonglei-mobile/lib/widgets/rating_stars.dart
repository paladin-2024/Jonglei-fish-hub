import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int count;
  final double size;
  const RatingStars({super.key, required this.rating, this.count = 0, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) => Icon(
          i < rating.floor()
            ? Icons.star_rounded
            : (i < rating ? Icons.star_half_rounded : Icons.star_outline_rounded),
          size: size,
          color: AppColors.secondary,
        )),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Text('($count)', style: GoogleFonts.outfit(
            fontSize: size - 2, color: AppColors.textMuted)),
        ],
      ],
    );
  }
}
