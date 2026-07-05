import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Monogramme "F" de Fafoutt Store — cercle marine avec liseré or.
class FafouttLogo extends StatelessWidget {
  final double size;
  const FafouttLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.navy,
        border: Border.all(color: AppColors.gold, width: size * 0.045),
      ),
      alignment: Alignment.center,
      child: Text(
        'F',
        style: GoogleFonts.poppins(
          fontSize: size * 0.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

/// Bandeau titre avec logo + nom du magasin, utilisé en en-tête d'écran.
/// Si [onTap] est fourni, le logo devient cliquable (menu principal).
class FafouttHeader extends StatelessWidget {
  final String subtitle;
  final VoidCallback? onTap;
  const FafouttHeader({super.key, this.subtitle = 'Point de Vente', this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        FafouttLogo(size: 34),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Fafoutt Store',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white70,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: content,
      ),
    );
  }
}
