import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import 'chatbot_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';
import 'chatbot_bubble.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard>
    with TickerProviderStateMixin {
  static const _green = Color(0xFF10B981);
  static const _greenDark = Color(0xFF059669);

  final _api = ApiService();
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String _userName = '';
  String _myUserId = '';
  int _selectedTab = 0;
  late AnimationController _fabController;
  late AnimationController _pageController;

  List<dynamic> get _visibleRequests => _requests
      .where((r) => r['status'] == 'pending' || r['status'] == 'accepted')
      .toList();

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this)
      ..forward();
    _pageController = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
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
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final req = await _api.getVolunteerRequests();
      setState(() {
        _userName = name ?? 'المتطوع';
        _myUserId = userId;
        _requests = req;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('تعذّر تحميل البيانات: $e', AppTheme.error);
    }
  }

  Future<void> _acceptRequest(Map<String, dynamic> req) async {
    try {
      await _api.acceptServiceRequest(req['id'].toString());
      _showSnack('تم قبول الطلب بنجاح ✅', _green);
      _loadData();
    } catch (e) {
      _showSnack('فشل قبول الطلب: $e', AppTheme.error);
    }
  }

  Future<void> _completeRequest(Map<String, dynamic> req) async {
    try {
      await _api.completeServiceRequest(req['id'].toString());
      _showSnack('تم إكمال الطلب بنجاح 🎉', AppTheme.primary);
      _loadData();
    } catch (e) {
      _showSnack('فشل إكمال الطلب: $e', AppTheme.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: _green,
          strokeWidth: 3,
          child: _selectedTab == 0 ? _buildHomePage() : _buildMapPage(),
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
                    const ChatbotScreen(userType: 'volunteer'),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
              )),
          backgroundColor: _green,
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
    final pending =
        _visibleRequests.where((e) => e['status'] == 'pending').toList();
    final accepted =
        _visibleRequests.where((e) => e['status'] == 'accepted').toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatsCard(pending.length, accepted.length),
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
                _buildSectionTitle('🎯 الإجراءات السريعة', 18),
                const SizedBox(height: 14),
                _buildQuickActionsPills(),
                const SizedBox(height: 32),
                _buildRequestsHeader('📬 الطلبات المتاحة'),
                const SizedBox(height: 14),
                _buildRequestsList(pending, false),
                if (accepted.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _buildRequestsHeader('✅ الطلبات المقبولة'),
                  const SizedBox(height: 14),
                  _buildRequestsList(accepted, true),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPage() => const JordanMapScreen();

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
            Text(_userName.isEmpty ? 'المتطوع' : _userName,
                style: GoogleFonts.cairo(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
          ],
        ),
        GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('لا توجد إشعارات جديدة ✅', style: GoogleFonts.cairo()),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          )),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [_green.withOpacity(0.15), _green.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _green.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(color: _green.withOpacity(0.1), blurRadius: 12)
              ],
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: _green, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(int pending, int accepted) {
    // ✅ إجمالي الطلبات التي قبلها أو أكملها هذا المتطوع تحديداً
    final myTotal = _requests
        .where((r) =>
            r['volunteer_id']?.toString() == _myUserId && _myUserId.isNotEmpty)
        .length;

    return GestureDetector(
      onTap: _requests.isEmpty ? null : _showAllRequestsSheet,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_green, _greenDark],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: _green.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('$myTotal', 'طلباتي',
                    tappable: true),
                _divider(),
                _statItem('$pending', 'قيد الانتظار'),
                _divider(),
                _statItem('$accepted', 'مقبولة'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70, size: 18),
                const SizedBox(width: 4),
                Text('اضغط لعرض كل الطلبات',
                    style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAllRequestsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AllRequestsSheet(
        requests: _requests,
        onAccept: _acceptRequest,
        onComplete: _completeRequest,
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

  Widget _buildQuickActionsPills() {
    final actions = [
      {
        'icon': Icons.map_outlined,
        'title': 'خريطة',
        'iconColor': const Color(0xFF0C5F3A),
        'bg': const Color(0xFFD1FAE5),
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
        'icon': Icons.chat_bubble_outline_rounded,
        'title': 'المساعد',
        'iconColor': const Color(0xFF0C447C),
        'bg': const Color(0xFFE6F1FB),
        'onTap': () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) =>
                  const ChatbotScreen(userType: 'volunteer'),
              transitionsBuilder: (_, a, __, c) =>
                  FadeTransition(opacity: a, child: c),
            )),
      },
      {
        'icon': Icons.refresh_rounded,
        'title': 'تحديث',
        'iconColor': const Color(0xFF854F0B),
        'bg': const Color(0xFFFAEEDA),
        'onTap': () => _loadData(),
      },
      {
        'icon': Icons.settings_outlined,
        'title': 'إعدادات',
        'iconColor': const Color(0xFF4C1D95),
        'bg': const Color(0xFFEDE9FE),
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
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = actions[i];
          return GestureDetector(
            onTap: s['onTap'] as VoidCallback,
            child: Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border:
                    Border.all(color: Colors.black.withOpacity(0.07), width: 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
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

  Widget _buildRequestsHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark)),
        if (_isLoading)
          SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(strokeWidth: 2.5, color: _green)),
      ],
    );
  }

  Widget _buildRequestsList(List<dynamic> requests, bool isAccepted) {
    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: _green));
    if (requests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [_green.withOpacity(0.05), _green.withOpacity(0.02)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _green.withOpacity(0.1), width: 1.5),
          boxShadow: [
            BoxShadow(color: _green.withOpacity(0.05), blurRadius: 12)
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.inbox_rounded, size: 44, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 10),
            Text('لا توجد طلبات متاحة حالياً 😌',
                style: GoogleFonts.cairo(
                    color: AppTheme.textLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return Column(
      children: requests
          .asMap()
          .entries
          .map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _requestItem(e.value, isAccepted),
              ))
          .toList(),
    );
  }

  Widget _requestItem(Map<String, dynamic> req, bool isAccepted) {
    final stripeColor = isAccepted ? _green : const Color(0xFFF59E0B);
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
    final urgency = req['urgency'] ?? 'normal';
    final family = req['users'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.07), width: 1),
          boxShadow: [
            BoxShadow(
                color: stripeColor.withOpacity(0.08),
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
                              color: isAccepted
                                  ? const Color(0xFFEAF3DE)
                                  : const Color(0xFFFAEEDA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                                isAccepted ? 'تم القبول' : 'قيد الانتظار',
                                style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isAccepted
                                        ? const Color(0xFF27500A)
                                        : const Color(0xFF633806))),
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
                      if (req['location_address'] != null &&
                          req['location_address'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.location_on_outlined,
                              size: 13, color: AppTheme.textLight),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(req['location_address'],
                                  style: GoogleFonts.cairo(
                                      fontSize: 11, color: AppTheme.textLight),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                        ]),
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
                      if (isAccepted && family != null) ...[
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
                                backgroundColor: _green,
                                child: Text(
                                  ((family['first_name'] as String? ?? ' ')
                                              .isNotEmpty
                                          ? (family['first_name'] as String)
                                              .substring(0, 1)
                                          : '') +
                                      ((family['last_name'] as String? ?? ' ')
                                              .isNotEmpty
                                          ? (family['last_name'] as String)
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
                                  '${family['first_name'] ?? ''} ${family['last_name'] ?? ''}'
                                      .trim(),
                                  style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF27500A)),
                                ),
                              ),
                              Row(children: [
                                const Icon(Icons.phone_outlined,
                                    size: 13, color: Color(0xFF3B6D11)),
                                const SizedBox(width: 3),
                                Text(family['phone_number'] ?? 'غير متوفر',
                                    style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        color: const Color(0xFF3B6D11))),
                              ]),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // ✅ زر الإكمال يظهر فقط للمتطوع اللي قبل الطلب
                      Builder(builder: (_) {
                        final isMyRequest =
                            req['volunteer_id']?.toString() == _myUserId &&
                                _myUserId.isNotEmpty;
                        final canComplete = isAccepted && isMyRequest;

                        return Row(
                          children: [
                            if (!isAccepted)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _acceptRequest(req),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                          colors: [_green, _greenDark]),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                            Icons.volunteer_activism_rounded,
                                            size: 16,
                                            color: Colors.white),
                                        const SizedBox(width: 6),
                                        Text('قبول الطلب ✅',
                                            style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (!isAccepted) const SizedBox(width: 8),
                            if (canComplete)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _completeRequest(req),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF2563EB)
                                      ]),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 16,
                                            color: Colors.white),
                                        const SizedBox(width: 6),
                                        Text('إكمال الطلب 🎉',
                                            style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            // طلب مقبول من متطوع آخر - اعرض بادج توضيحي
                            if (isAccepted && !isMyRequest && !canComplete)
                              Expanded(
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Colors.grey.shade300, width: 1),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.lock_outline_rounded,
                                          size: 15,
                                          color: Colors.grey.shade500),
                                      const SizedBox(width: 6),
                                      Text('مقبول من متطوع آخر',
                                          style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                              color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
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
                  bubbleColor: const Color(0xFF10B981),
                  message: 'مرحباً! أنا هنا لمساعدتك',
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                              const ChatbotScreen(userType: 'volunteer'),
                          transitionsBuilder: (_, animation, __, child) =>
                              FadeTransition(opacity: animation, child: child),
                        )),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 22)),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
            _navIcon(Icons.map_outlined, '🗺️', _selectedTab == 1,
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
                    gradient:
                        const LinearGradient(colors: [_green, _greenDark]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
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
  final Future<void> Function(Map<String, dynamic>) onAccept;
  final Future<void> Function(Map<String, dynamic>) onComplete;

  const _AllRequestsSheet({
    required this.requests,
    required this.onAccept,
    required this.onComplete,
  });

  static const _green = Color(0xFF10B981);
  static const _greenDark = Color(0xFF059669);

  static const _statusColors = {
    'pending': Color(0xFFBA7517),
    'accepted': _green,
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
                      itemBuilder: (ctx, i) =>
                          _buildRequestCard(ctx, requests[i], i + 1),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(
      BuildContext context, Map<String, dynamic> req, int index) {
    final status = req['status'] ?? 'pending';
    final stripeColor = _statusColors[status] ?? _green;
    final urgency = req['urgency'] ?? 'normal';
    final family = req['users'];
    final isAccepted = status == 'accepted' || status == 'completed';
    final description = req['description'] as String? ?? '';
    final address = req['location_address'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.07), width: 1),
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.description_outlined,
                                  size: 13, color: AppTheme.textLight),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(description,
                                    style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        color: AppTheme.textDark,
                                        height: 1.4)),
                              ),
                            ],
                          ),
                        ],
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 13, color: AppTheme.textLight),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(address,
                                    style: GoogleFonts.cairo(
                                        fontSize: 11, color: AppTheme.textDark),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
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
                        if (isAccepted && family != null) ...[
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
                                  backgroundColor: _green,
                                  child: Text(
                                    ((family['first_name'] as String? ?? ' ')
                                                .isNotEmpty
                                            ? (family['first_name'] as String)
                                                .substring(0, 1)
                                            : '') +
                                        ((family['last_name'] as String? ?? ' ')
                                                .isNotEmpty
                                            ? (family['last_name'] as String)
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
                                    '${family['first_name'] ?? ''} ${family['last_name'] ?? ''}'
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
                                  Text(family['phone_number'] ?? 'غير متوفر',
                                      style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          color: const Color(0xFF3B6D11))),
                                ]),
                              ],
                            ),
                          ),
                        ],
                        if (status == 'pending' || status == 'accepted') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (status == 'pending')
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      onAccept(req);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 11),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                            colors: [_green, _greenDark]),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                              Icons.volunteer_activism_rounded,
                                              size: 16,
                                              color: Colors.white),
                                          const SizedBox(width: 6),
                                          Text('قبول الطلب ✅',
                                              style: GoogleFonts.cairo(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (status == 'pending') const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    onComplete(req);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 11),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF2563EB)
                                      ]),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 16,
                                            color: Colors.white),
                                        const SizedBox(width: 6),
                                        Text(
                                            status == 'accepted'
                                                ? 'إكمال الطلب 🎉'
                                                : 'إكمال 🎉',
                                            style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
}