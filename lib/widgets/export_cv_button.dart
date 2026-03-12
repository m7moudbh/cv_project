import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/auth_provider.dart';
import '../../data/services/pdf_export_service.dart';

class ExportCVButton extends StatefulWidget {
  final bool compact; // compact = icon only (for app bar)

  const ExportCVButton({super.key, this.compact = false});

  @override
  State<ExportCVButton> createState() => _ExportCVButtonState();
}

class _ExportCVButtonState extends State<ExportCVButton> {
  final PdfExportService _pdfService = PdfExportService();
  bool _isExporting = false;

  Future<void> _export({bool preview = false}) async {
    setState(() => _isExporting = true);
    try {
      final auth = context.read<AuthProvider>();
      final userData = {
        ...?auth.userData,
        'email': auth.user?.email ?? '',
        'photoUrl': auth.userData?['photoUrl'] ?? auth.user?.photoURL ?? '',
      };

      if (preview) {
        await _pdfService.previewCV(userData: userData);
      } else {
        await _pdfService.exportCV(userData: userData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e',
                style: GoogleFonts.dmSans(color: Colors.white)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppColors.goldGlow,
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: AppColors.textOnGold, size: 28),
              ),

              const SizedBox(height: 16),

              Text(
                'Export CV as PDF',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Generate a professional PDF resume\nfrom your profile data',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // Preview button
              _ExportOption(
                icon: Icons.preview_rounded,
                title: 'Preview PDF',
                subtitle: 'View before downloading',
                color: AppColors.accentBlue,
                onTap: () {
                  Navigator.pop(context);
                  _export(preview: true);
                },
              ),

              const SizedBox(height: 12),

              // Export & Share button
              _ExportOption(
                icon: Icons.share_rounded,
                title: 'Export & Share',
                subtitle: 'Download and share your CV',
                color: AppColors.gold,
                onTap: () {
                  Navigator.pop(context);
                  _export(preview: false);
                },
              ),

              const SizedBox(height: 16),

              // Info note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fill your profile completely for a better looking CV',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      // App bar icon button
      return GestureDetector(
        onTap: _isExporting ? null : _showExportSheet,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: _isExporting
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold,
            ),
          )
              : const Icon(Icons.picture_as_pdf_rounded,
              size: 16, color: AppColors.gold),
        ),
      );
    }

    // Full button
    return GestureDetector(
      onTap: _isExporting ? null : _showExportSheet,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isExporting
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.gold),
            )
                : const Icon(Icons.picture_as_pdf_rounded,
                size: 18, color: AppColors.gold),
            const SizedBox(width: 10),
            Text(
              _isExporting ? 'Generating...' : 'Export PDF',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: color),
          ],
        ),
      ),
    );
  }
}