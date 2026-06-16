import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────
//  AdminDashboard — لوحة تحكم الأدمن
// ─────────────────────────────────────────────────────────────
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic> _stats = {};
  List<dynamic> _requests = [];
  List<dynamic> _volunteers = [];
  List<dynamic> _users = [];

  int _requestsPage = 0;
  int _volunteersPage = 0;
  static const int _pageSize = 10;

  String _requestFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────
  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait(
        [_loadStats(), _loadRequests(), _loadVolunteers(), _loadUsers()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadStats() async {
    try {
      final res = await ApiService().dio.get('/admin/stats');
      if (mounted) setState(() => _stats = res.data);
    } catch (_) {}
  }

  Future<void> _loadRequests() async {
    try {
      final res = await ApiService().dio.get('/admin/requests');
      if (mounted) setState(() => _requests = res.data ?? []);
    } catch (_) {}
  }

  Future<void> _loadVolunteers() async {
    try {
      final res = await ApiService().dio.get('/admin/volunteers');
      if (mounted) setState(() => _volunteers = res.data ?? []);
    } catch (_) {}
  }

  Future<void> _loadUsers() async {
    try {
      final res = await ApiService().dio.get('/admin/users');
      if (mounted) setState(() => _users = res.data ?? []);
    } catch (_) {}
  }

  // ── Actions ─────────────────────────────────────────────────
  Future<void> _approveVolunteer(String id) async {
    try {
      await ApiService().dio.put('/admin/volunteers/$id/approve');
      _showSnack('تم قبول المتطوع ✅');
      _loadVolunteers();
      _loadStats();
    } catch (_) {
      _showSnack('حدث خطأ ❌', isError: true);
    }
  }

  Future<void> _rejectVolunteer(String id) async {
    try {
      await ApiService().dio.put('/admin/volunteers/$id/reject');
      _showSnack('تم رفض المتطوع');
      _loadVolunteers();
      _loadStats();
    } catch (_) {
      _showSnack('حدث خطأ ❌', isError: true);
    }
  }

  Future<void> _deleteUser(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تأكيد الحذف',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('هل تريد حذف "$name"؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService().dio.delete('/admin/users/$id');
      _showSnack('تم الحذف بنجاح');
      _loadUsers();
      _loadStats();
    } catch (_) {
      _showSnack('حدث خطأ ❌', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.cairo()),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Helpers ─────────────────────────────────────────────────
  List<dynamic> get _filteredRequests {
    if (_requestFilter == 'all') return _requests;
    return _requests.where((r) => r['status'] == _requestFilter).toList();
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending':
        return AppTheme.warning;
      case 'accepted':
        return AppTheme.primary;
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      default:
        return AppTheme.textLight;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'معلق';
      case 'accepted':
        return 'مقبول';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغى';
      case 'approved':
        return 'موافق عليه';
      case 'rejected':
        return 'مرفوض';
      default:
        return status ?? '';
    }
  }

  String _serviceLabel(String? key) {
    const map = {
      'medicine_delivery': 'توصيل أدوية 💊',
      'food_delivery': 'توصيل طعام 🍽️',
      'transportation': 'نقل ومواصلات 🚗',
      'medical_care': 'رعاية طبية 🏥',
      'home_maintenance': 'صيانة منزلية 🔧',
      'educational_support': 'دعم تعليمي 📚',
      'shopping': 'تسوق 🛒',
      'elderly_companionship': 'مرافقة مسنين 👴',
    };
    return map[key] ?? key ?? '—';
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            _buildHeader(),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: Column(
                  children: [
                    _buildStatsRow(),
                    _buildTabBar(),
                    Expanded(child: _buildTabBarView()),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
      )),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 20,
        right: 20,
      ),
      child: Row(
        children: [
          const Text('🛡️', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('لوحة التحكم',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )),
                Text('رعايتكم — Admin',
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 13,
                    )),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'تحديث',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await ApiService().logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  // ── Stats Row ────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final cards = [
      {
        'label': 'المستخدمين',
        'value': _stats['totalUsers'],
        'icon': '👥',
        'color': AppTheme.primary
      },
      {
        'label': 'المتطوعين',
        'value': _stats['totalVolunteers'],
        'icon': '🤝',
        'color': AppTheme.secondary
      },
      {
        'label': 'طلبات معلقة',
        'value': _stats['pendingRequests'],
        'icon': '⏳',
        'color': AppTheme.warning
      },
      {
        'label': 'وثائق معلقة',
        'value': _stats['pendingDocs'],
        'icon': '📄',
        'color': AppTheme.error
      },
      {
        'label': 'مكتملة',
        'value': _stats['completedRequests'],
        'icon': '✅',
        'color': AppTheme.success
      },
    ];

    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = cards[i];
          return Container(
            width: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (c['color'] as Color).withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                    color: (c['color'] as Color).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(c['icon'] as String, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  '${c['value'] ?? 0}',
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c['color'] as Color),
                ),
                Text(c['label'] as String,
                    style: GoogleFonts.cairo(
                        fontSize: 10, color: AppTheme.textLight)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── TabBar ───────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: AppTheme.mainGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textLight,
        labelStyle:
            GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
        tabs: const [
          Tab(text: 'الطلبات 📋'),
          Tab(text: 'المتطوعون 🤝'),
          Tab(text: 'المستخدمون 👥'),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildRequestsTab(),
        _buildVolunteersTab(),
        _buildUsersTab(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  TAB 1 — الطلبات
  // ─────────────────────────────────────────────────────────────
  Widget _buildRequestsTab() {
    final filtered = _filteredRequests;
    final paged =
        filtered.skip(_requestsPage * _pageSize).take(_pageSize).toList();

    return Column(
      children: [
        _buildRequestFilters(),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty('لا توجد طلبات')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: paged.length,
                  itemBuilder: (_, i) => _requestCard(paged[i]),
                ),
        ),
        _buildPagination(
          current: _requestsPage,
          total: (filtered.length / _pageSize).ceil(),
          onPrev: () => setState(() => _requestsPage--),
          onNext: () => setState(() => _requestsPage++),
        ),
      ],
    );
  }

  Widget _buildRequestFilters() {
    final filters = [
      ('all', 'الكل'),
      ('pending', 'معلق'),
      ('accepted', 'مقبول'),
      ('completed', 'مكتمل'),
      ('cancelled', 'ملغى'),
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: filters.map((f) {
          final active = _requestFilter == f.$1;
          return GestureDetector(
            onTap: () => setState(() {
              _requestFilter = f.$1;
              _requestsPage = 0;
            }),
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                gradient: active ? AppTheme.mainGradient : null,
                color: active ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active
                        ? Colors.transparent
                        : AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Text(f.$2,
                  style: GoogleFonts.cairo(
                    color: active ? Colors.white : AppTheme.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> r) {
    final num = r['request_number'];
    final family = r['family'] as Map<String, dynamic>?;
    final volunteer = r['volunteer'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppTheme.mainGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$num',
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    r['title'] ?? 'طلب خدمة',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                _statusBadge(r['status']),
              ],
            ),
            const SizedBox(height: 10),
            if (r['description'] != null &&
                (r['description'] as String).isNotEmpty)
              Text(r['description'],
                  style: GoogleFonts.cairo(
                      color: AppTheme.textLight, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _infoChip('🗓️ ${_formatDate(r['created_at'])}'),
                _infoChip(_serviceLabel(r['service_type_id'])),
                if (family != null)
                  _infoChip(
                      '👤 ${family['first_name']} ${family['last_name']}'),
                if (volunteer != null)
                  _infoChip(
                      '🤝 ${volunteer['first_name']} ${volunteer['last_name']}'),
                if (r['urgency'] != null)
                  _infoChip('⚡ ${r['urgency']}', color: AppTheme.warning),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  TAB 2 — المتطوعون
  // ─────────────────────────────────────────────────────────────
  Widget _buildVolunteersTab() {
    final paged =
        _volunteers.skip(_volunteersPage * _pageSize).take(_pageSize).toList();
    return Column(
      children: [
        // زر إنشاء حساب متطوع جديد
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCreateVolunteerDialog,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: Text(
                'إنشاء حساب متطوع جديد',
                style: GoogleFonts.cairo(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
        Expanded(
          child: _volunteers.isEmpty
              ? _buildEmpty('لا يوجد متطوعون')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: paged.length,
                  itemBuilder: (_, i) => _volunteerCard(paged[i]),
                ),
        ),
        _buildPagination(
          current: _volunteersPage,
          total: (_volunteers.length / _pageSize).ceil(),
          onPrev: () => setState(() => _volunteersPage--),
          onNext: () => setState(() => _volunteersPage++),
        ),
      ],
    );
  }

  // ── Dialog: إنشاء حساب متطوع ──────────────────────────────────────
  void _showCreateVolunteerDialog() {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? selectedService;
    bool obscurePassword = true;
    bool isCreating = false;

    const serviceOptions = {
      'medicine_delivery': 'توصيل دواء 💊',
      'food_delivery': 'توصيل طعام 🍱',
      'transportation': 'نقل 🚗',
      'medical_care': 'رعاية طبية 🏥',
      'home_maintenance': 'صيانة منزلية 🔧',
      'educational_support': 'دعم تعليمي 📚',
      'shopping': 'تسوق 🛒',
      'elderly_companionship': 'مرافقة كبار السن 👴',
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.volunteer_activism, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'إنشاء حساب متطوع',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الاسم الأول
                  TextField(
                    controller: firstNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'الاسم الأول *',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    style: GoogleFonts.cairo(),
                  ),
                  const SizedBox(height: 12),
                  // الاسم الأخير
                  TextField(
                    controller: lastNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'الاسم الأخير',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    style: GoogleFonts.cairo(),
                  ),
                  const SizedBox(height: 12),
                  // البريد الإلكتروني
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني *',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    style: GoogleFonts.cairo(),
                  ),
                  const SizedBox(height: 12),
                  // كلمة المرور
                  StatefulBuilder(
                    builder: (_, setPassState) => TextField(
                      controller: passwordCtrl,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور *',
                        labelStyle: GoogleFonts.cairo(),
                        hintText: 'مثال: Pass@123',
                        hintStyle: GoogleFonts.cairo(fontSize: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setPassState(
                              () => obscurePassword = !obscurePassword),
                        ),
                      ),
                      style: GoogleFonts.cairo(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // رقم الهاتف
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    style: GoogleFonts.cairo(),
                  ),
                  const SizedBox(height: 12),
                  // نوع الخدمة
                  DropdownButtonFormField<String>(
                    initialValue: selectedService,
                    decoration: InputDecoration(
                      labelText: 'نوع الخدمة التطوعية *',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.volunteer_activism_outlined),
                    ),
                    items: serviceOptions.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value, style: GoogleFonts.cairo()),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedService = val),
                    hint: Text('اختر نوع الخدمة', style: GoogleFonts.cairo()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(ctx),
              child: Text('إلغاء',
                  style: GoogleFonts.cairo(color: AppTheme.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isCreating
                  ? null
                  : () async {
                      if (firstNameCtrl.text.trim().isEmpty ||
                          emailCtrl.text.trim().isEmpty ||
                          passwordCtrl.text.isEmpty ||
                          selectedService == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('يرجى ملء جميع الحقول المطلوبة (*)',
                                style: GoogleFonts.cairo()),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                        return;
                      }
                      setDialogState(() => isCreating = true);
                      try {
                        await ApiService().createVolunteerByAdmin(
                          firstName: firstNameCtrl.text.trim(),
                          lastName: lastNameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: passwordCtrl.text,
                          phone: phoneCtrl.text.trim(),
                          serviceTypeId: selectedService!,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم إنشاء حساب المتطوع بنجاح ✅',
                                  style: GoogleFonts.cairo()),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                          _loadAll(); // تحديث القائمة
                        }
                      } catch (e) {
                        setDialogState(() => isCreating = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text(e.toString(), style: GoogleFonts.cairo()),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    },
              child: isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text('إنشاء الحساب',
                      style: GoogleFonts.cairo(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _volunteerCard(Map<String, dynamic> v) {
    final user = v['user'] as Map<String, dynamic>?;
    final docs = (v['documents'] as List?) ?? [];
    final docStatus = v['documents_status'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    (user?['first_name'] ?? '?').substring(0, 1),
                    style: GoogleFonts.cairo(
                        color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}',
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(user?['email'] ?? '',
                          style: GoogleFonts.cairo(
                              color: AppTheme.textLight, fontSize: 12)),
                    ],
                  ),
                ),
                _statusBadge(docStatus),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _infoChip(_serviceLabel(v['service_type_id'])),
                _infoChip('📞 ${user?['phone_number'] ?? '—'}'),
                _infoChip('📄 ${docs.length} وثيقة'),
                _infoChip('🗓️ ${_formatDate(user?['created_at'])}'),
              ],
            ),
            if (docs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: docs.map<Widget>((d) => _docChip(d)).toList(),
              ),
            ],
            if (docStatus == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectVolunteer(v['volunteer_id']),
                      icon: const Icon(Icons.close_rounded,
                          size: 16, color: Colors.red),
                      label: Text('رفض',
                          style: GoogleFonts.cairo(
                              color: Colors.red, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveVolunteer(v['volunteer_id']),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label:
                          Text('قبول', style: GoogleFonts.cairo(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _docChip(Map<String, dynamic> doc) {
    final status = doc['status'] as String?;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _statusColor(status).withValues(alpha: 0.3)),
      ),
      child: Text(
        doc['document_type'] ?? '—',
        style: GoogleFonts.cairo(fontSize: 10, color: _statusColor(status)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  TAB 3 — المستخدمون
  // ─────────────────────────────────────────────────────────────
  Widget _buildUsersTab() {
    return _users.isEmpty
        ? _buildEmpty('لا يوجد مستخدمون')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _users.length,
            itemBuilder: (_, i) => _userCard(_users[i]),
          );
  }

  Widget _userCard(Map<String, dynamic> u) {
    final role = u['role'] ?? u['user_type'] ?? '';
    final roleIcon = role == 'volunteer'
        ? '🤝'
        : role == 'family'
            ? '👨‍👩‍👧'
            : '👤';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: Text(roleIcon, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(
          '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(u['email'] ?? '',
                style:
                    GoogleFonts.cairo(fontSize: 12, color: AppTheme.textLight)),
            Text(
                '${u['phone_number'] ?? '—'} | ${_formatDate(u['created_at'])}',
                style:
                    GoogleFonts.cairo(fontSize: 11, color: AppTheme.textLight)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusBadge(role),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 20),
              onPressed: () =>
                  _deleteUser(u['id'], '${u['first_name']} ${u['last_name']}'),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  // ── Shared Widgets ───────────────────────────────────────────
  Widget _statusBadge(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _statusColor(status).withValues(alpha: 0.3)),
      ),
      child: Text(
        _statusLabel(status),
        style: GoogleFonts.cairo(
            color: _statusColor(status),
            fontSize: 11,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoChip(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primary).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.cairo(
              fontSize: 11, color: color ?? AppTheme.textLight)),
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(msg,
              style:
                  GoogleFonts.cairo(color: AppTheme.textLight, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildPagination({
    required int current,
    required int total,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    if (total <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: current > 0 ? onPrev : null,
            color: AppTheme.primary,
          ),
          Text('${current + 1} / $total',
              style:
                  GoogleFonts.cairo(fontSize: 13, color: AppTheme.textLight)),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: current < total - 1 ? onNext : null,
            color: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}
