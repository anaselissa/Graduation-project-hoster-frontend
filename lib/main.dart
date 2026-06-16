import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/family_dashboard.dart';
import 'screens/volunteer_dashboard.dart';
import 'screens/registration_screen.dart';
import 'screens/admin_dashboard.dart';
import 'utils/app_theme.dart';
import 'services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'رعايتكم 2026',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.futuristicTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/family': (_) => const FamilyDashboard(),
        '/volunteer': (_) => const VolunteerDashboard(),
        '/admin': (_) => const AdminDashboard(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ApiService().isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.mainGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text('♡',
                            style:
                                TextStyle(fontSize: 40, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                      ).createShader(bounds),
                      child: Text('رعايتكم',
                          style: GoogleFonts.cairo(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (snapshot.data == true) {
          return FutureBuilder<String?>(
            future: ApiService().getSavedUserType(),
            builder: (context, typeSnapshot) {
              if (typeSnapshot.data == 'family') {
                return const FamilyDashboard();
              }
              if (typeSnapshot.data == 'volunteer') {
                return const VolunteerDashboard();
              }
              return const LoginScreen();
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  String? selectedUserType;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  bool get isFamily => selectedUserType == 'family';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              const Color(0xFFFFF7ED).withValues(alpha: 0.95),
              Colors.white,
              const Color(0xFFEFF6FF).withValues(alpha: 0.95),
            ],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
          child: SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeController,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(28),
                  child: selectedUserType == null
                      ? _buildUserTypeSelection()
                      : _buildLoginForm(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.06)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.cairo(
                fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeSelection() {
    return Column(
      children: [
        _buildLogo(),
        const SizedBox(height: 40),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
          ).createShader(bounds),
          child: Text('اختر نوع حسابك',
              style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
        const SizedBox(height: 8),
        Text('مرحباً بك في رعايتكم 2026',
            style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 32),
        _buildAnimatedTypeCard(
          'أنا من المنتفعون 👨‍👩‍👧',
          'أطلب خدمات لعائلتي في الأردن',
          Icons.family_restroom_rounded,
          AppTheme.primary,
          const Color(0xFFEFF6FF),
          0,
          () => setState(() {
            selectedUserType = 'family';
            _emailController.clear();
            _passwordController.clear();
          }),
        ),
        const SizedBox(height: 14),
        _buildAnimatedTypeCard(
          'أنا متطوع 🤝',
          'أرغب في تقديم المساعدة الإنسانية',
          Icons.volunteer_activism_rounded,
          const Color(0xFF10B981),
          const Color(0xFFF0FDF4),
          1,
          () => setState(() {
            selectedUserType = 'volunteer';
            _emailController.clear();
            _passwordController.clear();
          }),
        ),
        const SizedBox(height: 28),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('أو',
                        style: GoogleFonts.cairo(
                            fontSize: 12, color: AppTheme.textLight)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 16),
              Text('ليس لديك حساب؟ سجّل كالمنتفعون',
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              _buildRegisterButton(
                label: 'سجّل كالمنتفعون 👨‍👩‍👧',
                color: AppTheme.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const RegistrationScreen(userType: 'family'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Text('رعايتكم · الأردن 🇯🇴',
                  style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.elasticOut),
      ),
      child: Column(children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primary, AppTheme.secondary],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 3,
              ),
              BoxShadow(
                color: AppTheme.secondary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Text('♡',
                style: TextStyle(
                    fontSize: 50, color: Colors.white, letterSpacing: 2)),
          ),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text('رعايتكم',
              style: GoogleFonts.cairo(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5)),
        ),
        const SizedBox(height: 6),
        Text('من القلب إلى الخدمة 💙',
            style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFF59E0B),
                Color(0xFFFBBF24),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                blurRadius: 10,
              )
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildAnimatedTypeCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Color bgColor,
    int index,
    VoidCallback onTap,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: _buildTypeCard(title, subtitle, icon, color, bgColor, onTap),
    );
  }

  Widget _buildTypeCard(String title, String subtitle, IconData icon,
      Color color, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        onEnter: (_) => _scaleController.forward(),
        onExit: (_) => _scaleController.reverse(),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 25,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.8),
                Colors.white.withValues(alpha: 0.4),
              ],
            ),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bgColor, bgColor.withValues(alpha: 0.6)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 15,
                  )
                ],
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppTheme.textLight,
                          height: 1.4)),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                  )
                ],
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 20),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    final isFamily = selectedUserType == 'family';
    final color = isFamily ? AppTheme.primary : const Color(0xFF10B981);

    return Column(children: [
      Align(
        alignment: Alignment.centerRight,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
          ),
          child: TextButton.icon(
            onPressed: () => setState(() => selectedUserType = null),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text('تغيير نوع الحساب',
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ),
      const SizedBox(height: 12),
      _buildLogo(),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.04)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isFamily ? '👨‍👩‍👧' : '🤝',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isFamily ? 'حساب المنتفعون' : 'حساب المتطوع',
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 32),
      _buildAnimatedTextField(
        'البريد الإلكتروني 📧',
        Icons.email_outlined,
        _emailController,
        color,
        0,
      ),
      const SizedBox(height: 16),
      _buildAnimatedTextField(
        'كلمة المرور 🔐',
        Icons.lock_outline_rounded,
        _passwordController,
        color,
        1,
        isPassword: true,
      ),
      const SizedBox(height: 32),
      _buildAnimatedLoginButton(color),
      const SizedBox(height: 16),
      TextButton(
        onPressed: _showForgotPasswordDialog,
        child: Text('نسيت كلمة المرور؟ 🆘',
            style: GoogleFonts.cairo(
                color: AppTheme.textLight,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2)),
      ),
      if (isFamily) ...[
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ليس لديك حساب؟',
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w500)),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RegistrationScreen(userType: 'family'),
                ),
              ),
              child: Text('إنشاء حساب جديد ✨',
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.primary)),
            ),
          ],
        ),
      ],
      if (!isFamily) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ℹ️', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'حسابات المتطوعين تُنشأ من قِبَل الإدارة فقط',
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: const Color(0xFF059669),
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () async {
            final url = Uri.parse(
              'https://docs.google.com/forms/d/1bjAyem_mob1ORBEl3GBbaYebqaSnVKK33x35lZ3g17w/viewform',
            );
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withValues(alpha: 0.12),
                  const Color(0xFF10B981).withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                'سجّل كمتطوع 🤝',
                style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981)),
              ),
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _buildAnimatedTextField(
    String hint,
    IconData icon,
    TextEditingController controller,
    Color color,
    int index, {
    bool isPassword = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: _buildTextField(hint, icon, controller, color,
          isPassword: isPassword),
    );
  }

  Widget _buildTextField(
    String hint,
    IconData icon,
    TextEditingController controller,
    Color color, {
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.8),
            Colors.white.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        keyboardType: isPassword
            ? TextInputType.visiblePassword
            : TextInputType.emailAddress,
        textInputAction:
            isPassword ? TextInputAction.done : TextInputAction.next,
        onSubmitted: isPassword ? (_) => _handleLogin() : null,
        style: GoogleFonts.cairo(
            fontSize: 14,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(
              color: AppTheme.textLight.withValues(alpha: 0.6), fontSize: 13),
          prefixIcon: Icon(icon, color: color, size: 22),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.textLight,
                      size: 20),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword))
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildAnimatedLoginButton(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: GestureDetector(
        onTap: _isLoading ? null : _handleLogin,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isLoading
                  ? [color.withValues(alpha: 0.5), color.withValues(alpha: 0.4)]
                  : [color, color.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: _isLoading
              ? const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('دخول الآن',
                        style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5)),
                    const SizedBox(width: 8),
                    const Text('🚀', style: TextStyle(fontSize: 18)),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('يرجى إدخال البريد الإلكتروني وكلمة المرور ⚠️');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final debugPrefs = await SharedPreferences.getInstance();
      print('=== DEBUG ===');
      print('user_role: ${debugPrefs.getString('user_role')}');
      print('user_type: ${debugPrefs.getString('user_type')}');
      print('=============');
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role') ?? '';
      final userType = prefs.getString('user_type') ?? '';

      if (role == 'admin') {
        Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
      } else if (userType == 'family') {
        Navigator.pushNamedAndRemoveUntil(context, '/family', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, '/volunteer', (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('فشل الدخول: ${e.toString()} ❌');
    }
  }

  void _showForgotPasswordDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          title: Row(
            children: [
              const Text('🔐', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text('استعادة كلمة المرور',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 0.3)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين',
                  style: GoogleFonts.cairo(
                      fontSize: 13, color: AppTheme.textLight, height: 1.5)),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.emailAddress,
                  style:
                      GoogleFonts.cairo(fontSize: 14, color: AppTheme.textDark),
                  decoration: InputDecoration(
                    hintText: 'البريد الإلكتروني',
                    hintStyle: GoogleFonts.cairo(
                        color: AppTheme.textLight.withValues(alpha: 0.5)),
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: AppTheme.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء',
                  style: GoogleFonts.cairo(
                      color: AppTheme.textLight, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Row(
                    children: [
                      const Text('✅ ', style: TextStyle(fontSize: 18)),
                      Expanded(
                        child: Text('تم إرسال رابط الاستعادة إلى ${ctrl.text}',
                            style: GoogleFonts.cairo(fontSize: 13)),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.all(16),
                ));
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text('إرسال',
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Text('❌ ', style: TextStyle(fontSize: 18)),
          Expanded(child: Text(msg, style: GoogleFonts.cairo(fontSize: 13))),
        ],
      ),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }
}
