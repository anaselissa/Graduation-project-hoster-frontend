import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';

class JordanMapScreen extends StatefulWidget {
  const JordanMapScreen({super.key});

  @override
  State<JordanMapScreen> createState() => _JordanMapScreenState();
}

class _JordanMapScreenState extends State<JordanMapScreen>
    with TickerProviderStateMixin {
  static const LatLng _defaultCenter = LatLng(31.9454, 35.9284);
  final MapController _mapController = MapController();

  List<Marker> _markers = [];
  bool _isLoading = true;
  String _statusText = 'جارٍ تحميل الخريطة...';
  int _itemCount = 0;
  LatLng? _myLocation;
  String _userType = '';

  // نحتفظ ببيانات الطلبات عشان نستخدمها في الـ bottom sheet
  List<dynamic> _requestsData = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _init();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _userType = prefs.getString('user_type') ?? 'family';
    await _getMyLocation();
    await _loadData();
  }

  Future<void> _getMyLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _myLocation = const LatLng(32.5568, 35.8469));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _myLocation = const LatLng(32.5568, 35.8469));
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _myLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      setState(() => _myLocation = const LatLng(32.5568, 35.8469));
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final center = _myLocation ?? _defaultCenter;
      final newMarkers = <Marker>[];

      if (_myLocation != null) {
        newMarkers.add(_buildMyMarker(_myLocation!));
      }

      if (_userType == 'family') {
        final result = await ApiService().getNearbyVolunteers(
          lat: center.latitude,
          lng: center.longitude,
          radius: 100,
        );
        final volunteers = result['volunteers'] as List<dynamic>? ?? [];

        for (final v in volunteers) {
          final lat = v['latitude'];
          final lng = v['longitude'];
          if (lat == null || lng == null) continue;

          final name =
              '${v['first_name'] ?? ''} ${v['last_name'] ?? ''}'.trim();
          final distance = v['air_distance_km']?.toString() ?? '';

          newMarkers.add(_buildVolunteerMarker(
            LatLng((lat as num).toDouble(), (lng as num).toDouble()),
            name,
            distance,
          ));
        }

        setState(() {
          _markers = newMarkers;
          _itemCount = volunteers.length;
          _isLoading = false;
          _statusText = volunteers.isEmpty
              ? 'لا يوجد متطوعون متاحون حالياً'
              : 'يوجد ${volunteers.length} متطوع قريب منك';
        });
      } else {
        // volunteer — يشوف الطلبات ويقدر يقبل أو يرفض
        final result = await ApiService().getNearbyRequests(
          lat: center.latitude,
          lng: center.longitude,
          radius: 100,
        );
        final requests = result['requests'] as List<dynamic>? ?? [];
        _requestsData = requests;

        for (final r in requests) {
          final lat = r['latitude'];
          final lng = r['longitude'];
          if (lat == null || lng == null) continue;

          newMarkers.add(_buildRequestMarker(
            LatLng((lat as num).toDouble(), (lng as num).toDouble()),
            r,
          ));
        }

        setState(() {
          _markers = newMarkers;
          _itemCount = requests.length;
          _isLoading = false;
          _statusText = requests.isEmpty
              ? 'لا توجد طلبات قريبة منك حالياً'
              : 'يوجد ${requests.length} طلب مساعدة قريب منك';
        });
      }

      if (_myLocation != null) {
        _mapController.move(_myLocation!, 10.0);
      }
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusText = 'تعذّر تحميل البيانات';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ: $e', style: GoogleFonts.cairo()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  // ── Accept / Reject ──────────────────────────────────────────
  Future<void> _acceptRequest(String requestId) async {
    try {
      await ApiService().acceptServiceRequest(requestId);
      if (mounted) {
        Navigator.pop(context); // أغلق الـ bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم قبول الطلب ✅', style: GoogleFonts.cairo()),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
        _loadData(); // تحديث الخريطة
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل القبول: $e', style: GoogleFonts.cairo()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      await ApiService().cancelServiceRequest(requestId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم رفض الطلب ❌', style: GoogleFonts.cairo()),
          backgroundColor: AppTheme.textLight,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل الرفض: $e', style: GoogleFonts.cairo()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  // ── Bottom Sheet للطلب ───────────────────────────────────────
  void _showRequestSheet(Map<String, dynamic> request) {
    final urgency = request['urgency'] ?? 'normal';
    final status = request['status'] ?? 'pending';
    final color = urgency == 'urgent'
        ? Colors.red
        : urgency == 'high'
            ? Colors.orange
            : AppTheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // العنوان والحالة
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.elderly_rounded, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request['title'] ?? 'طلب مساعدة',
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          _urgencyLabel(urgency),
                          style: GoogleFonts.cairo(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  // رقم الطلب
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppTheme.mainGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${request['id']?.toString().substring(0, 6) ?? '—'}',
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // الوصف
              if (request['description'] != null &&
                  (request['description'] as String).isNotEmpty) ...[
                Text(
                  request['description'],
                  style: GoogleFonts.cairo(
                      color: AppTheme.textLight, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 12),
              ],

              // معلومات إضافية
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (request['air_distance_km'] != null)
                    _chip('📍 ${request['air_distance_km']} كم',
                        AppTheme.primary),
                  if (request['service_type_id'] != null)
                    _chip('🛠️ ${request['service_type_id']}',
                        AppTheme.secondary),
                  _chip(_statusLabel(status), _statusColor(status)),
                ],
              ),
              const SizedBox(height: 24),

              // أزرار القبول والرفض — بس إذا الطلب pending
              if (status == 'pending') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelRequest(request['id']),
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: Colors.red),
                        label: Text('رفض',
                            style: GoogleFonts.cairo(
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _acceptRequest(request['id']),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text('قبول الطلب',
                            style:
                                GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _statusColor(status).withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      'الطلب ${_statusLabel(status)}',
                      style: GoogleFonts.cairo(
                          color: _statusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ),
              ],
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Markers ──────────────────────────────────────────────────
  Marker _buildMyMarker(LatLng point) {
    final isFamily = _userType == 'family';
    final color = isFamily ? AppTheme.primary : const Color(0xFF10B981);
    final icon =
        isFamily ? Icons.home_rounded : Icons.volunteer_activism_rounded;

    return Marker(
      point: point,
      width: 90,
      height: 90,
      child: GestureDetector(
        onTap: () => _showInfoDialog('موقعي الحالي', 'أنت هنا الآن', color),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('أنا هنا',
                  style: GoogleFonts.cairo(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Marker _buildVolunteerMarker(LatLng point, String name, String distance) {
    return Marker(
      point: point,
      width: 80,
      height: 80,
      child: GestureDetector(
        onTap: () => _showInfoDialog(
          'متطوع: ${name.isEmpty ? 'مجهول' : name}',
          distance.isNotEmpty ? 'المسافة: $distance كم' : 'متطوع متاح',
          AppTheme.secondary,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary]),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: const Icon(Icons.person_pin_rounded,
                  color: Colors.white, size: 22),
            ),
            if (name.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1), blurRadius: 3)
                  ],
                ),
                child: Text(name,
                    style: GoogleFonts.cairo(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark),
                    overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ),
    );
  }

  // الماركر الجديد — يفتح bottom sheet بدل dialog
  Marker _buildRequestMarker(LatLng point, Map<String, dynamic> request) {
    final urgency = request['urgency'] ?? 'normal';
    final status = request['status'] ?? 'pending';
    final title = request['title'] ?? 'طلب مساعدة';

    final color = urgency == 'urgent'
        ? Colors.red
        : urgency == 'high'
            ? Colors.orange
            : Colors.blue;

    // لو مش pending خليه أفتح بس بدون أزرار
    return Marker(
      point: point,
      width: 90,
      height: 100,
      child: GestureDetector(
        onTap: () => _showRequestSheet(request),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(Icons.elderly_rounded,
                      color: Colors.white, size: 22),
                ),
                // بادج الحالة
                if (status == 'pending')
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.warning,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 3)
                ],
              ),
              child: Text(
                title,
                style: GoogleFonts.cairo(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  String _urgencyLabel(String urgency) {
    switch (urgency) {
      case 'urgent':
        return 'عاجل جداً 🔴';
      case 'high':
        return 'أولوية عالية 🟠';
      case 'low':
        return 'منخفضة';
      default:
        return 'عادية';
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
      default:
        return status ?? '';
    }
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
      default:
        return AppTheme.textLight;
    }
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.cairo(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  void _showInfoDialog(String title, String content, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.location_on_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(title,
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold, fontSize: 14))),
        ]),
        content: Text(content, style: GoogleFonts.cairo(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إغلاق',
                style: GoogleFonts.cairo(
                    color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isFamily = _userType == 'family';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isFamily ? 'خريطة المتطوعين' : 'طلبات المساعدة القريبة',
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppTheme.primary.withValues(alpha: 0.15),
                AppTheme.primary.withValues(alpha: 0.05),
              ]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2), width: 1.5),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: AppTheme.primary, size: 20),
              onPressed: _loadData,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _myLocation ?? _defaultCenter,
              initialZoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rayatukum.app',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          // Legend
          Positioned(
            top: 16,
            right: 16,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem(
                      isFamily ? AppTheme.primary : const Color(0xFF10B981),
                      isFamily
                          ? Icons.home_rounded
                          : Icons.volunteer_activism_rounded,
                      'موقعك',
                    ),
                    const SizedBox(height: 6),
                    if (isFamily)
                      _legendItem(
                          AppTheme.secondary, Icons.person_pin_rounded, 'متطوع')
                    else ...[
                      _legendItem(Colors.blue, Icons.elderly_rounded, 'عادي'),
                      const SizedBox(height: 4),
                      _legendItem(Colors.orange, Icons.elderly_rounded, 'عالي'),
                      const SizedBox(height: 4),
                      _legendItem(Colors.red, Icons.elderly_rounded, 'عاجل'),
                    ],
                  ],
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary)),
            ),

          // Status bar
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.15), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppTheme.primary.withValues(alpha: 0.15),
                          AppTheme.primary.withValues(alpha: 0.05),
                        ]),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFamily
                            ? Icons.location_on_rounded
                            : Icons.elderly_rounded,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoading ? 'جارٍ التحميل...' : _statusText,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            !isFamily
                                ? 'اضغط على الطلب للقبول أو الرفض'
                                : 'اضغط على أي أيقونة للتفاصيل',
                            style: GoogleFonts.cairo(
                                color: AppTheme.textLight, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (_itemCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            AppTheme.primary,
                            AppTheme.primary.withValues(alpha: 0.8)
                          ]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('$_itemCount',
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 12),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textDark)),
      ],
    );
  }
}
