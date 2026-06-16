import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import 'chatbot_screen.dart';
import 'map_screen.dart';
import 'medical_record_screen.dart';
import 'settings_screen.dart';
import 'chatbot_bubble.dart';

class FamilyDashboard extends StatefulWidget {
  const FamilyDashboard({super.key});

  @override
  State<FamilyDashboard> createState() => _FamilyDashboardState();
}

class _FamilyDashboardState extends State<FamilyDashboard>
    with TickerProviderStateMixin {
  final _api = ApiService();
  List<dynamic> _activeRequests = [];
  List<dynamic> _serviceTypes = [];
  bool _isLoading = true;
  String _userName = '';
  int _selectedTab = 0;
  late AnimationController _fabController;
  late AnimationController _pageController;

  List<dynamic> get _visibleRequests => _activeRequests
      .where((r) => r['status'] == 'pending' || r['status'] == 'accepted')
      .toList();

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final name = await _api.getSavedUserName();
      final results = await Future.wait([
        _api.getUserServiceRequests(),
        _api.getServiceTypes(),
      ]);
      setState(() {
        _userName = name ?? 'المنتفعون';
        _activeRequests = results[0];
        _serviceTypes = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('تعذّر تحميل البيانات: $e', AppTheme.error);
    }
  }

  Future<void> _createRequest(String title, String? serviceTypeId) async {
    try {
      final details = await _showRequestDetailsDialog(title);
      if (details == null) return;

      await _api.createServiceRequest({
        'title': title,
        'description': details['description'],
        'urgency': details['urgency'],
        'service_type_id': serviceTypeId,
        'location_address': details['address'],
        'neighborhood': details['neighborhood'],
        'notes': details['notes'],
      });
      _showSnack('تم إرسال الطلب بنجاح ✅', AppTheme.success);
      _loadData();
    } catch (e) {
      _showSnack('فشل إنشاء الطلب: $e', AppTheme.error);
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Text('⚠️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text('إلغاء الطلب',
              style:
                  GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        content: Text(
          'هل أنت متأكد من إلغاء هذا الطلب؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.cairo(fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('تراجع',
                style: GoogleFonts.cairo(
                    color: AppTheme.textLight, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: Text('تأكيد الإلغاء',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.cancelServiceRequest(requestId);
      _showSnack('تم إلغاء الطلب', AppTheme.textLight);
      _loadData();
    } catch (e) {
      _showSnack('فشل الإلغاء: $e', AppTheme.error);
    }
  }

  void _showRestaurantPicker(String title, String? serviceTypeId) {
    final restaurants = [
      'Low Carb Restaurant',
      'SW Restaurant',
      '360 Degree Healthy',
      'Diet Lab',
    ];

    final customCtrl = TextEditingController();
    bool showCustomField = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Row(
                    children: [
                      const Text('🍽️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Text('اختر المطعم',
                          style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: restaurants.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 20),
                  itemBuilder: (_, i) => ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.restaurant_rounded,
                          color: Color(0xFFEF4444), size: 20),
                    ),
                    title: Text(restaurants[i],
                        style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(ctx);
                      _createRequest(
                        '$title - ${restaurants[i]}',
                        serviceTypeId,
                      );
                    },
                  ),
                ),
                const Divider(height: 1, indent: 20),
                ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3DE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Color(0xFF10B981), size: 22),
                  ),
                  title: Text('أضف مطعمك المفضل',
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981))),
                  onTap: () => setInner(() => showCustomField = true),
                ),
                if (showCustomField)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0), width: 1.5),
                            ),
                            child: TextField(
                              controller: customCtrl,
                              autofocus: true,
                              style: GoogleFonts.cairo(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'اسم المطعم...',
                                hintStyle: GoogleFonts.cairo(
                                    color: const Color(0xFFCBD5E1),
                                    fontSize: 12),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            if (customCtrl.text.trim().isEmpty) return;
                            final name = customCtrl.text.trim();
                            Navigator.pop(ctx);
                            _createRequest('$title - $name', serviceTypeId);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text('تأكيد',
                                style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showRequestDetailsDialog(String title) async {
    final descCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final neighborhoodCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String urgency = 'normal';

    final serviceIcons = {
      'توصيل أدوية': '💊',
      'توصيل طعام': '🍽️',
      'نقل ومواصلات': '🚕',
      'رعاية طبية': '🏥',
      'إصلاح منزلي': '🔧',
      'دعم تعليمي': '📚',
      'مرافقة كبار': '🤝',
      'تسوق وشراء': '🛒',
    };
    final icon = serviceIcons[title] ?? '📋';

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          clipBehavior: Clip.antiAlias,
          elevation: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(title,
                        style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 3),
                    Text('أدخل تفاصيل طلبك وسنوصّلك بمتطوع قريباً',
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dialogFieldLabel('📝 وصف الطلب'),
                      const SizedBox(height: 6),
                      _dialogTextField(
                        controller: descCtrl,
                        hint: 'اذكر تفاصيل الطلب بوضوح...',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _dialogFieldLabel('📍 العنوان'),
                                const SizedBox(height: 6),
                                _dialogTextField(
                                  controller: addrCtrl,
                                  hint: 'شارع، بناية...',
                                  icon: Icons.location_on_outlined,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _dialogFieldLabel('🏘️ الحي / المنطقة'),
                                const SizedBox(height: 6),
                                _dialogTextField(
                                  controller: neighborhoodCtrl,
                                  hint: 'الحي الشمالي...',
                                  icon: Icons.location_city_outlined,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _dialogFieldLabel('💬 ملاحظات إضافية'),
                      const SizedBox(height: 6),
                      _dialogTextField(
                        controller: notesCtrl,
                        hint: 'أي معلومات إضافية تساعد المتطوع...',
                        icon: Icons.chat_bubble_outline_rounded,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _dialogFieldLabel('⚡ درجة الاستعجال'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: _urgencyChip('✅ عادي', 'normal', urgency,
                                  (v) => setInner(() => urgency = v))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _urgencyChip('⚠️ مهم', 'high', urgency,
                                  (v) => setInner(() => urgency = v))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _urgencyChip('🔴 عاجل', 'urgent', urgency,
                                  (v) => setInner(() => urgency = v))),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Text('💙', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'سيتواصل معك المتطوع خلال وقت قصير بعد إرسال الطلب',
                                style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    color: const Color(0xFF0369A1),
                                    fontWeight: FontWeight.w600,
                                    height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('إلغاء',
                            style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.secondary],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(ctx, {
                              'description': descCtrl.text.trim().isEmpty
                                  ? 'طلب خدمة $title'
                                  : descCtrl.text.trim(),
                              'urgency': urgency,
                              'address': addrCtrl.text.trim(),
                              'neighborhood': neighborhoodCtrl.text.trim(),
                              'notes': notesCtrl.text.trim(),
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('إرسال الطلب',
                                    style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                const SizedBox(width: 6),
                                const Text('🚀',
                                    style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
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

  Widget _dialogFieldLabel(String label) {
    return Text(label,
        style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B)));
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.cairo(
            fontSize: 13,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.cairo(color: const Color(0xFFCBD5E1), fontSize: 12),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        ),
      ),
    );
  }

  Widget _urgencyChip(String label, String value, String selected,
      ValueChanged<String> onSelected) {
    final colors = {
      'normal': const Color(0xFF10B981),
      'high': const Color(0xFFF59E0B),
      'urgent': const Color(0xFFEF4444),
    };
    final isSelected = selected == value;
    final color = colors[value]!;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)])
              : LinearGradient(
                  colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.04)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: isSelected ? 2 : 1.5),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)]
              : [],
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.cairo(
                  color: isSelected ? Colors.white : color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showAllRequestsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AllRequestsSheet(requests: _activeRequests),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primary,
          strokeWidth: 3,
          child: _selectedTab == 0 ? _buildHomePage() : _buildServicesPage(),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
        ),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) =>
                  const ChatbotScreen(userType: 'family'),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          ),
          backgroundColor: AppTheme.primary,
          elevation: 8,
          highlightElevation: 12,
          child: const Icon(Icons.smart_toy_rounded,
              color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomePage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatsCard(),
              const SizedBox(height: 28),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('🎯 خدمات رعايتكم', 18),
                const SizedBox(height: 14),
                _buildQuickServicesPills(),
                const SizedBox(height: 32),
                _buildRequestsHeader(),
                const SizedBox(height: 14),
                _buildRequestsList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickServicesPills() {
    final services = [
      {
        'icon': Icons.map_outlined,
        'title': 'خريطة',
        'iconColor': const Color(0xFF0C447C),
        'bg': const Color(0xFFE6F1FB),
        'onTap': () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const JordanMapScreen(),
              transitionsBuilder: (_, a, __, c) => SlideTransition(
                  position:
                      Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                          .animate(a),
                  child: c),
            )),
      },
      {
        'icon': Icons.description_outlined,
        'title': 'السجل الطبي',
        'iconColor': const Color(0xFF791F1F),
        'bg': const Color(0xFFFCEBEB),
        'onTap': () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const MedicalRecordScreen(),
              transitionsBuilder: (_, a, __, c) => SlideTransition(
                  position:
                      Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                          .animate(a),
                  child: c),
            )),
      },
      {
        'icon': Icons.apps_rounded,
        'title': 'الخدمات',
        'iconColor': const Color(0xFF633806),
        'bg': const Color(0xFFFAEEDA),
        'onTap': () => setState(() => _selectedTab = 1),
      },
      {
        'icon': Icons.settings_outlined,
        'title': 'إعدادات',
        'iconColor': const Color(0xFF27500A),
        'bg': const Color(0xFFEAF3DE),
        'onTap': () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const SettingsScreen(),
              transitionsBuilder: (_, a, __, c) => SlideTransition(
                  position:
                      Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                          .animate(a),
                  child: c),
            )),
      },
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = services[i];
          return GestureDetector(
            onTap: s['onTap'] as VoidCallback,
            child: Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border:
                    Border.all(color: Colors.black.withValues(alpha: 0.07), width: 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: s['bg'] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(s['icon'] as IconData,
                        color: s['iconColor'] as Color, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s['title'] as String,
                    style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServicesPage() {
    final allServices = [
      {
        'icon': '💊',
        'title': 'توصيل أدوية',
        'desc': 'نوصّل أدويتك للمنزل بسرعة وأمان',
        'color': const Color(0xFFF59E0B),
        'gradient': [const Color(0xFFFFF7ED), const Color(0xFFFFECD2)],
        'border': const Color(0xFFFCD9A0),
        'key': 'medicine_delivery',
      },
      {
        'icon': '🍽️',
        'title': 'توصيل طعام',
        'desc': 'وجبات طازجة توصلك لباب البيت',
        'color': const Color(0xFFEF4444),
        'gradient': [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)],
        'border': const Color(0xFFFCA5A5),
        'key': 'food_delivery',
      },
      {
        'icon': '🚕',
        'title': 'نقل ومواصلات',
        'desc': 'توصيل لمواعيد الطبيب والتسوق وغيرها',
        'color': AppTheme.primary,
        'gradient': [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
        'border': const Color(0xFF93C5FD),
        'key': 'transportation',
      },
      {
        'icon': '🏥',
        'title': 'رعاية طبية',
        'desc': 'زيارات منزلية وإرشاد صحي من متطوعين',
        'color': const Color(0xFFEF4444),
        'gradient': [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)],
        'border': const Color(0xFFFCA5A5),
        'key': 'medical_care',
      },
      {
        'icon': '🔧',
        'title': 'إصلاح منزلي',
        'desc': 'أعطال كهربائية أو سباكة أو غيرها',
        'color': const Color(0xFF8B5CF6),
        'gradient': [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE)],
        'border': const Color(0xFFC4B5FD),
        'key': 'home_maintenance',
      },
      {
        'icon': '📚',
        'title': 'دعم تعليمي',
        'desc': 'مساعدة في الدراسة والتقنية والتواصل',
        'color': const Color(0xFF10B981),
        'gradient': [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
        'border': const Color(0xFF86EFAC),
        'key': 'educational_support',
      },
      {
        'icon': '🤝',
        'title': 'مرافقة كبار',
        'desc': 'جليس ومرافق لكبير السن برفق واهتمام',
        'color': AppTheme.secondary,
        'gradient': [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
        'border': const Color(0xFF7DD3FC),
        'key': 'elderly_companionship',
      },
      {
        'icon': '🛒',
        'title': 'تسوق وشراء',
        'desc': 'نشتري احتياجاتك ونوصّلها للمنزل',
        'color': const Color(0xFFF59E0B),
        'gradient': [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
        'border': const Color(0xFFFCD34D),
        'key': 'shopping',
      },
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🌟 جميع الخدمات',
              style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark)),
          const SizedBox(height: 6),
          Text('اختر الخدمة التي تحتاجها وسنوصلك بمتطوع',
              style:
                  GoogleFonts.cairo(fontSize: 13, color: AppTheme.textLight)),
          const SizedBox(height: 20),
          ...allServices.asMap().entries.map((entry) {
            final s = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildCurvedServiceCard(s, () {
                String? stId;
                if (_serviceTypes.isNotEmpty) {
                  final key = s['key'] as String;
                  final match = _serviceTypes.firstWhere(
                    (st) => (st['name'] as String) == key,
                    orElse: () => null,
                  );
                  stId = match?['id'];
                }

                if (s['title'] == 'توصيل طعام') {
                  _showRestaurantPicker(s['title'] as String, stId);
                } else {
                  _createRequest(s['title'] as String, stId);
                }
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCurvedServiceCard(
      Map<String, dynamic> service, VoidCallback onTap) {
    final color = service['color'] as Color;
    final gradientColors = service['gradient'] as List<Color>;
    final borderColor = service['border'] as Color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8)
                ],
              ),
              child: Center(
                child: Text(service['icon'] as String,
                    style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service['title'] as String,
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 3),
                  Text(service['desc'] as String,
                      style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: color.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                          height: 1.4)),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: color, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مرحباً بك 👋',
                style:
                    GoogleFonts.cairo(fontSize: 14, color: AppTheme.textLight)),
            Text(_userName.isEmpty ? 'رعايتكم' : _userName,
                style: GoogleFonts.cairo(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
          ],
        ),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('لا توجد إشعارات جديدة ✅', style: GoogleFonts.cairo()),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ));
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.15),
                  AppTheme.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.1), blurRadius: 12)
              ],
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: AppTheme.primary, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final pendingCount =
        _visibleRequests.where((r) => r['status'] == 'pending').length;
    final acceptedCount =
        _visibleRequests.where((r) => r['status'] == 'accepted').length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.mainGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: _activeRequests.isEmpty ? null : _showAllRequestsSheet,
            child: _statItem(
              '${_activeRequests.length}',
              'إجمالي الطلبات',
              tappable: true,
            ),
          ),
          _divider(),
          _statItem('$pendingCount', 'قيد الانتظار'),
          _divider(),
          _statItem('$acceptedCount', 'مقبولة'),
        ],
      ),
    );
  }

  Widget _statItem(String val, String lbl, {bool tappable = false}) => Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(val,
                  style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              if (tappable) ...[
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white70, size: 13),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(lbl,
              style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500)),
        ],
      );

  Widget _divider() => Container(width: 1.5, height: 44, color: Colors.white24);

  Widget _buildRequestsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('📬 الطلبات النشطة',
            style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark)),
        if (_isLoading)
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppTheme.primary)),
      ],
    );
  }

  Widget _buildRequestsList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_visibleRequests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withValues(alpha: 0.05),
              AppTheme.primary.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: AppTheme.primary.withValues(alpha: 0.1), width: 1.5),
          boxShadow: [
            BoxShadow(color: AppTheme.primary.withValues(alpha: 0.05), blurRadius: 12)
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.inbox_rounded, size: 44, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 10),
            Text('لا توجد طلبات نشطة حالياً 😌',
                style: GoogleFonts.cairo(
                    color: AppTheme.textLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => setState(() => _selectedTab = 1),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('طلب خدمة جديدة',
                  style: GoogleFonts.cairo(
                      fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                elevation: 4,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: _visibleRequests
          .asMap()
          .entries
          .map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _requestItem(e.value),
              ))
          .toList(),
    );
  }

  Widget _requestItem(Map<String, dynamic> req) {
    final statusColors = {
      'pending': const Color(0xFFBA7517),
      'accepted': const Color(0xFF639922),
      'completed': const Color(0xFF378ADD),
      'cancelled': const Color(0xFFE24B4A),
    };
    final statusLabels = {
      'pending': 'قيد الانتظار',
      'accepted': 'تم القبول',
      'completed': 'مكتمل',
      'cancelled': 'ملغي',
    };
    final statusBg = {
      'pending': const Color(0xFFFAEEDA),
      'accepted': const Color(0xFFEAF3DE),
      'completed': const Color(0xFFE6F1FB),
      'cancelled': const Color(0xFFFCEBEB),
    };
    final statusTextColor = {
      'pending': const Color(0xFF633806),
      'accepted': const Color(0xFF27500A),
      'completed': const Color(0xFF0C447C),
      'cancelled': const Color(0xFF791F1F),
    };
    final urgencyColors = {
      'normal': const Color(0xFF3B6D11),
      'high': const Color(0xFF854F0B),
      'urgent': const Color(0xFFA32D2D),
    };
    final urgencyBg = {
      'normal': const Color(0xFFEAF3DE),
      'high': const Color(0xFFFAEEDA),
      'urgent': const Color(0xFFFCEBEB),
    };
    final urgencyBorder = {
      'normal': const Color(0xFF97C459),
      'high': const Color(0xFFEF9F27),
      'urgent': const Color(0xFFF09595),
    };
    final urgencyLabel = {
      'normal': 'عادي',
      'high': 'مهم',
      'urgent': 'عاجل',
    };

    final status = req['status'] ?? 'pending';
    final urgency = req['urgency'] ?? 'normal';
    final stripeColor = statusColors[status] ?? AppTheme.primary;
    final volunteer = req['volunteer_info'];
    final isAccepted = status == 'accepted' || status == 'completed';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.07), width: 1),
          boxShadow: [
            BoxShadow(
                color: stripeColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: stripeColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(req['title'] ?? 'طلب خدمة',
                                style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg[status],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(statusLabels[status] ?? status,
                                style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: statusTextColor[status])),
                          ),
                        ],
                      ),
                      if ((req['description'] as String? ?? '').isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(req['description'],
                            style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: AppTheme.textLight,
                                height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: urgencyBg[urgency],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: urgencyBorder[urgency]!, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flash_on_rounded,
                                size: 11, color: urgencyColors[urgency]),
                            const SizedBox(width: 3),
                            Text(urgencyLabel[urgency] ?? urgency,
                                style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: urgencyColors[urgency])),
                          ],
                        ),
                      ),
                      if (isAccepted && volunteer != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF3DE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFF639922),
                                child: Text(
                                  ((volunteer['first_name'] as String? ?? ' ')
                                              .isNotEmpty
                                          ? (volunteer['first_name'] as String)
                                              .substring(0, 1)
                                          : '') +
                                      ((volunteer['last_name'] as String? ??
                                                  ' ')
                                              .isNotEmpty
                                          ? (volunteer['last_name'] as String)
                                              .substring(0, 1)
                                          : ''),
                                  style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${volunteer['first_name'] ?? ''} ${volunteer['last_name'] ?? ''}'
                                      .trim(),
                                  style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF27500A)),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined,
                                      size: 13, color: Color(0xFF3B6D11)),
                                  const SizedBox(width: 3),
                                  Text(volunteer['phone_number'] ?? 'غير متوفر',
                                      style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          color: const Color(0xFF3B6D11))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (status == 'pending') ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _cancelRequest(req['id']),
                            icon: const Icon(Icons.cancel_outlined,
                                size: 15, color: Colors.red),
                            label: Text('إلغاء الطلب',
                                style: GoogleFonts.cairo(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                              backgroundColor: AppTheme.error.withValues(alpha: 0.07),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 12,
      elevation: 10,
      color: Colors.white,
      child: SizedBox(
        height: 66,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navIcon(Icons.home_rounded, '🏠', _selectedTab == 0,
                () => setState(() => _selectedTab = 0)),
            Expanded(
              child: Center(
                child: ChatbotBubble(
                  bubbleColor: AppTheme.primary,
                  message: 'مرحباً! أنا هنا لمساعدتك',
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                              const ChatbotScreen(userType: 'family'),
                          transitionsBuilder: (_, animation, __, child) =>
                              FadeTransition(opacity: animation, child: child),
                        )),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('💬', style: TextStyle(fontSize: 22)),
                        SizedBox(height: 2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
            _navIcon(Icons.apps_rounded, '⭐', _selectedTab == 1,
                () => setState(() => _selectedTab = 1)),
            _navIcon(
                Icons.settings_outlined,
                '⚙️',
                false,
                () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const SettingsScreen(),
                      transitionsBuilder: (_, animation, __, child) =>
                          SlideTransition(
                              position: Tween<Offset>(
                                      begin: const Offset(1, 0),
                                      end: Offset.zero)
                                  .animate(animation),
                              child: child),
                    ))),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(
      IconData icon, String emoji, bool active, VoidCallback onTap) {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 2),
              if (active)
                Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: AppTheme.mainGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, double size) {
    return Text(title,
        style: GoogleFonts.cairo(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark));
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

class _AllRequestsSheet extends StatelessWidget {
  final List<dynamic> requests;
  const _AllRequestsSheet({required this.requests});

  static const _statusColors = {
    'pending': Color(0xFFBA7517),
    'accepted': Color(0xFF639922),
    'completed': Color(0xFF378ADD),
    'cancelled': Color(0xFFE24B4A),
  };
  static const _statusLabels = {
    'pending': 'قيد الانتظار',
    'accepted': 'تم القبول',
    'completed': 'مكتمل',
    'cancelled': 'ملغي',
  };
  static const _statusBg = {
    'pending': Color(0xFFFAEEDA),
    'accepted': Color(0xFFEAF3DE),
    'completed': Color(0xFFE6F1FB),
    'cancelled': Color(0xFFFCEBEB),
  };
  static const _statusTextColor = {
    'pending': Color(0xFF633806),
    'accepted': Color(0xFF27500A),
    'completed': Color(0xFF0C447C),
    'cancelled': Color(0xFF791F1F),
  };
  static const _urgencyLabels = {
    'normal': 'عادي',
    'high': 'مهم',
    'urgent': 'عاجل',
  };
  static const _urgencyColors = {
    'normal': Color(0xFF3B6D11),
    'high': Color(0xFF854F0B),
    'urgent': Color(0xFFA32D2D),
  };
  static const _urgencyBg = {
    'normal': Color(0xFFEAF3DE),
    'high': Color(0xFFFAEEDA),
    'urgent': Color(0xFFFCEBEB),
  };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('جميع الطلبات',
                          style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark)),
                      Text('${requests.length} طلب إجمالاً',
                          style: GoogleFonts.cairo(
                              fontSize: 13, color: AppTheme.textLight)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: requests.isEmpty
                  ? Center(
                      child: Text('لا توجد طلبات',
                          style: GoogleFonts.cairo(color: AppTheme.textLight)))
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: requests.length,
                      itemBuilder: (_, i) =>
                          _buildRequestCard(requests[i], i + 1),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req, int index) {
    final status = req['status'] ?? 'pending';
    final stripeColor = _statusColors[status] ?? AppTheme.primary;
    final volunteer = req['volunteer_info'];
    final isAccepted = status == 'accepted' || status == 'completed';
    final urgency = req['urgency'] ?? 'normal';
    final description = req['description'] as String? ?? '';
    final address = req['location_address'] as String? ?? '';
    final neighborhood = req['neighborhood'] as String? ?? '';
    final notes = req['notes'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.07), width: 1),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: stripeColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                  color: stripeColor,
                                  borderRadius: BorderRadius.circular(8)),
                              alignment: Alignment.center,
                              child: Text('$index',
                                  style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(req['title'] ?? 'طلب خدمة',
                                  style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppTheme.textDark)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusBg[status],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(_statusLabels[status] ?? status,
                                  style: GoogleFonts.cairo(
                                      color: _statusTextColor[status],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _infoRow(
                              Icons.description_outlined, 'الوصف', description),
                        ],
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _infoRow(
                              Icons.location_on_outlined, 'العنوان', address),
                        ],
                        if (neighborhood.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _infoRow(Icons.location_city_outlined,
                              'الحي / المنطقة', neighborhood),
                        ],
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _infoRow(Icons.chat_bubble_outline_rounded, 'ملاحظات',
                              notes),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _urgencyBg[urgency],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flash_on_rounded,
                                  size: 11, color: _urgencyColors[urgency]),
                              const SizedBox(width: 3),
                              Text(_urgencyLabels[urgency] ?? urgency,
                                  style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _urgencyColors[urgency])),
                            ],
                          ),
                        ),
                        if (isAccepted && volunteer != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF3DE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: const Color(0xFF639922),
                                  child: Text(
                                    ((volunteer['first_name'] as String? ?? ' ')
                                                .isNotEmpty
                                            ? (volunteer['first_name']
                                                    as String)
                                                .substring(0, 1)
                                            : '') +
                                        ((volunteer['last_name'] as String? ??
                                                    ' ')
                                                .isNotEmpty
                                            ? (volunteer['last_name'] as String)
                                                .substring(0, 1)
                                            : ''),
                                    style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${volunteer['first_name'] ?? ''} ${volunteer['last_name'] ?? ''}'
                                        .trim(),
                                    style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF27500A)),
                                  ),
                                ),
                                Row(children: [
                                  const Icon(Icons.phone_outlined,
                                      size: 12, color: Color(0xFF3B6D11)),
                                  const SizedBox(width: 3),
                                  Text(volunteer['phone_number'] ?? 'غير متوفر',
                                      style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          color: const Color(0xFF3B6D11))),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppTheme.textLight),
        const SizedBox(width: 5),
        Text('$label: ',
            style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textLight)),
        Expanded(
          child: Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 11, color: AppTheme.textDark, height: 1.4)),
        ),
      ],
    );
  }
}
