import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/auth_provider.dart';
import '../../widgets/cv_widgets.dart';
import '../../widgets/profile_photo_widget.dart';
import '../../widgets/export_cv_button.dart';
import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: IndexedStack(
        index: _currentTab,
        children: const [_CVTab(), _PortfolioTab(), _ContactTab()],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(children: [
            _navItem(0, Icons.person_rounded, 'Profile'),
            _navItem(1, Icons.work_rounded, 'Portfolio'),
            _navItem(2, Icons.mail_rounded, 'Contact'),
          ]),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: active ? AppColors.gold.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 22,
                color: active ? AppColors.gold : AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.dmSans(
              fontSize: 11,
              color: active ? AppColors.gold : AppColors.textMuted,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — CV / Profile
// ══════════════════════════════════════════════════════════════════════════════
class _CVTab extends StatelessWidget {
  const _CVTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final d = auth.userData ?? {};

    final name = d['fullName'] as String? ?? auth.user?.displayName ?? 'Your Name';
    final jobTitle = d['jobTitle'] as String? ?? 'Add your job title';
    final bio = d['bio'] as String? ?? '';
    final location = d['location'] as String? ?? '';
    final skills = List<String>.from(d['skills'] ?? []);
    final experience = List<Map<String, dynamic>>.from(d['experience'] ?? []);
    final education = List<Map<String, dynamic>>.from(d['education'] ?? []);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeader(context, name, jobTitle, location, auth),
          ),
          actions: [
            const ExportCVButton(compact: true),
            const SizedBox(width: 4),
            _appBarBtn(Icons.edit_rounded, AppColors.textPrimary, () =>
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
            _appBarBtn(Icons.delete_forever_rounded, AppColors.error, () =>
                _showDeleteAccountDialog(context, auth)),
            _appBarBtn(Icons.logout_rounded, AppColors.textSecondary, () =>
                _showLogout(context, auth)),
            const SizedBox(width: 8),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // ── Bio ──────────────────────────────────────────────────────
              if (bio.isNotEmpty) ...[
                const SectionHeader(title: 'About Me'),
                const SizedBox(height: 12),
                CVCard(child: Text(bio,
                    style: GoogleFonts.dmSans(fontSize: 14,
                        color: AppColors.textSecondary, height: 1.6))),
                const SizedBox(height: 28),
              ],

              // ── Skills ────────────────────────────────────────────────────
              if (skills.isNotEmpty) ...[
                const SectionHeader(title: 'Skills'),
                const SizedBox(height: 14),
                CVCard(
                  child: Wrap(
                    spacing: 8, runSpacing: 8,
                    children: skills.map((s) => _SkillChip(skill: s)).toList(),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // ── Experience ────────────────────────────────────────────────
              if (experience.isNotEmpty) ...[
                SectionHeader(
                  title: 'Experience',
                  subtitle: '${experience.length} position${experience.length > 1 ? 's' : ''}',
                ),
                const SizedBox(height: 14),
                ...experience.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExperienceCard(data: e),
                )),
                const SizedBox(height: 28),
              ],

              // ── Education ─────────────────────────────────────────────────
              if (education.isNotEmpty) ...[
                SectionHeader(
                  title: 'Education',
                  subtitle: '${education.length} degree${education.length > 1 ? 's' : ''}',
                ),
                const SizedBox(height: 14),
                ...education.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _EducationCard(data: e),
                )),
                const SizedBox(height: 28),
              ],

              // ── Empty state ───────────────────────────────────────────────
              if (bio.isEmpty && skills.isEmpty &&
                  experience.isEmpty && education.isEmpty)
                _EmptyProfileCard(),

              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext ctx, String name, String jobTitle,
      String location, AuthProvider auth) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.profileGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 80, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const ProfilePhotoWidget(size: 76),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: GoogleFonts.spaceGrotesk(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                      ),
                      child: Text(jobTitle, style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.gold,
                          fontWeight: FontWeight.w500)),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(children: [
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(location, style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                    ],
                  ]),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBarBtn(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      onPressed: onTap,
    );
  }

  void _showDeleteAccountDialog(BuildContext ctx, AuthProvider auth) {
    final passwordController = TextEditingController();
    bool obscure = true;
    bool isDeleting = false;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
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
              child: const Icon(Icons.warning_rounded,
                  color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            Text('Delete Account', style: GoogleFonts.spaceGrotesk(
                fontSize: 17, fontWeight: FontWeight.w700,
                color: AppColors.error)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚠️  This will permanently delete:',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text(
                      '• Your profile and all personal data\n'
                          '• All experience, education & projects\n'
                          '• Your account — cannot be recovered',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textSecondary,
                          height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Enter your password to confirm:',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              // Password field
              StatefulBuilder(
                builder: (_, setObscure) => TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Your password',
                    hintStyle: GoogleFonts.dmSans(
                        color: AppColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.error.withOpacity(0.6)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscure ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18, color: AppColors.textMuted),
                      onPressed: () => setObscure(() => obscure = !obscure),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ),
            TextButton(
              onPressed: isDeleting ? null : () async {
                if (passwordController.text.trim().isEmpty) return;
                setDialogState(() => isDeleting = true);
                try {
                  await auth.deleteAccount(passwordController.text.trim());
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (ctx.mounted) {
                    Navigator.pushAndRemoveUntil(
                      ctx,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false,
                    );
                  }
                } catch (e) {
                  setDialogState(() => isDeleting = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(e.toString(),
                          style: GoogleFonts.dmSans(color: Colors.white)),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(16),
                    ));
                  }
                }
              },
              child: isDeleting
                  ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.error))
                  : Text('Delete Forever',
                  style: GoogleFonts.dmSans(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogout(BuildContext ctx, AuthProvider auth) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border)),
        title: Text('Sign Out', style: GoogleFonts.spaceGrotesk(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(
                color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
              if (ctx.mounted) {
                Navigator.pushAndRemoveUntil(ctx,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false);
              }
            },
            child: Text('Sign Out', style: GoogleFonts.dmSans(
                color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Skill Chip ───────────────────────────────────────────────────────────────
class _SkillChip extends StatelessWidget {
  final String skill;
  const _SkillChip({required this.skill});

  static const List<Color> _colors = [
    AppColors.gold, AppColors.accentBlue,
    AppColors.accentPurple, AppColors.accentGreen,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[skill.length % _colors.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(skill, style: GoogleFonts.dmSans(
          fontSize: 13, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

// ─── Experience Card ──────────────────────────────────────────────────────────
class _ExperienceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ExperienceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return CVCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.work_rounded, color: AppColors.textOnGold, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data['title'] ?? '', style: GoogleFonts.spaceGrotesk(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text('${data['company'] ?? ''}  •  ${data['period'] ?? ''}',
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.gold)),
          if ((data['description'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(data['description'], style: GoogleFonts.dmSans(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          ],
        ])),
      ]),
    );
  }
}

// ─── Education Card ───────────────────────────────────────────────────────────
class _EducationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _EducationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return CVCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: AppColors.accentPurple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accentPurple.withOpacity(0.3)),
          ),
          child: const Icon(Icons.school_rounded,
              color: AppColors.accentPurple, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data['degree'] ?? '', style: GoogleFonts.spaceGrotesk(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(data['institution'] ?? '', style: GoogleFonts.dmSans(
              fontSize: 12, color: AppColors.accentPurple)),
          Text(data['period'] ?? '', style: GoogleFonts.dmSans(
              fontSize: 12, color: AppColors.textSecondary)),
          if ((data['gpa'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('GPA: ${data['gpa']}',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.accentGreen,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ])),
      ]),
    );
  }
}

// ─── Empty Profile State ──────────────────────────────────────────────────────
class _EmptyProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CVCard(
      child: Column(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
          ),
          child: const Icon(Icons.edit_note_rounded,
              color: AppColors.gold, size: 28),
        ),
        const SizedBox(height: 14),
        Text('Complete Your Profile', style: GoogleFonts.spaceGrotesk(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text('Tap the edit button to add your bio,\nskills, experience, and education.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Edit Profile', style: GoogleFonts.dmSans(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textOnGold)),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — Portfolio (from Firestore)
// ══════════════════════════════════════════════════════════════════════════════
class _PortfolioTab extends StatelessWidget {
  const _PortfolioTab();

  static const List<Color> _cardColors = [
    AppColors.gold, AppColors.accentBlue,
    AppColors.accentPurple, AppColors.accentGreen,
  ];

  static const List<IconData> _cardIcons = [
    Icons.rocket_launch_rounded, Icons.phone_android_rounded,
    Icons.web_rounded, Icons.smart_toy_rounded,
    Icons.folder_rounded, Icons.terminal_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final d = auth.userData ?? {};
    final projects = List<Map<String, dynamic>>.from(d['projects'] ?? []);
    final skills = List<String>.from(d['skills'] ?? []);
    final experience = List<Map<String, dynamic>>.from(d['experience'] ?? []);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.primary,
          title: Text('Portfolio', style: GoogleFonts.spaceGrotesk(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // Stats row
              Row(children: [
                _StatCard(value: '${projects.length}', label: 'Projects'),
                const SizedBox(width: 10),
                _StatCard(value: '${skills.length}', label: 'Skills'),
                const SizedBox(width: 10),
                _StatCard(value: '${experience.length}', label: 'Jobs'),
              ]),
              const SizedBox(height: 28),

              // Projects
              if (projects.isNotEmpty) ...[
                SectionHeader(
                    title: 'Projects',
                    subtitle: '${projects.length} project${projects.length > 1 ? 's' : ''}'),
                const SizedBox(height: 14),
                ...projects.asMap().entries.map((e) {
                  final color = _cardColors[e.key % _cardColors.length];
                  final icon = _cardIcons[e.key % _cardIcons.length];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ProjectCard(data: e.value, color: color, icon: icon),
                  );
                }),
              ] else
                _EmptySection(
                  icon: Icons.rocket_launch_rounded,
                  title: 'No Projects Yet',
                  subtitle: 'Add your projects from the Edit Profile screen.',
                  color: AppColors.accentBlue,
                ),

              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Text(value, style: GoogleFonts.spaceGrotesk(
              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.gold)),
          Text(label, style: GoogleFonts.dmSans(
              fontSize: 11, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color color;
  final IconData icon;
  const _ProjectCard({required this.data, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final techList = List<String>.from(data['tech'] ?? []);
    final github = data['github'] as String? ?? '';
    final liveUrl = data['liveUrl'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(data['title'] ?? '', style: GoogleFonts.spaceGrotesk(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
          ),
          // Links
          if (github.isNotEmpty)
            _linkBtn(Icons.code_rounded, AppColors.textSecondary, github),
          if (liveUrl.isNotEmpty) ...[
            const SizedBox(width: 6),
            _linkBtn(Icons.open_in_new_rounded, color, liveUrl),
          ],
        ]),
        if ((data['desc'] as String?)?.isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Text(data['desc'], style: GoogleFonts.dmSans(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        ],
        if (techList.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: techList.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(t, style: GoogleFonts.dmSans(
                  fontSize: 11, color: color, fontWeight: FontWeight.w500)),
            )).toList(),
          ),
        ],
      ]),
    );
  }

  Widget _linkBtn(IconData icon, Color color, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3 — Contact (fully working)
// ══════════════════════════════════════════════════════════════════════════════
class _ContactTab extends StatelessWidget {
  const _ContactTab();

  // ─── Launch URL with error handling ────────────────────────────────────────
  Future<void> _launch(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      // mailto: and tel: need externalApplication mode
      final mode = (url.startsWith('mailto:') || url.startsWith('tel:'))
          ? LaunchMode.externalApplication
          : LaunchMode.externalApplication;
      final launched = await launchUrl(uri, mode: mode);
      if (!launched && context.mounted) {
        _showSnack(context, 'Could not open. Check the link.', AppColors.error);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Invalid link', AppColors.error);
      }
    }
  }

  // ─── Copy to clipboard ─────────────────────────────────────────────────────
  void _copy(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    _showSnack(context, '$label copied to clipboard!', AppColors.success);
  }

  void _showSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final d = auth.userData ?? {};
    final email = auth.user?.email ?? '';
    final phone = d['phone'] as String? ?? '';
    final website = d['website'] as String? ?? '';
    final linkedIn = d['linkedIn'] as String? ?? '';
    final github = d['github'] as String? ?? '';
    final name = d['fullName'] as String? ?? 'there';

    // Check if contact info is complete
    final hasContact = email.isNotEmpty || phone.isNotEmpty;
    final hasSocial = linkedIn.isNotEmpty || github.isNotEmpty;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.primary,
          title: Text('Contact Me', style: GoogleFonts.spaceGrotesk(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
          actions: [
            // Quick action: go to edit if info missing
            if (!hasContact || !hasSocial)
              TextButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                icon: const Icon(Icons.edit_rounded,
                    size: 14, color: AppColors.gold),
                label: Text('Add Info', style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.gold,
                    fontWeight: FontWeight.w600)),
              ),
            const SizedBox(width: 8),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // ── Intro Banner ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1200), Color(0xFF231A00)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.gold.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.waving_hand_rounded,
                            color: AppColors.gold, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Hi, I'm $name",
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            Text('Available for new opportunities',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppColors.accentGreen)),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Text(
                      "Feel free to reach out for collaborations,\njob opportunities, or just to say hi!",
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.6),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      // Main CTA button — actually works
                      GoldButton(
                        label: 'Send Me an Email',
                        icon: Icons.send_rounded,
                        onPressed: () => _launch(context, 'mailto:$email'),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Contact Details ────────────────────────────────────────
              if (hasContact) ...[
                const SectionHeader(
                  title: 'Contact Details',
                  subtitle: 'Tap to open • Long press to copy',
                ),
                const SizedBox(height: 14),

                if (email.isNotEmpty)
                  _ActionRow(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: email,
                    color: AppColors.gold,
                    actionIcon: Icons.send_rounded,
                    actionLabel: 'Send',
                    onTap: () => _launch(context, 'mailto:$email'),
                    onLongPress: () => _copy(context, email, 'Email'),
                  ),

                if (phone.isNotEmpty)
                  _ActionRow(
                    icon: Icons.phone_rounded,
                    label: 'Phone',
                    value: phone,
                    color: AppColors.accentGreen,
                    actionIcon: Icons.call_rounded,
                    actionLabel: 'Call',
                    onTap: () => _launch(context, 'tel:$phone'),
                    onLongPress: () => _copy(context, phone, 'Phone'),
                  ),

                if (website.isNotEmpty)
                  _ActionRow(
                    icon: Icons.language_rounded,
                    label: 'Website',
                    value: website
                        .replaceAll('https://', '')
                        .replaceAll('http://', ''),
                    color: AppColors.accentBlue,
                    actionIcon: Icons.open_in_new_rounded,
                    actionLabel: 'Open',
                    onTap: () => _launch(context, website),
                    onLongPress: () => _copy(context, website, 'Website'),
                  ),

                const SizedBox(height: 28),
              ] else ...[
                // Empty contact state with button to add
                _AddInfoCard(
                  icon: Icons.contact_phone_rounded,
                  title: 'No Contact Info Added',
                  subtitle: 'Add your phone and email so people can reach you.',
                  color: AppColors.gold,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen())),
                ),
                const SizedBox(height: 28),
              ],

              // ── Social Links ───────────────────────────────────────────
              const SectionHeader(
                title: 'Social Links',
                subtitle: 'Tap to open profile',
              ),
              const SizedBox(height: 14),

              if (linkedIn.isNotEmpty)
                _ActionRow(
                  icon: FontAwesomeIcons.linkedin,
                  label: 'LinkedIn',
                  value: linkedIn
                      .replaceAll('https://linkedin.com/in/', '')
                      .replaceAll('https://www.linkedin.com/in/', ''),
                  color: const Color(0xFF0A66C2),
                  actionIcon: Icons.open_in_new_rounded,
                  actionLabel: 'Open',
                  onTap: () => _launch(context, linkedIn),
                  onLongPress: () => _copy(context, linkedIn, 'LinkedIn'),
                )
              else
                _AddInfoCard(
                  icon: FontAwesomeIcons.linkedin,
                  title: 'LinkedIn not added',
                  subtitle: 'Add your LinkedIn profile URL',
                  color: const Color(0xFF0A66C2),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen())),
                ),

              const SizedBox(height: 10),

              if (github.isNotEmpty)
                _ActionRow(
                  icon: FontAwesomeIcons.github,
                  label: 'GitHub',
                  value: github
                      .replaceAll('https://github.com/', '')
                      .replaceAll('https://www.github.com/', ''),
                  color: AppColors.textPrimary,
                  actionIcon: Icons.open_in_new_rounded,
                  actionLabel: 'Open',
                  onTap: () => _launch(context, github),
                  onLongPress: () => _copy(context, github, 'GitHub'),
                )
              else
                _AddInfoCard(
                  icon: FontAwesomeIcons.github,
                  title: 'GitHub not added',
                  subtitle: 'Add your GitHub profile URL',
                  color: AppColors.textSecondary,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen())),
                ),

              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Action Row — tap opens, long press copies ────────────────────────────────
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label, value, actionLabel;
  final IconData actionIcon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.actionIcon,
    required this.actionLabel,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          // Icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Center(child: FaIcon(icon, size: 18, color: color)),
          ),
          const SizedBox(width: 12),

          // Text
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.dmSans(
                  fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),

          // Action button — clearly shows what happens on tap
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(actionIcon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(actionLabel, style: GoogleFonts.dmSans(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Add Info Card — shown when data is missing ───────────────────────────────
class _AddInfoCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AddInfoCard({
    required this.icon, required this.title,
    required this.subtitle, required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: color.withOpacity(0.2),
              style: BorderStyle.solid),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: Center(
              child: FaIcon(icon, size: 17,
                  color: color.withOpacity(0.4)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
              Text(subtitle, style: GoogleFonts.dmSans(
                  fontSize: 11, color: AppColors.textMuted)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: Text('+ Add', style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.gold,
                fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}

// ─── Shared Empty Section ─────────────────────────────────────────────────────
class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;

  const _EmptySection({
    required this.icon, required this.title,
    required this.subtitle, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(children: [
        Icon(icon, size: 48, color: color.withOpacity(0.3)),
        const SizedBox(height: 12),
        Text(title, style: GoogleFonts.spaceGrotesk(
            fontSize: 15, fontWeight: FontWeight.w600,
            color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                fontSize: 13, color: AppColors.textMuted, height: 1.5)),
      ]),
    );
  }
}