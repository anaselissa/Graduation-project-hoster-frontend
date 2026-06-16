import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'العربية';

  late AnimationController _headerController;
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ApiService().getUserProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
      _headerController.forward();
      _listController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _headerController.forward();
      _listController.forward();
      if (mounted) {
        _showSnack('تعذّر تحميل الملف الشخصي: $e', AppTheme.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile != null
        ? '${_profile!['first_name'] ?? ''} ${_profile!['last_name'] ?? ''}'
            .trim()
        : '';
    final userType =
        _profile?['user_type'] == 'family' ? 'عائلة 👨‍👩‍👧' : 'متطوع 🤝';
    final address = _profile?['address'] ?? 'الأردن 🇯🇴';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: _listController, curve: Curves.easeOutCubic)),
                    child: FadeTransition(
                      opacity: _listController,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                        children: [
                          const SizedBox(height: 20),
                          _buildProfileCard(name, userType, address),
                          const SizedBox(height: 28),
                          _sectionLabel('👤 الحساب الشخصي'),
                          const SizedBox(height: 10),
                          _item(
                              Icons.person_outline_rounded,
                              'تعديل الملف الشخصي',
                              AppTheme.primary,
                              _showEditProfileDialog),
                          _item(Icons.lock_outline_rounded, 'تغيير كلمة المرور',
                              AppTheme.primary, _showChangePasswordDialog),
                          _item(
                              Icons.notifications_none_rounded,
                              'إعدادات التنبيهات',
                              AppTheme.primary,
                              _showNotificationsDialog),
                          const SizedBox(height: 24),
                          _sectionLabel('🎨 التطبيق'),
                          const SizedBox(height: 10),
                          _item(
                              Icons.language_rounded,
                              'اللغة ($_selectedLanguage)',
                              AppTheme.secondary,
                              _showLanguageDialog),
                          _switchItem(Icons.dark_mode_outlined, 'الوضع الليلي',
                              AppTheme.secondary, _isDarkMode, (val) {
                            setState(() => _isDarkMode = val);
                            _showSnack(
                                val
                                    ? 'تم تفعيل الوضع الليلي 🌙'
                                    : 'تم تعطيل الوضع الليلي ☀️',
                                AppTheme.primary);
                          }),
                          _item(Icons.help_outline_rounded, 'مركز المساعدة',
                              AppTheme.secondary, _showHelpDialog),
                          const SizedBox(height: 24),
                          _sectionLabel('📋 قانوني'),
                          const SizedBox(height: 10),
                          _item(Icons.privacy_tip_outlined, 'سياسة الخصوصية',
                              AppTheme.textLight, _showPrivacyDialog),
                          _item(Icons.info_outline_rounded, 'عن رعايتكم',
                              AppTheme.textLight, _showAboutDialog),
                          const SizedBox(height: 32),
                          _logoutBtn(context),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return FadeTransition(
      opacity: _headerController,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 20,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary,
              AppTheme.secondary,
              Color(0xFF6366F1),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(Icons.settings_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text('الإعدادات',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String name, String userType, String address) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.secondary,
            Color(0xFF6366F1),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.white.withValues(alpha: 0.15), blurRadius: 12)
              ],
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? 'المستخدم' : name,
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 17,
                        letterSpacing: 0.3)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Text(userType,
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(address,
                          style: GoogleFonts.cairo(
                              color: Colors.white70, fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showEditProfileDialog,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(Icons.edit_outlined,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t,
            style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
                letterSpacing: 0.3)),
      );

  Widget _item(IconData icon, String title, Color color, VoidCallback onTap) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: color.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.12),
                          color.withValues(alpha: 0.05)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: color.withValues(alpha: 0.15), width: 1),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(title,
                        style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark)),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: color.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchItem(IconData icon, String title, Color color, bool value,
      ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
            ),
            Transform.scale(
              scale: 0.9,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppTheme.primary,
                activeTrackColor: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  Future<void> _showEditProfileDialog() async {
    final firstCtrl =
        TextEditingController(text: _profile?['first_name'] ?? '');
    final lastCtrl = TextEditingController(text: _profile?['last_name'] ?? '');
    final phoneCtrl = TextEditingController(text: _profile?['phone'] ?? '');
    final addressCtrl = TextEditingController(text: _profile?['address'] ?? '');
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          elevation: 12,
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_outline_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text('تعديل الملف الشخصي',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(firstCtrl, 'الاسم الأول', Icons.person_outline),
                const SizedBox(height: 10),
                _dialogField(lastCtrl, 'الاسم الأخير', Icons.person_outline),
                const SizedBox(height: 10),
                _dialogField(phoneCtrl, 'رقم الهاتف', Icons.phone_outlined,
                    type: TextInputType.phone),
                const SizedBox(height: 10),
                _dialogField(
                    addressCtrl, 'العنوان', Icons.location_on_outlined),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء',
                  style: GoogleFonts.cairo(color: AppTheme.textLight)),
            ),
            Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        setInner(() => saving = true);
                        try {
                          await ApiService().updateUserProfile(
                            firstName: firstCtrl.text.trim(),
                            lastName: lastCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                          );
                          if (mounted) {
                            Navigator.pop(ctx);
                            _loadProfile();
                            _showSnack('تم تحديث الملف الشخصي بنجاح ✅',
                                AppTheme.success);
                          }
                        } catch (e) {
                          setInner(() => saving = false);
                          if (mounted) {
                            _showSnack('فشل التحديث: $e', AppTheme.error);
                          }
                        }
                      },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.transparent),
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                  elevation: WidgetStateProperty.all(0),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
                ),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('حفظ',
                        style: GoogleFonts.cairo(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text('تغيير كلمة المرور',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _passwordField(
                    currentCtrl,
                    'كلمة المرور الحالية',
                    obscureCurrent,
                    () => setInner(() => obscureCurrent = !obscureCurrent)),
                const SizedBox(height: 10),
                _passwordField(newCtrl, 'كلمة المرور الجديدة', obscureNew,
                    () => setInner(() => obscureNew = !obscureNew)),
                const SizedBox(height: 10),
                _passwordField(confirmCtrl, 'تأكيد كلمة المرور الجديدة',
                    obscureNew, () => setInner(() => obscureNew = !obscureNew)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء',
                  style: GoogleFonts.cairo(color: AppTheme.textLight)),
            ),
            Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (newCtrl.text != confirmCtrl.text) {
                    _showSnack('كلمتا المرور غير متطابقتين ⚠️', AppTheme.error);
                    return;
                  }
                  Navigator.pop(ctx);
                  _showSnack('تم تغيير كلمة المرور بنجاح ✅', AppTheme.success);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.transparent),
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                  elevation: WidgetStateProperty.all(0),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
                ),
                child: Text('تغيير',
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNotificationsDialog() async {
    bool pushEnabled = _notificationsEnabled;
    bool emailEnabled = true;
    bool smsEnabled = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text('إعدادات التنبيهات',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _notifTile('📱', 'إشعارات الجهاز', 'تنبيهات فورية على هاتفك',
                  pushEnabled, (v) => setInner(() => pushEnabled = v)),
              const SizedBox(height: 8),
              _notifTile(
                  '📧',
                  'البريد الإلكتروني',
                  'استقبال التحديثات عبر الإيميل',
                  emailEnabled,
                  (v) => setInner(() => emailEnabled = v)),
              const SizedBox(height: 8),
              _notifTile('💬', 'رسائل SMS', 'تنبيهات عبر الرسائل النصية',
                  smsEnabled, (v) => setInner(() => smsEnabled = v)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء',
                  style: GoogleFonts.cairo(color: AppTheme.textLight)),
            ),
            Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _notificationsEnabled = pushEnabled);
                  Navigator.pop(ctx);
                  _showSnack('تم حفظ إعدادات التنبيهات ✅', AppTheme.success);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.transparent),
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                  elevation: WidgetStateProperty.all(0),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
                ),
                child: Text('حفظ',
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notifTile(String emoji, String title, String subtitle, bool value,
      ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.primary.withValues(alpha: 0.1), width: 1.5),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: AppTheme.textLight)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppTheme.primary,
              activeTrackColor: AppTheme.primary.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguageDialog() async {
    final languages = [
      {'flag': '🇸🇦', 'label': 'العربية'},
      {'flag': '🇬🇧', 'label': 'English'},
      {'flag': '🇫🇷', 'label': 'Français'},
    ];
    String selected = _selectedLanguage;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.secondary, AppTheme.primary]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.language_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text('اختر اللغة',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((lang) {
              final isSelected = selected == lang['label'];
              return GestureDetector(
                onTap: () => setInner(() => selected = lang['label']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: [
                            AppTheme.primary.withValues(alpha: 0.1),
                            AppTheme.secondary.withValues(alpha: 0.05)
                          ])
                        : null,
                    color: isSelected ? null : Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.4)
                          : Colors.grey[200]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(lang['flag']!, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Text(lang['label']!,
                          style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.textDark)),
                      const Spacer(),
                      if (isSelected)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                colors: [AppTheme.primary, AppTheme.secondary]),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء',
                  style: GoogleFonts.cairo(color: AppTheme.textLight)),
            ),
            Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _selectedLanguage = selected);
                  Navigator.pop(ctx);
                  _showSnack(
                      'تم تغيير اللغة إلى $selected ✅', AppTheme.success);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.transparent),
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                  elevation: WidgetStateProperty.all(0),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
                ),
                child: Text('تأكيد',
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.secondary, AppTheme.primary]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.help_outline_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text('مركز المساعدة',
              style:
                  GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _helpItem('📱', 'كيف أطلب خدمة؟',
                  'من الصفحة الرئيسية، اضغط على الخدمة المطلوبة وسيتم إنشاء طلب تلقائياً.'),
              _helpItem('🤝', 'كيف أقبل طلباً كمتطوع؟',
                  'ابحث في قائمة الفرص التطوعية واضغط "قبول الطلب".'),
              _helpItem('🗺️', 'ماذا تعني خريطة المتطوعين؟',
                  'تُظهر المتطوعين المتاحين القريبين منك على الخريطة.'),
              _helpItem(
                  '📞', 'للتواصل مع الدعم', 'راسلنا على: support@rayatukum.jo'),
            ],
          ),
        ),
        actions: [
          Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                shadowColor: WidgetStateProperty.all(Colors.transparent),
                elevation: WidgetStateProperty.all(0),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
              ),
              child: Text('حسناً',
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _helpItem(String emoji, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppTheme.primary.withValues(alpha: 0.08), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 3),
                Text(desc,
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppTheme.textLight, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.textLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.privacy_tip_outlined,
                color: AppTheme.textLight, size: 20),
          ),
          const SizedBox(width: 10),
          Text('سياسة الخصوصية',
              style:
                  GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        content: SingleChildScrollView(
          child: Text(
            'نحن في رعايتكم نلتزم بحماية خصوصيتك وبياناتك الشخصية.\n\n'
            '• نجمع فقط البيانات الضرورية لتقديم خدماتنا.\n'
            '• لا نشارك بياناتك مع أي طرف ثالث دون إذنك.\n'
            '• يمكنك طلب حذف بياناتك في أي وقت.\n'
            '• نستخدم تشفير SSL لحماية بياناتك.\n'
            '• بياناتك تُخزّن على خوادم آمنة في المملكة الأردنية الهاشمية.\n\n'
            'للمزيد: privacy@rayatukum.jo\n\nآخر تحديث: أبريل 2026',
            style: GoogleFonts.cairo(
                fontSize: 13, color: AppTheme.textLight, height: 1.7),
          ),
        ),
        actions: [
          Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                shadowColor: WidgetStateProperty.all(Colors.transparent),
                elevation: WidgetStateProperty.all(0),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
              ),
              child: Text('فهمت',
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary,
                    AppTheme.secondary,
                    Color(0xFF6366F1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: const Center(
                  child: Text('♡',
                      style: TextStyle(fontSize: 40, color: Colors.white))),
            ),
            const SizedBox(height: 16),
            Text('رعايتكم',
                style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.primary.withValues(alpha: 0.1),
                  AppTheme.secondary.withValues(alpha: 0.05)
                ]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2), width: 1),
              ),
              child: Text('الإصدار 1.0.0',
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 14),
            Text(
              'منصة تطوعية أردنية تربط المنتفعون بالمتطوعين لتقديم الخدمات الإنسانية.',
              style: GoogleFonts.cairo(
                  fontSize: 13, color: AppTheme.textLight, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.primary.withValues(alpha: 0.08),
                  AppTheme.secondary.withValues(alpha: 0.04)
                ]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.15), width: 1),
              ),
              child: Text('صُنع بـ ♡ في الأردن 🇯🇴',
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                shadowColor: WidgetStateProperty.all(Colors.transparent),
                elevation: WidgetStateProperty.all(0),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
              ),
              child: Text('حسناً',
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: GoogleFonts.cairo(fontSize: 14, color: AppTheme.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: AppTheme.textLight, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppTheme.primary.withValues(alpha: 0.2), width: 1.5),
        ),
      ),
    );
  }

  Widget _passwordField(TextEditingController ctrl, String label, bool obscure,
      VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: GoogleFonts.cairo(fontSize: 14, color: AppTheme.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: AppTheme.textLight, fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: AppTheme.primary, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: AppTheme.textLight),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppTheme.primary.withValues(alpha: 0.2), width: 1.5),
        ),
      ),
    );
  }

  Widget _logoutBtn(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                backgroundColor: Colors.white,
                title: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: Color(0xFFEF4444), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('تسجيل الخروج',
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
                content: Text('هل أنت متأكد من تسجيل الخروج؟',
                    style: GoogleFonts.cairo(
                        color: AppTheme.textLight, height: 1.5)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('إلغاء',
                        style: GoogleFonts.cairo(color: AppTheme.textLight)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Text('خروج',
                        style: GoogleFonts.cairo(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
            if (confirmed == true && mounted) {
              await ApiService().logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (r) => false);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded,
                    color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 10),
                Text('تسجيل الخروج',
                    style: GoogleFonts.cairo(
                        color: const Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.cairo(fontWeight: FontWeight.w500)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      elevation: 6,
    ));
  }
}
