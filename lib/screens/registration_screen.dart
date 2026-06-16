import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';

class ServiceTypeModel {
  final String id;
  final String name;
  final String icon;
  final List<DocumentRequirement> requirements;
  const ServiceTypeModel(
      {required this.id,
      required this.name,
      required this.icon,
      required this.requirements});
}

class DocumentRequirement {
  final String id;
  final String label;
  final String hint;
  final IconData icon;
  const DocumentRequirement(
      {required this.id,
      required this.label,
      required this.hint,
      required this.icon});
}

const List<ServiceTypeModel> kServiceTypes = [
  ServiceTypeModel(
      id: 'medicine_delivery',
      name: 'توصيل أدوية',
      icon: '💊',
      requirements: [
        DocumentRequirement(
            id: 'qualification',
            label: 'شهادة التأهل في المجال الصحي / الدوائي',
            hint: 'ارفق صورة عن شهادة التأهل أو الترخيص',
            icon: Icons.medical_services_outlined),
      ]),
  ServiceTypeModel(
      id: 'food_delivery',
      name: 'توصيل طعام',
      icon: '🍱',
      requirements: [
        DocumentRequirement(
            id: 'driving_license',
            label: 'رخصة القيادة',
            hint: 'صورة واضحة عن رخصة القيادة السارية',
            icon: Icons.directions_car_outlined),
        DocumentRequirement(
            id: 'no_criminal_record',
            label: 'وثيقة عدم المحكومية',
            hint: 'صورة عن وثيقة عدم المحكومية الرسمية',
            icon: Icons.gavel_outlined),
      ]),
  ServiceTypeModel(
      id: 'transportation',
      name: 'نقل ومواصلات',
      icon: '🚗',
      requirements: [
        DocumentRequirement(
            id: 'driving_license',
            label: 'رخصة القيادة',
            hint: 'صورة واضحة عن رخصة القيادة السارية',
            icon: Icons.directions_car_outlined),
        DocumentRequirement(
            id: 'no_criminal_record',
            label: 'وثيقة عدم المحكومية',
            hint: 'صورة عن وثيقة عدم المحكومية الرسمية',
            icon: Icons.gavel_outlined),
      ]),
  ServiceTypeModel(
      id: 'medical_care',
      name: 'رعاية طبية',
      icon: '🏥',
      requirements: [
        DocumentRequirement(
            id: 'medical_specialty',
            label: 'شهادة الاختصاص الطبي',
            hint: 'صورة عن شهادة الطب أو الاختصاص',
            icon: Icons.local_hospital_outlined),
        DocumentRequirement(
            id: 'medical_qualifications',
            label: 'المؤهلات الطبية والتدريبية',
            hint: 'شهادات ودورات تُمكّنك من العمل كراعٍ طبي',
            icon: Icons.workspace_premium_outlined),
      ]),
  ServiceTypeModel(
      id: 'home_maintenance',
      name: 'إصلاح منزلي',
      icon: '🔧',
      requirements: [
        DocumentRequirement(
            id: 'skills_proof',
            label: 'إثبات الإمكانيات والمهارات',
            hint: 'شهادة أو وثيقة تثبت كفاءتك في الإصلاح المنزلي',
            icon: Icons.handyman_outlined),
      ]),
  ServiceTypeModel(
      id: 'educational_support',
      name: 'دعم تعليمي',
      icon: '📚',
      requirements: [
        DocumentRequirement(
            id: 'edu_specialty',
            label: 'شهادة الاختصاص التعليمي',
            hint: 'صورة عن شهادة التخصص أو الإجازة التعليمية',
            icon: Icons.school_outlined),
      ]),
  ServiceTypeModel(
      id: 'shopping',
      name: 'تسوق وشراء',
      icon: '🛒',
      requirements: [
        DocumentRequirement(
            id: 'driving_license',
            label: 'رخصة القيادة',
            hint: 'صورة واضحة عن رخصة القيادة السارية',
            icon: Icons.directions_car_outlined),
      ]),
  ServiceTypeModel(
      id: 'elderly_companionship',
      name: 'مرافقة كبار السن',
      icon: '👴',
      requirements: [
        DocumentRequirement(
            id: 'care_qualifications',
            label: 'مؤهلات الرعاية والمرافقة',
            hint: 'وثائق تُثبت أهليتك للقيام بدور مرافق/ة لكبار السن',
            icon: Icons.favorite_border_outlined),
      ]),
];

class RegistrationScreen extends StatefulWidget {
  final String userType;
  const RegistrationScreen({super.key, required this.userType});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  late AnimationController _fadeController;

  
  ServiceTypeModel? _selectedService;
  final Map<String, File?> _uploadedDocs = {};
  File? _idCardFile;
  File? _noCriminalFile;

  bool get _hasMinLength => _passwordController.text.length >= 7;
  bool get _hasUpperCase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _passwordController.text.contains(RegExp(r'[^A-Za-z0-9]'));
  bool get isFamily => widget.userType == 'family';

  Color get themeColor => isFamily ? AppTheme.primary : const Color(0xFF10B981);

  Color get _buttonColor =>
      isFamily ? const Color(0xFF1D4ED8) : const Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this)
      ..forward();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
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
              const Color(0xFFEFF6FF).withValues(alpha: 0.95)
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeController,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildTypeBadge(),
                    const SizedBox(height: 24),
                    _buildField(
                        controller: _nameController,
                        hint: 'الاسم الكامل',
                        icon: Icons.person_outline_rounded,
                        index: 0,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'أدخل اسمك'
                            : null),
                    const SizedBox(height: 14),
                    _buildField(
                        controller: _emailController,
                        hint: 'البريد الإلكتروني',
                        icon: Icons.email_outlined,
                        index: 1,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'أدخل البريد الإلكتروني';
                          }
                          if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$')
                              .hasMatch(v.trim())) {
                            return 'البريد الإلكتروني غير صحيح';
                          }
                          return null;
                        }),
                    const SizedBox(height: 14),
                    _buildField(
                        controller: _phoneController,
                        hint: 'رقم الهاتف (اختياري)',
                        icon: Icons.phone_outlined,
                        index: 2,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),
                    _buildPasswordField(
                        controller: _passwordController,
                        hint: 'كلمة المرور',
                        obscure: _obscurePassword,
                        index: 3,
                        onToggle: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                          if (!_hasMinLength ||
                              !_hasUpperCase ||
                              !_hasNumber ||
                              !_hasSpecial) {
                            return 'كلمة المرور لا تستوفي المتطلبات';
                          }
                          return null;
                        }),
                    const SizedBox(height: 10),
                    _buildPasswordRules(),
                    const SizedBox(height: 14),
                    _buildPasswordField(
                        controller: _confirmPasswordController,
                        hint: 'تأكيد كلمة المرور',
                        obscure: _obscureConfirm,
                        index: 4,
                        onToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (v) => (v != _passwordController.text)
                            ? 'كلمتا المرور غير متطابقتين'
                            : null),
                    if (!isFamily) ...[
                      const SizedBox(height: 28),
                      _buildSectionDivider(
                          'نوع الخدمة التطوعية', Icons.volunteer_activism),
                      const SizedBox(height: 16),
                      _buildServiceTypeGrid(),
                      if (_selectedService != null) ...[
                        const SizedBox(height: 24),
                        _buildSectionDivider(
                            'المستندات المطلوبة لـ ${_selectedService!.name}',
                            Icons.folder_copy_outlined),
                        const SizedBox(height: 4),
                        _buildNote(
                            'كل الوثائق التالية إلزامية للموافقة على طلبك'),
                        const SizedBox(height: 14),
                        ..._selectedService!.requirements.map((req) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildDocUpload(
                                reqId: req.id,
                                label: req.label,
                                hint: req.hint,
                                icon: req.icon,
                                file: _uploadedDocs[req.id],
                                onPick: () => _pickDoc(req.id),
                                onRemove: () => setState(
                                    () => _uploadedDocs[req.id] = null),
                              ),
                            )),
                        const SizedBox(height: 24),
                        _buildSectionDivider('وثائق إلزامية لجميع المتطوعين',
                            Icons.security_outlined),
                        const SizedBox(height: 4),
                        _buildNote(
                            'هذه الوثائق مطلوبة من جميع المتطوعين بغض النظر عن نوع الخدمة'),
                        const SizedBox(height: 14),
                        _buildDocUpload(
                            reqId: 'id_card',
                            label: 'صورة الهوية الوطنية',
                            hint: 'صورة واضحة عن الوجهين الأمامي والخلفي',
                            icon: Icons.badge_outlined,
                            file: _idCardFile,
                            onPick: () => _pickCommonDoc('id_card'),
                            onRemove: () => setState(() => _idCardFile = null)),
                        const SizedBox(height: 14),
                        _buildDocUpload(
                            reqId: 'no_criminal',
                            label: 'وثيقة عدم المحكومية العامة',
                            hint: 'وثيقة رسمية صادرة عن الجهات المختصة',
                            icon: Icons.gavel_outlined,
                            file: _noCriminalFile,
                            onPick: () => _pickCommonDoc('no_criminal'),
                            onRemove: () =>
                                setState(() => _noCriminalFile = null)),
                      ],
                    ],
                    const SizedBox(height: 32),
                    _buildRegisterButton(),
                    const SizedBox(height: 20),
                    _buildLoginLink(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text('رجوع',
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [_buttonColor, _buttonColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: _buttonColor.withValues(alpha: 0.35),
                  blurRadius: 25,
                  offset: const Offset(0, 12))
            ],
          ),
          child: const Center(
              child: Text('♡',
                  style: TextStyle(fontSize: 38, color: Colors.white))),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
                  colors: [_buttonColor, _buttonColor.withValues(alpha: 0.7)])
              .createShader(bounds),
          child: Text('إنشاء حساب جديد',
              style: GoogleFonts.cairo(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ),
        const SizedBox(height: 4),
        Text('انضم إلى مجتمع رعايتكم 💙',
            style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          themeColor.withValues(alpha: 0.08),
          themeColor.withValues(alpha: 0.04)
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isFamily ? '👨\u200d👩\u200d👧' : '🤝',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(isFamily ? 'حساب المنتفعون' : 'حساب المتطوع',
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: themeColor,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: themeColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(title,
                style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark))),
      ],
    );
  }

  Widget _buildNote(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 15, color: Color(0xFFF59E0B)),
          const SizedBox(width: 7),
          Expanded(
              child: Text(text,
                  style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: const Color(0xFF92400E),
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildServiceTypeGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اختر نوع الخدمة التي ستقدمها:',
            style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.4),
          itemCount: kServiceTypes.length,
          itemBuilder: (_, i) {
            final svc = kServiceTypes[i];
            final selected = _selectedService?.id == svc.id;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedService = svc;
                _uploadedDocs.clear();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(
                          colors: [themeColor, themeColor.withValues(alpha: 0.75)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight)
                      : LinearGradient(colors: [
                          Colors.white,
                          Colors.white.withValues(alpha: 0.8)
                        ]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color:
                          selected ? themeColor : themeColor.withValues(alpha: 0.2),
                      width: selected ? 2 : 1.5),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: themeColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ]
                      : [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(svc.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(svc.name,
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color:
                                  selected ? Colors.white : AppTheme.textDark),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_selectedService == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('* يرجى اختيار نوع الخدمة',
                style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppTheme.error,
                    fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }

  Widget _buildDocUpload(
      {required String reqId,
      required String label,
      required String hint,
      required IconData icon,
      required File? file,
      required VoidCallback onPick,
      required VoidCallback onRemove}) {
    final hasFile = file != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: hasFile
            ? const Color(0xFF10B981).withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: hasFile
                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                : themeColor.withValues(alpha: 0.2),
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: (hasFile ? const Color(0xFF10B981) : themeColor)
                  .withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (hasFile ? const Color(0xFF10B981) : themeColor)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(hasFile ? Icons.check_circle_outline : icon,
                  color: hasFile ? const Color(0xFF10B981) : themeColor,
                  size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  Text(hasFile ? '✅ تم الرفع بنجاح' : hint,
                      style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: hasFile
                              ? const Color(0xFF10B981)
                              : AppTheme.textLight,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            hasFile
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    _iconBtn(
                        icon: Icons.edit_outlined,
                        color: themeColor,
                        onTap: onPick),
                    const SizedBox(width: 4),
                    _iconBtn(
                        icon: Icons.delete_outline,
                        color: AppTheme.error,
                        onTap: onRemove),
                  ])
                : ElevatedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.upload_file_outlined, size: 16),
                    label: Text('رفع',
                        style: GoogleFonts.cairo(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _fieldContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: themeColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: themeColor.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.85),
              Colors.white.withValues(alpha: 0.5)
            ]),
      ),
      child: child,
    );
  }

  Widget _buildField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      required int index,
      TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + index * 100),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: Opacity(opacity: value, child: child)),
      child: _fieldContainer(
          child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.cairo(
            fontSize: 14,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(
              color: AppTheme.textLight.withValues(alpha: 0.6), fontSize: 13),
          prefixIcon: Icon(icon, color: themeColor, size: 22),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          errorStyle: GoogleFonts.cairo(fontSize: 11),
        ),
      )),
    );
  }

  Widget _buildPasswordField(
      {required TextEditingController controller,
      required String hint,
      required bool obscure,
      required int index,
      required VoidCallback onToggle,
      String? Function(String?)? validator}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + index * 100),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: Opacity(opacity: value, child: child)),
      child: _fieldContainer(
          child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: GoogleFonts.cairo(
            fontSize: 14,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(
              color: AppTheme.textLight.withValues(alpha: 0.6), fontSize: 13),
          prefixIcon:
              Icon(Icons.lock_outline_rounded, color: themeColor, size: 22),
          suffixIcon: IconButton(
              icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textLight,
                  size: 20),
              onPressed: onToggle),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          errorStyle: GoogleFonts.cairo(fontSize: 11),
        ),
      )),
    );
  }

  Widget _buildPasswordRules() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('متطلبات كلمة المرور:',
            style: GoogleFonts.cairo(
                fontSize: 11,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _ruleItem('7 أحرف على الأقل', _hasMinLength)),
          Expanded(child: _ruleItem('حرف كبير (A-Z)', _hasUpperCase))
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: _ruleItem('رقم (0-9)', _hasNumber)),
          Expanded(child: _ruleItem(r'رمز خاص (!@#$)', _hasSpecial))
        ]),
      ]),
    );
  }

  Widget _ruleItem(String text, bool passed) {
    return Row(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 16,
        height: 16,
        decoration: BoxDecoration(
            color: passed ? const Color(0xFF10B981) : Colors.grey.shade300,
            shape: BoxShape.circle),
        child: passed
            ? const Icon(Icons.check, size: 10, color: Colors.white)
            : null,
      ),
      const SizedBox(width: 6),
      Flexible(
          child: Text(text,
              style: GoogleFonts.cairo(
                  fontSize: 11,
                  color:
                      passed ? const Color(0xFF10B981) : AppTheme.textLight))),
    ]);
  }

  
  
  
  Widget _buildRegisterButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child)),
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isLoading
                ? [
                    _buttonColor.withValues(alpha: 0.55),
                    _buttonColor.withValues(alpha: 0.45)
                  ]
                : [
                    _buttonColor,
                    _buttonColor.withValues(alpha: 0.82),
                  ],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                      color: _buttonColor.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 7))
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _handleRegister,
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('إنشاء الحساب',
                            style: GoogleFonts.cairo(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3)),
                        const SizedBox(width: 8),
                        const Text('✨', style: TextStyle(fontSize: 18)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('لديك حساب بالفعل؟',
          style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppTheme.textLight,
              fontWeight: FontWeight.w500)),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('تسجيل الدخول',
            style: GoogleFonts.cairo(
                fontSize: 13,
                color: themeColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: themeColor)),
      ),
    ]);
  }

  
  
  
  Future<void> _pickDoc(String reqId) async {
    final picker = ImagePicker();
    final result = await showModalBottomSheet<XFile?>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _pickerSheet(picker),
    );
    if (result != null) {
      setState(() => _uploadedDocs[reqId] = File(result.path));
    }
  }

  Future<void> _pickCommonDoc(String docType) async {
    final picker = ImagePicker();
    final result = await showModalBottomSheet<XFile?>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _pickerSheet(picker),
    );
    if (result != null) {
      setState(() {
        if (docType == 'id_card') _idCardFile = File(result.path);
        if (docType == 'no_criminal') _noCriminalFile = File(result.path);
      });
    }
  }

  Widget _pickerSheet(ImagePicker picker) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Text('اختر مصدر الصورة',
              style:
                  GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: _pickerOption(
                    icon: Icons.camera_alt_outlined,
                    label: 'الكاميرا',
                    color: themeColor,
                    onTap: () async {
                      final img = await picker.pickImage(
                          source: ImageSource.camera, imageQuality: 80);
                      Navigator.pop(context, img);
                    })),
            const SizedBox(width: 12),
            Expanded(
                child: _pickerOption(
                    icon: Icons.photo_library_outlined,
                    label: 'المعرض',
                    color: AppTheme.primary,
                    onTap: () async {
                      final img = await picker.pickImage(
                          source: ImageSource.gallery, imageQuality: 80);
                      Navigator.pop(context, img);
                    })),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _pickerOption(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25))),
        child: Column(children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 13, color: color, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!isFamily && _selectedService == null) {
      _showError('يرجى اختيار نوع الخدمة التطوعية');
      return;
    }
    if (!isFamily) {
      for (final req in _selectedService!.requirements) {
        if (_uploadedDocs[req.id] == null) {
          _showError('يرجى رفع: ${req.label}');
          return;
        }
      }
      if (_idCardFile == null) {
        _showError('يرجى رفع صورة الهوية الوطنية');
        return;
      }
      if (_noCriminalFile == null) {
        _showError('يرجى رفع وثيقة عدم المحكومية');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      await ApiService().register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _nameController.text.trim(),
        lastName: '',
        userType: widget.userType,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        serviceTypeId: _selectedService?.id,
      );
      if (!mounted) return;
      _showSuccess();
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      if (widget.userType == 'family') {
        Navigator.pushNamedAndRemoveUntil(context, '/family', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, '/volunteer', (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Text('✅ ', style: TextStyle(fontSize: 18)),
        Expanded(
            child: Text('تم إنشاء حسابك بنجاح! أهلاً بك 🎉',
                style: GoogleFonts.cairo(fontSize: 13)))
      ]),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Text('❌ ', style: TextStyle(fontSize: 18)),
        Expanded(child: Text(msg, style: GoogleFonts.cairo(fontSize: 13)))
      ]),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }
}
