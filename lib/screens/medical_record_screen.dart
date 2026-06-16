import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';

class _RecordType {
  final String key;
  final String label;
  final String unit;
  final String hint;
  final IconData icon;
  final Color color;

  const _RecordType({
    required this.key,
    required this.label,
    required this.unit,
    required this.hint,
    required this.icon,
    required this.color,
  });
}

const List<_RecordType> kRecordTypes = [
  _RecordType(
    key: 'sugar',
    label: 'سكري',
    unit: 'mg/dL',
    hint: 'مثال: 110',
    icon: Icons.water_drop_rounded,
    color: Color(0xFFEA580C),
  ),
  _RecordType(
    key: 'bp',
    label: 'ضغط الدم',
    unit: 'mmHg',
    hint: 'مثال: 120/80',
    icon: Icons.monitor_heart_rounded,
    color: Color(0xFFDC2626),
  ),
  _RecordType(
    key: 'temp',
    label: 'درجة الحرارة',
    unit: '°C',
    hint: 'مثال: 36.8',
    icon: Icons.thermostat_rounded,
    color: Color(0xFFD97706),
  ),
  _RecordType(
    key: 'custom',
    label: 'إضافي',
    unit: '',
    hint: 'أدخل القيمة',
    icon: Icons.add_circle_outline_rounded,
    color: Color(0xFF0D9488),
  ),
];

class MedicalRecordScreen extends StatefulWidget {
  const MedicalRecordScreen({super.key});

  @override
  State<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends State<MedicalRecordScreen> {
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _filtered = [];
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String _userId = '';
  String _search = '';
  String _sort = 'date-desc';

  final _searchCtrl = TextEditingController();

  
  static const _sortOptions = [
    {'value': 'date-desc', 'label': 'الأحدث أولاً'},
    {'value': 'date-asc', 'label': 'الأقدم أولاً'},
    {'value': 'name-asc', 'label': 'الاسم أ–ي'},
    {'value': 'name-desc', 'label': 'الاسم ي–أ'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id') ?? '';

      final profile = await ApiService().getUserProfile();
      setState(() => _userProfile = profile);

      await _loadRecords();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('تعذّر تحميل البيانات: $e', AppTheme.error);
    }
  }

  Future<void> _loadRecords() async {
    try {
      
      final records =
          await ApiService().getMedicalRecords(_userId, sort: _sort);
      setState(() {
        _records = records.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
      _applySearch(_search);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('تعذّر تحميل السجلات: $e', AppTheme.error);
    }
  }

  void _applySearch(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _search = q;
      _filtered = q.isEmpty
          ? List.from(_records)
          : _records
              .where(
                (r) =>
                    (r['label'] ?? '').toLowerCase().contains(lower) ||
                    (r['value'] ?? '').toLowerCase().contains(lower) ||
                    (r['notes'] ?? '').toLowerCase().contains(lower),
              )
              .toList();
    });
  }

  
  @override
  Widget build(BuildContext context) {
    final firstName = _userProfile?['first_name'] ?? '';
    final lastName = _userProfile?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.headerGradient),
        ),
        title: Text('السجل الطبي',
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  FadeInDown(
                      child: _patientCard(
                          fullName.isEmpty ? 'المستخدم' : fullName)),
                  const SizedBox(height: 16),

                  
                  FadeInDown(
                      delay: const Duration(milliseconds: 80),
                      child: _searchSortRow()),
                  const SizedBox(height: 12),

                  
                  if (_filtered.isEmpty) ...[
                    FadeInUp(child: _emptyState()),
                  ] else ...[
                    FadeInUp(
                        child: _sectionTitle(
                            'السجلات الطبية (${_filtered.length})')),
                    FadeInUp(child: _recordsList()),
                  ],

                  const SizedBox(height: 24),
                  FadeInUp(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showAddRecordDialog,
                        icon:
                            const Icon(Icons.add_rounded, color: Colors.white),
                        label: Text('إضافة سجل طبي جديد',
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  
  Widget _patientCard(String name) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.mainGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15)),
              Text('السجل الطبي الشخصي',
                  style:
                      GoogleFonts.cairo(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchSortRow() {
    return Row(
      children: [
        
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            style: GoogleFonts.cairo(fontSize: 13),
            onChanged: _applySearch,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'ابحث عن تحليل...',
              hintStyle:
                  GoogleFonts.cairo(fontSize: 12, color: AppTheme.textLight),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _applySearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppTheme.primary.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppTheme.primary.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sort,
              icon: const Icon(Icons.sort_rounded, size: 18),
              style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textDark),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _sort = v);
                _loadRecords();
              },
              items: _sortOptions
                  .map((o) => DropdownMenuItem<String>(
                        value: o['value'],
                        child: Text(o['label']!,
                            style: GoogleFonts.cairo(fontSize: 12)),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark)),
      );

  Widget _recordsList() {
    return Column(
      children: _filtered.asMap().entries.map((e) {
        final record = e.value;
        final type = kRecordTypes.firstWhere(
          (t) => t.key == (record['record_type'] ?? 'custom'),
          orElse: () => kRecordTypes.last,
        );
        final status = record['status'] ?? 'normal';

        return FadeInRight(
          delay: Duration(milliseconds: e.key * 50),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.04), blurRadius: 8)
              ],
            ),
            child: Row(
              children: [
                
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(type.icon, color: type.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      Row(
                        children: [
                          Text(record['label'] ?? '',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 6),
                          _statusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      
                      Text(
                        '${record['value'] ?? ''}'
                        '${(record['unit'] ?? '').isNotEmpty ? '  ${record['unit']}' : ''}',
                        style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: type.color),
                      ),
                      
                      if ((record['notes'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(record['notes'],
                            style: GoogleFonts.cairo(
                                fontSize: 11, color: AppTheme.textLight)),
                      ],
                      
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 12, color: AppTheme.textLight),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(record['created_at'] ?? ''),
                            style: GoogleFonts.cairo(
                                fontSize: 10, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444), size: 20),
                  onPressed: () =>
                      _deleteRecord(record['id']?.toString() ?? ''),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _statusBadge(String status) {
    final cfg = <String, Map<String, dynamic>>{
          'normal': {
            'label': 'طبيعي',
            'bg': const Color(0xFFDCFCE7),
            'fg': const Color(0xFF166534)
          },
          'high': {
            'label': 'مرتفع',
            'bg': const Color(0xFFFEE2E2),
            'fg': const Color(0xFF991B1B)
          },
          'low': {
            'label': 'منخفض',
            'bg': const Color(0xFFFEF3C7),
            'fg': const Color(0xFF92400E)
          },
        }[status] ??
        {'label': status, 'bg': Colors.grey[100]!, 'fg': Colors.grey[600]!};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cfg['bg'] as Color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(cfg['label'] as String,
          style: GoogleFonts.cairo(
              fontSize: 10,
              color: cfg['fg'] as Color,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _emptyState() {
    final hasSearch = _search.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(
            hasSearch
                ? Icons.search_off_rounded
                : Icons.medical_services_outlined,
            size: 48,
            color: const Color(0xFFBFDBFE),
          ),
          const SizedBox(height: 12),
          Text(
            hasSearch
                ? 'لا توجد نتائج لـ "$_search"'
                : 'لا توجد سجلات طبية بعد',
            style: GoogleFonts.cairo(color: AppTheme.textLight, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 8),
            Text('اضغط على "إضافة سجل" لإضافة أول سجل طبي',
                style:
                    GoogleFonts.cairo(color: AppTheme.textLight, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  
  Widget _buildTypeGrid(
    List<_RecordType> types,
    _RecordType selected,
    StateSetter setDialogState,
    ValueChanged<_RecordType> onSelect,
  ) {
    Widget typeBtn(_RecordType t) {
      final isSelected = selected.key == t.key;
      return Expanded(
        child: GestureDetector(
          onTap: () => setDialogState(() => onSelect(t)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? t.color.withValues(alpha: 0.12) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? t.color : Colors.grey.withValues(alpha: 0.2),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(t.icon,
                    color: isSelected ? t.color : AppTheme.textLight, size: 18),
                const SizedBox(width: 6),
                Text(t.label,
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? t.color : AppTheme.textLight)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: [
          typeBtn(types[0]),
          const SizedBox(width: 8),
          typeBtn(types[1]),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          typeBtn(types[2]),
          const SizedBox(width: 8),
          typeBtn(types[3]),
        ]),
      ],
    );
  }

  
  Future<void> _showAddRecordDialog() async {
    _RecordType selectedType = kRecordTypes.first;
    final valueCtrl = TextEditingController();
    final customNameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text('إضافة سجل طبي جديد',
              style:
                  GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                _buildTypeGrid(kRecordTypes, selectedType, setDialogState, (t) {
                  selectedType = t;
                }),
                const SizedBox(height: 14),

                
                if (selectedType.key == 'custom') ...[
                  Text('اسم التحليل',
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: AppTheme.textLight)),
                  const SizedBox(height: 4),
                  _dialogTextField(
                    controller: customNameCtrl,
                    hint: 'مثال: كوليسترول، فيتامين D...',
                  ),
                  const SizedBox(height: 12),
                ],

                
                Text(
                  selectedType.unit.isNotEmpty
                      ? 'القيمة (${selectedType.unit})'
                      : 'القيمة',
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: AppTheme.textLight),
                ),
                const SizedBox(height: 4),
                _dialogTextField(
                  controller: valueCtrl,
                  hint: selectedType.hint,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 12),

                
                Text('ملاحظات (اختياري)',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppTheme.textLight)),
                const SizedBox(height: 4),
                _dialogTextField(
                  controller: notesCtrl,
                  hint: 'مثال: بعد الأكل، صيام...',
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('إلغاء',
                        style: GoogleFonts.cairo(color: AppTheme.textLight)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final val = valueCtrl.text.trim();
                      if (val.isEmpty) return;
                      await _addRecord(
                        type: selectedType.key,
                        customName: customNameCtrl.text.trim(),
                        value: val,
                        notes: notesCtrl.text.trim(),
                      );
                      if (mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('حفظ',
                        style: GoogleFonts.cairo(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.cairo(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textLight),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  
  Future<void> _addRecord({
    required String type,
    required String customName,
    required String value,
    required String notes,
  }) async {
    try {
      await ApiService().addMedicalRecord(_userId, {
        'record_type': type,
        'label': customName, 
        'value': value,
        'notes': notes,
        
      });
      _showSnack('تمت الإضافة بنجاح ✅', AppTheme.success);
      _loadRecords();
    } catch (e) {
      _showSnack('فشل الحفظ: $e', AppTheme.error);
    }
  }

  Future<void> _deleteRecord(String id) async {
    if (id.isEmpty) return;
    try {
      await ApiService().deleteMedicalRecord(id);
      _showSnack('تم الحذف', AppTheme.warning);
      _loadRecords();
    } catch (e) {
      _showSnack('فشل الحذف: $e', AppTheme.error);
    }
  }

  

  String _formatDateTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const days = [
        'الأحد',
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت'
      ];
      final day = days[dt.weekday % 7];
      final date = '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
      final time = '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
      return '$day $date — $time';
    } catch (_) {
      return iso;
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.cairo()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
