import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/auth_provider.dart';
import '../../widgets/cv_widgets.dart';
import '../../widgets/profile_photo_widget.dart';
import '../../widgets/export_cv_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _githubController = TextEditingController();
  final _skillController = TextEditingController();

  List<String> _skills = [];
  List<Map<String, dynamic>> _experience = [];
  List<Map<String, dynamic>> _education = [];
  List<Map<String, dynamic>> _projects = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  void _loadData() {
    final d = context.read<AuthProvider>().userData ?? {};
    _nameController.text = d['fullName'] ?? '';
    _jobTitleController.text = d['jobTitle'] ?? '';
    _bioController.text = d['bio'] ?? '';
    _phoneController.text = d['phone'] ?? '';
    _locationController.text = d['location'] ?? '';
    _websiteController.text = d['website'] ?? '';
    _linkedInController.text = d['linkedIn'] ?? '';
    _githubController.text = d['github'] ?? '';
    _skills = List<String>.from(d['skills'] ?? []);
    _experience = List<Map<String, dynamic>>.from(d['experience'] ?? []);
    _education = List<Map<String, dynamic>>.from(d['education'] ?? []);
    _projects = List<Map<String, dynamic>>.from(d['projects'] ?? []);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _jobTitleController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _linkedInController.dispose();
    _githubController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Name is required', AppColors.error);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await context.read<AuthProvider>().updateUserData({
        'fullName': _nameController.text.trim(),
        'jobTitle': _jobTitleController.text.trim(),
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'website': _websiteController.text.trim(),
        'linkedIn': _linkedInController.text.trim(),
        'github': _githubController.text.trim(),
        'skills': _skills,
        'experience': _experience,
        'education': _education,
        'projects': _projects,
      });
      if (mounted) {
        _showSnack('Profile saved!', AppColors.success);
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack('Error: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text('Edit Profile',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.gold))
                  : Text('Save All',
                  style: GoogleFonts.dmSans(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          indicatorWeight: 2.5,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.person_rounded, size: 18), text: 'Profile'),
            Tab(icon: Icon(Icons.work_rounded, size: 18), text: 'Work'),
            Tab(icon: Icon(Icons.school_rounded, size: 18), text: 'Education'),
            Tab(icon: Icon(Icons.rocket_launch_rounded, size: 18), text: 'Projects'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Profile
          _buildProfileTab(),
          // Tab 2: Experience
          _buildDynamicTab(
            items: _experience,
            title: 'Work Experience',
            subtitle: 'Jobs, internships, freelance',
            icon: Icons.work_rounded,
            iconColor: AppColors.gold,
            emptyMsg: 'No experience added yet.\nTap + to add your first job.',
            onAdd: () => _showExperienceDialog(context, null, -1),
            onEdit: (i) => _showExperienceDialog(context, _experience[i], i),
            onDelete: (i) => _confirmDelete(
              context,
              _experience[i]['title'] ?? 'this experience',
                  () => setState(() => _experience.removeAt(i)),
            ),
            buildTitle: (e) => e['title'] ?? '',
            buildSubtitle: (e) => '${e['company'] ?? ''}  •  ${e['period'] ?? ''}',
            buildDesc: (e) => e['description'] ?? '',
          ),
          // Tab 3: Education
          _buildDynamicTab(
            items: _education,
            title: 'Education',
            subtitle: 'Degrees, courses, certifications',
            icon: Icons.school_rounded,
            iconColor: AppColors.accentPurple,
            emptyMsg: 'No education added yet.\nTap + to add your degree.',
            onAdd: () => _showEducationDialog(context, null, -1),
            onEdit: (i) => _showEducationDialog(context, _education[i], i),
            onDelete: (i) => _confirmDelete(
              context,
              _education[i]['degree'] ?? 'this education',
                  () => setState(() => _education.removeAt(i)),
            ),
            buildTitle: (e) => e['degree'] ?? '',
            buildSubtitle: (e) => e['institution'] ?? '',
            buildDesc: (e) => '${e['period'] ?? ''}${(e['gpa'] as String?)?.isNotEmpty == true ? '  •  GPA: ${e['gpa']}' : ''}',
          ),
          // Tab 4: Projects
          _buildDynamicTab(
            items: _projects,
            title: 'Projects',
            subtitle: 'Your portfolio work',
            icon: Icons.rocket_launch_rounded,
            iconColor: AppColors.accentBlue,
            emptyMsg: 'No projects added yet.\nTap + to showcase your work.',
            onAdd: () => _showProjectDialog(context, null, -1),
            onEdit: (i) => _showProjectDialog(context, _projects[i], i),
            onDelete: (i) => _confirmDelete(
              context,
              _projects[i]['title'] ?? 'this project',
                  () => setState(() => _projects.removeAt(i)),
            ),
            buildTitle: (e) => e['title'] ?? '',
            buildSubtitle: (e) => (e['tech'] as List?)?.join(' • ') ?? '',
            buildDesc: (e) => e['desc'] ?? '',
          ),
        ],
      ),
    );
  }

  // ─── Confirm Delete Dialog ────────────────────────────────────────────────
  void _confirmDelete(BuildContext ctx, String itemName, VoidCallback onConfirm) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Delete?', style: GoogleFonts.spaceGrotesk(
              fontSize: 17, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
        ]),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.dmSans(
                fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                text: '"$itemName"',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              const TextSpan(text: '?\n\nThis cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(
                color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text('Delete', style: GoogleFonts.dmSans(
                color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─── Profile Tab ─────────────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Column(children: [
            const ProfilePhotoWidget(size: 90),
            const SizedBox(height: 8),
            Text('Tap photo to change',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(height: 20),
        const Center(child: ExportCVButton()),
        const SizedBox(height: 28),

        _sectionLabel('Personal Info'),
        const SizedBox(height: 12),
        CVTextField(label: 'Full Name', hint: 'John Doe',
            controller: _nameController, prefixIcon: Icons.person_outline_rounded),
        const SizedBox(height: 14),
        CVTextField(label: 'Job Title', hint: 'Flutter Developer',
            controller: _jobTitleController, prefixIcon: Icons.work_outline_rounded),
        const SizedBox(height: 14),
        CVTextField(label: 'Location', hint: 'Amman, Jordan',
            controller: _locationController, prefixIcon: Icons.location_on_outlined),
        const SizedBox(height: 14),
        CVTextField(label: 'Bio / Summary',
            hint: 'Write a short professional summary...',
            controller: _bioController, maxLines: 4),

        const SizedBox(height: 24),
        _sectionLabel('Contact'),
        const SizedBox(height: 12),
        CVTextField(label: 'Phone', hint: '+962 7X XXX XXXX',
            controller: _phoneController, prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 14),
        CVTextField(label: 'Website', hint: 'https://yourwebsite.com',
            controller: _websiteController, prefixIcon: Icons.language_rounded,
            keyboardType: TextInputType.url),

        const SizedBox(height: 24),
        _sectionLabel('Social Links'),
        const SizedBox(height: 12),
        CVTextField(label: 'LinkedIn URL',
            hint: 'https://linkedin.com/in/yourprofile',
            controller: _linkedInController, prefixIcon: Icons.link_rounded,
            keyboardType: TextInputType.url),
        const SizedBox(height: 14),
        CVTextField(label: 'GitHub URL',
            hint: 'https://github.com/yourusername',
            controller: _githubController, prefixIcon: Icons.code_rounded,
            keyboardType: TextInputType.url),

        const SizedBox(height: 24),
        _sectionLabel('Skills'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: CVTextField(label: '', hint: 'e.g. Flutter, Firebase...',
                controller: _skillController,
                textInputAction: TextInputAction.done,
                onSubmit: _addSkill),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _addSkill,
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.add_rounded, color: AppColors.textOnGold),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        if (_skills.isNotEmpty)
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _skills.map((s) => _buildSkillChip(s)).toList(),
          ),
      ]),
    );
  }

  void _addSkill() {
    final s = _skillController.text.trim();
    if (s.isEmpty || _skills.contains(s)) return;
    setState(() { _skills.add(s); _skillController.clear(); });
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(skill, style: GoogleFonts.dmSans(
            fontSize: 13, color: AppColors.gold, fontWeight: FontWeight.w500)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => setState(() => _skills.remove(skill)),
          child: const Icon(Icons.close_rounded, size: 14, color: AppColors.gold),
        ),
      ]),
    );
  }

  // ─── Dynamic List Tab Builder ─────────────────────────────────────────────────
  Widget _buildDynamicTab({
    required List<Map<String, dynamic>> items,
    required String title, required String subtitle, required String emptyMsg,
    required IconData icon, required Color iconColor,
    required VoidCallback onAdd,
    required Function(int) onEdit,
    required Function(int) onDelete,
    required String Function(Map<String, dynamic>) buildTitle,
    required String Function(Map<String, dynamic>) buildSubtitle,
    required String Function(Map<String, dynamic>) buildDesc,
  }) {
    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconColor.withOpacity(0.25)),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.spaceGrotesk(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
            Text(subtitle, style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.textSecondary)),
          ])),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add_rounded, size: 14, color: AppColors.textOnGold),
                const SizedBox(width: 4),
                Text('Add', style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.textOnGold)),
              ]),
            ),
          ),
        ]),
      ),

      // Content
      Expanded(
        child: items.isEmpty
            ? Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 52, color: AppColors.textMuted.withOpacity(0.3)),
            const SizedBox(height: 14),
            Text(emptyMsg, textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.textMuted, height: 1.6)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconColor.withOpacity(0.3)),
                ),
                child: Text('+ Add Now', style: GoogleFonts.dmSans(
                    color: iconColor, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ]),
        )
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _buildItemCard(
            title: buildTitle(items[i]),
            subtitle: buildSubtitle(items[i]),
            desc: buildDesc(items[i]),
            color: iconColor,
            icon: icon,
            onEdit: () => onEdit(i),
            onDelete: () => setState(() => onDelete(i)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildItemCard({
    required String title, required String subtitle, required String desc,
    required Color color, required IconData icon,
    required VoidCallback onEdit, required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.spaceGrotesk(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.dmSans(
                fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ],
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(desc, style: GoogleFonts.dmSans(
                fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ])),
        const SizedBox(width: 8),
        Column(children: [
          _actionBtn(Icons.edit_rounded, AppColors.textSecondary,
              AppColors.surfaceLight, onEdit),
          const SizedBox(height: 6),
          _actionBtn(Icons.delete_outline_rounded, AppColors.error,
              AppColors.error.withOpacity(0.08), onDelete),
        ]),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, Color color, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _sectionLabel(String text) => Row(children: [
    Container(width: 3, height: 16,
        decoration: BoxDecoration(gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(text, style: GoogleFonts.spaceGrotesk(
        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
  ]);

  // ─── Dialogs ──────────────────────────────────────────────────────────────────
  void _showExperienceDialog(BuildContext ctx, Map<String, dynamic>? data, int idx) {
    final t = TextEditingController(text: data?['title'] ?? '');
    final c = TextEditingController(text: data?['company'] ?? '');
    final p = TextEditingController(text: data?['period'] ?? '');
    final d = TextEditingController(text: data?['description'] ?? '');
    _showSheet(ctx, title: data == null ? 'Add Experience' : 'Edit Experience',
      fields: [
        CVTextField(label: 'Job Title', hint: 'e.g. Flutter Developer',
            controller: t, prefixIcon: Icons.work_outline_rounded),
        const SizedBox(height: 14),
        CVTextField(label: 'Company', hint: 'e.g. Tech Solutions',
            controller: c, prefixIcon: Icons.business_outlined),
        const SizedBox(height: 14),
        CVTextField(label: 'Period', hint: 'e.g. 2022 – Present',
            controller: p, prefixIcon: Icons.date_range_outlined),
        const SizedBox(height: 14),
        CVTextField(label: 'Description',
            hint: 'Describe your role and achievements...',
            controller: d, maxLines: 3),
      ],
      onSave: () {
        if (t.text.trim().isEmpty) return false;
        final item = {'title': t.text.trim(), 'company': c.text.trim(),
          'period': p.text.trim(), 'description': d.text.trim()};
        setState(() {
          if (idx == -1) _experience.add(item);
          else _experience[idx] = item;
        });
        return true;
      },
    );
  }

  void _showEducationDialog(BuildContext ctx, Map<String, dynamic>? data, int idx) {
    final deg = TextEditingController(text: data?['degree'] ?? '');
    final inst = TextEditingController(text: data?['institution'] ?? '');
    final p = TextEditingController(text: data?['period'] ?? '');
    final gpa = TextEditingController(text: data?['gpa'] ?? '');
    _showSheet(ctx, title: data == null ? 'Add Education' : 'Edit Education',
      fields: [
        CVTextField(label: 'Degree', hint: 'e.g. B.Sc. Computer Science',
            controller: deg, prefixIcon: Icons.school_outlined),
        const SizedBox(height: 14),
        CVTextField(label: 'Institution', hint: 'e.g. University of Jordan',
            controller: inst, prefixIcon: Icons.location_city_outlined),
        const SizedBox(height: 14),
        CVTextField(label: 'Period', hint: 'e.g. 2019 – 2023',
            controller: p, prefixIcon: Icons.date_range_outlined),
        const SizedBox(height: 14),
        CVTextField(label: 'GPA (optional)', hint: 'e.g. 3.7 / 4.0',
            controller: gpa, prefixIcon: Icons.grade_outlined),
      ],
      onSave: () {
        if (deg.text.trim().isEmpty) return false;
        final item = {'degree': deg.text.trim(), 'institution': inst.text.trim(),
          'period': p.text.trim(), 'gpa': gpa.text.trim()};
        setState(() {
          if (idx == -1) _education.add(item);
          else _education[idx] = item;
        });
        return true;
      },
    );
  }

  void _showProjectDialog(BuildContext ctx, Map<String, dynamic>? data, int idx) {
    final t = TextEditingController(text: data?['title'] ?? '');
    final d = TextEditingController(text: data?['desc'] ?? '');
    final tech = TextEditingController(
        text: (data?['tech'] as List?)?.join(', ') ?? '');
    final gh = TextEditingController(text: data?['github'] ?? '');
    final live = TextEditingController(text: data?['liveUrl'] ?? '');
    _showSheet(ctx, title: data == null ? 'Add Project' : 'Edit Project',
      fields: [
        CVTextField(label: 'Project Name', hint: 'e.g. Portfolio CV App',
            controller: t, prefixIcon: Icons.folder_outlined),
        const SizedBox(height: 14),
        CVTextField(label: 'Description', hint: 'What does this project do?',
            controller: d, maxLines: 3),
        const SizedBox(height: 14),
        CVTextField(label: 'Tech Stack',
            hint: 'Flutter, Firebase (comma separated)',
            controller: tech, prefixIcon: Icons.code_rounded),
        const SizedBox(height: 14),
        CVTextField(label: 'GitHub Link (optional)',
            hint: 'https://github.com/...',
            controller: gh, prefixIcon: Icons.link_rounded,
            keyboardType: TextInputType.url),
        const SizedBox(height: 14),
        CVTextField(label: 'Live URL (optional)', hint: 'https://...',
            controller: live, prefixIcon: Icons.open_in_browser_rounded,
            keyboardType: TextInputType.url),
      ],
      onSave: () {
        if (t.text.trim().isEmpty) return false;
        final techList = tech.text.split(',')
            .map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        final item = {'title': t.text.trim(), 'desc': d.text.trim(),
          'tech': techList, 'github': gh.text.trim(), 'liveUrl': live.text.trim()};
        setState(() {
          if (idx == -1) _projects.add(item);
          else _projects[idx] = item;
        });
        return true;
      },
    );
  }

  void _showSheet(BuildContext ctx, {
    required String title,
    required List<Widget> fields,
    required bool Function() onSave,
  }) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.spaceGrotesk(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            ...fields,
            const SizedBox(height: 24),
            GoldButton(
              label: title.startsWith('Add') ? '+ Add' : 'Update',
              onPressed: () {
                if (onSave()) Navigator.pop(ctx);
              },
            ),
          ]),
        ),
      ),
    );
  }
}