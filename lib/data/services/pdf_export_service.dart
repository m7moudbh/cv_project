import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfExportService {
  // Colors
  static const _navy = PdfColor.fromInt(0xFF0A0E1A);
  static const _gold = PdfColor.fromInt(0xFFFFB800);
  static const _white = PdfColors.white;
  static const _grey = PdfColor.fromInt(0xFF64748B);
  static const _lightGrey = PdfColor.fromInt(0xFFF1F5F9);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);
  static const _purple = PdfColor.fromInt(0xFF9B6DFF);
  static const _green = PdfColor.fromInt(0xFF00D68F);
  static const _blue = PdfColor.fromInt(0xFF4F8EF7);

  Future<void> exportCV({required Map<String, dynamic> userData}) async {
    final bytes = await _build(userData);
    await _share(bytes, userData['fullName'] ?? 'CV');
  }

  Future<void> previewCV({required Map<String, dynamic> userData}) async {
    final bytes = await _build(userData);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '${userData['fullName'] ?? 'CV'}_Resume.pdf',
    );
  }

  Future<Uint8List> _build(Map<String, dynamic> d) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.dMSansRegular(),
        bold: await PdfGoogleFonts.dMSansBold(),
      ),
    );

    final name = d['fullName'] ?? 'Your Name';
    final jobTitle = d['jobTitle'] ?? '';
    final bio = d['bio'] ?? '';
    final email = d['email'] ?? '';
    final phone = d['phone'] ?? '';
    final location = d['location'] ?? '';
    final website = d['website'] ?? '';
    final linkedIn = d['linkedIn'] ?? '';
    final github = d['github'] ?? '';
    final photoUrl = d['photoUrl'] as String? ?? '';
    final skills = List<String>.from(d['skills'] ?? []);
    final experience = List<Map<String, dynamic>>.from(d['experience'] ?? []);
    final education = List<Map<String, dynamic>>.from(d['education'] ?? []);
    final projects = List<Map<String, dynamic>>.from(d['projects'] ?? []);

    // Try to load profile photo from URL
    pw.MemoryImage? profileImage;
    if (photoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(photoUrl))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          profileImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {
        // Photo failed to load — fall back to initial letter
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (ctx) => [
          // Header
          _header(name, jobTitle, email, phone, location, github, profileImage),
          pw.SizedBox(height: 0),

          // Body
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                // About
                if (bio.isNotEmpty) ...[
                  _section('ABOUT ME'),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: _lightGrey,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: _border),
                    ),
                    child: pw.Text(bio, style: pw.TextStyle(
                        fontSize: 10, color: _grey, lineSpacing: 4)),
                  ),
                  pw.SizedBox(height: 22),
                ],

                // Two columns
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [

                    // LEFT (62%) — Experience + Education
                    pw.Expanded(
                      flex: 62,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [

                          if (experience.isNotEmpty) ...[
                            _section('EXPERIENCE'),
                            pw.SizedBox(height: 10),
                            ...experience.map((e) => _expBlock(
                                e['title'] ?? '', e['company'] ?? '',
                                e['period'] ?? '', e['description'] ?? '')),
                            pw.SizedBox(height: 22),
                          ],

                          if (education.isNotEmpty) ...[
                            _section('EDUCATION'),
                            pw.SizedBox(height: 10),
                            ...education.map((e) => _eduBlock(
                                e['degree'] ?? '', e['institution'] ?? '',
                                e['period'] ?? '', e['gpa'] ?? '')),
                          ],
                        ],
                      ),
                    ),

                    pw.SizedBox(width: 22),

                    // RIGHT (38%) — Skills + Projects + Links
                    pw.Expanded(
                      flex: 38,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [

                          if (skills.isNotEmpty) ...[
                            _section('SKILLS'),
                            pw.SizedBox(height: 10),
                            ..._buildSkillsGrid(skills),
                            pw.SizedBox(height: 22),
                          ],

                          if (projects.isNotEmpty) ...[
                            _section('PROJECTS'),
                            pw.SizedBox(height: 10),
                            ...projects.take(3).map((p) => _projectBlock(
                                p['title'] ?? '',
                                p['desc'] ?? '',
                                List<String>.from(p['tech'] ?? []))),
                            pw.SizedBox(height: 22),
                          ],

                          // Links
                          if (linkedIn.isNotEmpty || website.isNotEmpty) ...[
                            _section('LINKS'),
                            pw.SizedBox(height: 10),
                            if (linkedIn.isNotEmpty)
                              _linkRow('LinkedIn', _shortenUrl(linkedIn), _blue),
                            if (website.isNotEmpty)
                              _linkRow('Website', _shortenUrl(website), _gold),
                            if (github.isNotEmpty)
                              _linkRow('GitHub', _shortenUrl(github), _grey),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        footer: (ctx) => pw.Container(
          color: const PdfColor.fromInt(0xFF111827),
          padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Generated by PortfolioMe',
                  style: pw.TextStyle(fontSize: 8, color: _grey)),
              pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: _grey)),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  // Header
  pw.Widget _header(String name, String jobTitle, String email,
      String phone, String location, String github,
      pw.MemoryImage? profileImage) {
    return pw.Container(
      color: _navy,
      padding: const pw.EdgeInsets.fromLTRB(32, 28, 32, 24),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          //  Profile photo or initial letter
          pw.Container(
            width: 68,
            height: 68,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: _gold, width: 2.5),
            ),
            child: pw.ClipOval(
              child: profileImage != null
                  ? pw.Image(profileImage, fit: pw.BoxFit.cover,
                  width: 68, height: 68)
                  : pw.Container(
                color: const PdfColor.fromInt(0xFF1A1E2E),
                child: pw.Center(
                  child: pw.Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: _gold),
                  ),
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 20),

          // Name + title
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(name, style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold,
                    color: _white, letterSpacing: -0.5)),
                pw.SizedBox(height: 6),
                if (jobTitle.isNotEmpty)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: _gold,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(jobTitle, style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold,
                        color: _navy)),
                  ),
              ],
            ),
          ),

          //  Contact info
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (email.isNotEmpty)    _contactLine('✉  $email', _white),
              if (phone.isNotEmpty)    _contactLine('📞  $phone', _white),
              if (location.isNotEmpty) _contactLine('📍  $location', _white),
              if (github.isNotEmpty)
                _contactLine('⌨  ${_shortenUrl(github)}', _gold),
            ],
          ),
        ],
      ),
    );
  }

  // Section Title
  pw.Widget _section(String title) {
    return pw.Row(children: [
      pw.Container(width: 3, height: 13, color: _gold),
      pw.SizedBox(width: 7),
      pw.Text(title, style: pw.TextStyle(
          fontSize: 9, fontWeight: pw.FontWeight.bold,
          color: _navy, letterSpacing: 2)),
    ]);
  }

  //Experience Block
  pw.Widget _expBlock(String title, String company,
      String period, String desc) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 3, height: desc.isNotEmpty ? 60 : 40,
            color: _gold, margin: const pw.EdgeInsets.only(top: 3, right: 10),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold, color: _navy)),
                pw.SizedBox(height: 2),
                pw.Text('$company  ·  $period', style: pw.TextStyle(
                    fontSize: 9, color: _gold, fontWeight: pw.FontWeight.bold)),
                if (desc.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(desc, style: pw.TextStyle(
                      fontSize: 9, color: _grey, lineSpacing: 3)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  //  Education Block
  pw.Widget _eduBlock(String degree, String institution,
      String period, String gpa) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 3, height: 48,
            color: _purple, margin: const pw.EdgeInsets.only(top: 3, right: 10),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(degree, style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold, color: _navy)),
                pw.SizedBox(height: 2),
                pw.Text(institution, style: pw.TextStyle(
                    fontSize: 9, color: _purple, fontWeight: pw.FontWeight.bold)),
                pw.Text(period, style: pw.TextStyle(fontSize: 9, color: _grey)),
                if (gpa.isNotEmpty)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 3),
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFE6FFF5),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text('GPA: $gpa',
                        style: pw.TextStyle(fontSize: 8, color: _green,
                            fontWeight: pw.FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Skills Grid — 2 per row
  List<pw.Widget> _buildSkillsGrid(List<String> skills) {
    final rows = <pw.Widget>[];
    for (int i = 0; i < skills.length; i += 2) {
      final hasSecond = i + 1 < skills.length;
      rows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Row(children: [
            pw.Expanded(child: _skillTag(skills[i])),
            pw.SizedBox(width: 5),
            pw.Expanded(
              child: hasSecond
                  ? _skillTag(skills[i + 1])
                  : pw.SizedBox(),
            ),
          ]),
        ),
      );
    }
    return rows;
  }

  pw.Widget _skillTag(String skill) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFF8E7),
        border: pw.Border(
          left: pw.BorderSide(color: _gold, width: 2.5),
        ),
      ),
      child: pw.Text(
        skill,
        style: pw.TextStyle(fontSize: 9, color: _navy),
        maxLines: 1,
      ),
    );
  }

  //  Project Block
  pw.Widget _projectBlock(String title, String desc, List<String> tech) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(title, style: pw.TextStyle(
            fontSize: 10, fontWeight: pw.FontWeight.bold, color: _navy)),
        if (desc.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Text(desc, style: pw.TextStyle(
              fontSize: 9, color: _grey, lineSpacing: 2),
              maxLines: 2),
        ],
        if (tech.isNotEmpty) ...[
          pw.SizedBox(height: 5),
          pw.Text(tech.join(' · '), style: pw.TextStyle(
              fontSize: 8, color: _blue)),
        ],
      ]),
    );
  }

  //  Link Row
  pw.Widget _linkRow(String label, String url, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(children: [
        pw.Container(
            width: 4, height: 4,
            decoration: pw.BoxDecoration(
                color: color, shape: pw.BoxShape.circle)),
        pw.SizedBox(width: 6),
        pw.Text('$label: ', style: pw.TextStyle(
            fontSize: 9, fontWeight: pw.FontWeight.bold, color: _grey)),
        pw.Expanded(
          child: pw.Text(url, style: pw.TextStyle(
              fontSize: 9, color: color)),
        ),
      ]),
    );
  }

  pw.Widget _contactLine(String text, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: 9, color: color)),
    );
  }

  String _shortenUrl(String url) {
    return url
        .replaceAll('https://', '')
        .replaceAll('http://', '')
        .replaceAll('www.', '');
  }

  Future<void> _share(Uint8List bytes, String name) async {
    final dir = await getApplicationDocumentsDirectory();
    final safe = name.replaceAll(' ', '_');
    final file = File('${dir.path}/${safe}_CV.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: '$name — Resume',
    );
  }
}