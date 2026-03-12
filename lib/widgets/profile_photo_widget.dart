import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/auth_provider.dart';

class ProfilePhotoWidget extends StatefulWidget {
  final double size;
  final bool editable;

  const ProfilePhotoWidget({
    super.key,
    this.size = 96,
    this.editable = true,
  });

  @override
  State<ProfilePhotoWidget> createState() => _ProfilePhotoWidgetState();
}

class _ProfilePhotoWidgetState extends State<ProfilePhotoWidget> {
  final StorageService _storageService = StorageService();
  bool _isUploading = false;
  double _uploadProgress = 0;
  File? _localImage;

  Future<void> _pickAndUpload({required bool fromCamera}) async {
    Navigator.pop(context);

    try {
      final file = await _storageService.pickImage(fromCamera: fromCamera);
      if (file == null) return;

      setState(() {
        _localImage = file;
        _isUploading = true;
        _uploadProgress = 0;
      });

      // Upload to Cloudinary with progress callback
      final url = await _storageService.uploadProfilePhoto(
        file,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      // Save URL to Firestore
      await context.read<AuthProvider>().updateUserData({'photoUrl': url});

      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
        });
        _showSuccessSnack();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _localImage = null;
        });
        _showErrorSnack(e.toString());
      }
    }
  }

  void _showImageSourceSheet() {
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
              Text(
                'Update Profile Photo',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _SheetOption(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                color: AppColors.accentBlue,
                onTap: () => _pickAndUpload(fromCamera: false),
              ),
              const SizedBox(height: 12),
              _SheetOption(
                icon: Icons.camera_alt_rounded,
                label: 'Take a Photo',
                color: AppColors.accentGreen,
                onTap: () => _pickAndUpload(fromCamera: true),
              ),
              const SizedBox(height: 12),
              _SheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'Remove Photo',
                color: AppColors.error,
                onTap: () async {
                  Navigator.pop(context);
                  await _removePhoto();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removePhoto() async {
    setState(() => _isUploading = true);
    try {
      await _storageService.deleteProfilePhoto();
      await context.read<AuthProvider>().updateUserData({'photoUrl': ''});
      setState(() => _localImage = null);
    } catch (_) {}
    if (mounted) setState(() => _isUploading = false);
  }

  void _showSuccessSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Photo updated!',
            style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
        Text('Error: $msg', style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final photoUrl = auth.userData?['photoUrl'] as String? ??
        auth.user?.photoURL ??
        '';
    final name = auth.userData?['fullName'] as String? ??
        auth.user?.displayName ??
        'U';

    final size = widget.size;
    final radius = size * 0.28;

    return GestureDetector(
      onTap: widget.editable && !_isUploading
          ? _showImageSourceSheet
          : null,
      child: Stack(
        children: [
          // Photo container
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppColors.gold, width: 2.5),
              boxShadow: AppColors.goldGlow,
            ),
            child: ClipRRect(
              borderRadius:
              BorderRadius.circular(radius - 2),
              child: _buildImageContent(
                  photoUrl, name, size, _isUploading),
            ),
          ),

          // Upload progress overlay
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: size * 0.45,
                      height: size * 0.45,
                      child: CircularProgressIndicator(
                        value: _uploadProgress > 0 ? _uploadProgress : null,
                        strokeWidth: 3,
                        color: AppColors.gold,
                        backgroundColor:
                        AppColors.gold.withOpacity(0.2),
                      ),
                    ),
                    if (_uploadProgress > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${(_uploadProgress * 100).round()}%',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Edit badge
          if (widget.editable && !_isUploading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 14, color: AppColors.textOnGold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageContent(
      String photoUrl, String name, double size, bool isUploading) {
    // Show local file while uploading
    if (_localImage != null) {
      return Image.file(_localImage!, fit: BoxFit.cover);
    }

    // Show network image
    if (photoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildInitialAvatar(name, size),
        errorWidget: (_, __, ___) => _buildInitialAvatar(name, size),
      );
    }

    // Fallback: initial letter
    return _buildInitialAvatar(name, size);
  }

  Widget _buildInitialAvatar(String name, double size) {
    return Container(
      color: AppColors.surfaceLight,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: GoogleFonts.spaceGrotesk(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }
}


class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}