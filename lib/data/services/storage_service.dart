import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  // ─────────────────────────────────────────────────────────────────────────
  // 🔧 CONFIGURATION — replace with your Cloudinary values
  // cloudName   : found in Cloudinary Dashboard → Cloud Name
  // uploadPreset: Settings → Upload → Upload Presets → create Unsigned preset
  // ─────────────────────────────────────────────────────────────────────────
  static const String _cloudName   = 'dejeqw5q5';
  static const String _uploadPreset = 'cv_app_uploads';
  // ─────────────────────────────────────────────────────────────────────────

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker  _picker = ImagePicker();

  // ── Pick image from gallery or camera ─────────────────────────────────────
  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth:  800,
        maxHeight: 800,
      );
      if (picked == null) return null;
      return File(picked.path);
    } catch (e) {
      throw 'Failed to pick image: $e';
    }
  }

  // ── Upload to Cloudinary & return download URL ────────────────────────────
  Future<String> uploadProfilePhoto(
      File imageFile, {
        void Function(double progress)? onProgress,
      }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw 'User not authenticated';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    onProgress?.call(0.1);

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = _uploadPreset;
    // Note: public_id with folder slash can cause 400 on unsigned presets
    // Use a simple flat id instead
    request.fields['public_id'] = 'profile_$uid';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    onProgress?.call(0.3);

    final streamed = await request.send();
    onProgress?.call(0.8);

    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      // Show the actual Cloudinary error message
      String errorMsg = 'Upload failed (${streamed.statusCode})';
      try {
        final err = jsonDecode(body) as Map<String, dynamic>;
        errorMsg = err['error']?['message'] ?? errorMsg;
      } catch (_) {}
      throw errorMsg;
    }

    onProgress?.call(1.0);

    final data = jsonDecode(body) as Map<String, dynamic>;
    final url  = data['secure_url'] as String;

    await _auth.currentUser?.updatePhotoURL(url);

    return url;
  }

  // ── Stream-based upload for progress indicator ────────────────────────────
  Stream<double> uploadProfilePhotoWithProgress(File imageFile) async* {
    yield 0.05;

    String? url;
    String? error;

    await uploadProfilePhoto(
      imageFile,
      onProgress: (_) {}, // handled inside
    ).then((u) => url = u).catchError((e) => error = e.toString());

    if (error != null) throw error!;

    yield 1.0;
  }

  // ── Delete — Cloudinary free tier doesn't allow delete via unsigned ───────

  Future<void> deleteProfilePhoto() async {
    try {
      await _auth.currentUser?.updatePhotoURL(null);
    } catch (_) {}
  }
}