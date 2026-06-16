import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../utils/openai_service.dart';
import '../services/api_service.dart';

class ServiceOrder {
  String? serviceKey;
  String? serviceTitle;
  String? address;
  String? notes;
  String? preferredTime;

  bool get isComplete =>
      serviceKey != null && address != null && preferredTime != null;

  Map<String, dynamic> toJson() => {
        'service_key': serviceKey,
        'service_title': serviceTitle,
        'address': address,
        'notes': notes ?? '',
        'preferred_time': preferredTime,
      };
}

const List<Map<String, dynamic>> kServices = [
  {'icon': '💊', 'title': 'توصيل أدوية', 'key': 'medicine_delivery'},
  {'icon': '🍽️', 'title': 'توصيل طعام', 'key': 'food_delivery'},
  {'icon': '🚕', 'title': 'نقل ومواصلات', 'key': 'transportation'},
  {'icon': '🏥', 'title': 'رعاية طبية', 'key': 'medical_care'},
  {'icon': '🔧', 'title': 'إصلاح منزلي', 'key': 'home_maintenance'},
  {'icon': '📚', 'title': 'دعم تعليمي', 'key': 'educational_support'},
  {'icon': '🤝', 'title': 'مرافقة كبار', 'key': 'elderly_companionship'},
  {'icon': '🛒', 'title': 'تسوق وشراء', 'key': 'shopping'},
];

enum _OrderStep { idle, selectService, address, time, notes, confirm, done }

class ChatbotScreen extends StatefulWidget {

  final String userType;
  final String? initialMessage;

  const ChatbotScreen({
    super.key,
    required this.userType,
    this.initialMessage,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  late AnimationController _appBarController;
  late AnimationController _inputController;
  late AnimationController _typingController;

  
  _OrderStep _orderStep = _OrderStep.idle;
  final ServiceOrder _currentOrder = ServiceOrder();

  
  late final List<Map<String, dynamic>> _messages;

  bool get isFamily => widget.userType == 'family';
  bool get isVolunteer => widget.userType == 'volunteer';

  
  List<String> get _quickReplies => isFamily
      ? [
          '📋 اطلب خدمة',
          '🗺️ أين المتطوعون؟',
          '📦 تتبع طلبي',
          '📞 تواصل معنا',
        ]
      : [
          '📅 مواعيدي اليوم',
          '✅ إنهاء مهمة',
          '🗺️ عرض الخريطة',
          '📊 إحصائياتي',
        ];

  @override
  void initState() {
    super.initState();

    
    _messages = [
      {
        'text': isFamily
            ? 'مرحباً! 👋 أنا مساعد رعايتكم الذكي.\nيمكنني مساعدتك في طلب الخدمات وتتبعها. كيف يمكنني مساعدتك اليوم؟'
            : 'أهلاً بك متطوعاً في رعايتكم! 🌟\nيمكنني مساعدتك في إدارة مهامك ومواعيدك وإحصائياتك.',
        'isUser': false,
        'time': 'الآن',
        'type': 'text',
      },
    ];

    _appBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _inputController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialMessage!);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _appBarController.dispose();
    _inputController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  
  
  
  void _addBotMessage(String text, {String type = 'text'}) {
    setState(() {
      _messages.add({
        'text': text,
        'isUser': false,
        'time':
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'type': type,
      });
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({
        'text': text,
        'isUser': true,
        'time':
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'type': 'text',
      });
    });
    _scrollToBottom();
  }

  
  
  
  Future<void> _handleOrderFlow(String userInput) async {
    switch (_orderStep) {
      
      case _OrderStep.selectService:
        final match = kServices.firstWhere(
          (s) => userInput.contains(s['title']) || userInput.contains(s['key']),
          orElse: () => {},
        );
        if (match.isEmpty) {
          _addBotMessage(
              'عذراً، لم أتعرف على الخدمة. يرجى اختيار إحدى الخدمات المتاحة 👇');
          setState(() => _orderStep = _OrderStep.selectService);
          return;
        }
        _currentOrder.serviceKey = match['key'];
        _currentOrder.serviceTitle = match['title'];
        setState(() => _orderStep = _OrderStep.address);
        _addBotMessage(
            'ممتاز! اخترت "${match['icon']} ${match['title']}"\n\nالآن، أرسل لي عنوانك الكامل 📍');
        break;

      
      case _OrderStep.address:
        if (userInput.length < 5) {
          _addBotMessage('يرجى كتابة عنوان أكثر تفصيلاً 📍');
          return;
        }
        _currentOrder.address = userInput;
        setState(() => _orderStep = _OrderStep.time);
        _addBotMessage(
            'تم تسجيل العنوان ✅\n\nما هو الوقت المفضل لك لاستقبال الخدمة؟\nمثال: اليوم الساعة 3 عصراً، أو غداً صباحاً ⏰');
        break;

      
      case _OrderStep.time:
        if (userInput.length < 3) {
          _addBotMessage('يرجى تحديد وقت واضح ⏰');
          return;
        }
        _currentOrder.preferredTime = userInput;
        setState(() => _orderStep = _OrderStep.notes);
        _addBotMessage(
            'هل لديك أي ملاحظات إضافية تريد إضافتها للطلب؟ 📝\n(اكتب "لا" إن لم يكن لديك ملاحظات)');
        break;

      
      case _OrderStep.notes:
        _currentOrder.notes = userInput.toLowerCase() == 'لا' ? '' : userInput;
        setState(() => _orderStep = _OrderStep.confirm);
        _addBotMessage(_buildOrderSummary(), type: 'order_summary');
        break;

      
      case _OrderStep.confirm:
        if (userInput == 'تأكيد الطلب') {
          await _submitOrder();
        } else if (userInput == 'إلغاء') {
          _cancelOrder();
        } else {
          _addBotMessage('اضغط "تأكيد الطلب" لإرسال الطلب أو "إلغاء" للتراجع');
        }
        break;

      default:
        break;
    }
  }

  String _buildOrderSummary() {
    return '''📋 ملخص طلبك:

🔹 الخدمة: ${_currentOrder.serviceTitle}
📍 العنوان: ${_currentOrder.address}
⏰ الوقت المفضل: ${_currentOrder.preferredTime}
${_currentOrder.notes!.isNotEmpty ? '📝 ملاحظات: ${_currentOrder.notes}' : ''}

هل تريد تأكيد الطلب؟''';
  }

  Future<void> _submitOrder() async {
    setState(() {
      _isTyping = true;
      _orderStep = _OrderStep.done;
    });

    try {
      
      String? serviceTypeId;
      try {
        final serviceTypes = await ApiService().getServiceTypes();

        
        final keywordMap = {
          'توصيل أدوية': ['دواء', 'أدوية', 'medicine', 'drug'],
          'توصيل طعام': ['طعام', 'غذاء', 'وجبة', 'food'],
          'نقل ومواصلات': ['نقل', 'مواصلات', 'سيارة', 'transport'],
          'رعاية طبية': ['طبي', 'رعاية', 'صحة', 'medical'],
          'إصلاح منزلي': ['منزل', 'إصلاح', 'صيانة', 'home', 'maintenance'],
          'دعم تعليمي': ['تعليم', 'دراسة', 'تدريس', 'education'],
          'مرافقة كبار': ['مرافقة', 'كبار', 'مسن', 'companion'],
          'تسوق وشراء': ['تسوق', 'شراء', 'shopping'],
        };

        final orderTitle = _currentOrder.serviceTitle ?? '';
        final keywords = keywordMap[orderTitle] ?? [orderTitle];

        for (final type in serviceTypes) {
          final dbName = (type['name'] ?? '').toString().toLowerCase();
          final dbDesc = (type['description'] ?? '').toString().toLowerCase();

          
          if (dbName == orderTitle.toLowerCase()) {
            serviceTypeId = type['id'].toString();
            break;
          }

          
          for (final kw in keywords) {
            if (dbName.contains(kw.toLowerCase()) ||
                dbDesc.contains(kw.toLowerCase())) {
              serviceTypeId = type['id'].toString();
              break;
            }
          }
          if (serviceTypeId != null) break;
        }

        
        if (serviceTypeId == null && serviceTypes.isNotEmpty) {
          for (final type in serviceTypes) {
            final dbName = (type['name'] ?? '').toString();
            if (orderTitle.isNotEmpty &&
                (dbName.contains(orderTitle.substring(0, 2)) ||
                    orderTitle.contains(dbName.substring(
                        0, dbName.length > 2 ? 2 : dbName.length)))) {
              serviceTypeId = type['id'].toString();
              break;
            }
          }
        }
      } catch (_) {
        
      }

      
      final description = [
        if ((_currentOrder.notes ?? '').isNotEmpty)
          'ملاحظات: ${_currentOrder.notes}',
        'الوقت المفضل: ${_currentOrder.preferredTime ?? ''}',
      ].join('\n');

      final requestData = <String, dynamic>{
        'title': _currentOrder.serviceTitle ?? 'طلب خدمة',
        'description': description,
        'location_address': _currentOrder.address ?? '',
        'urgency': 'normal',
        
        'service_key': _currentOrder.serviceKey ?? '',
        if (serviceTypeId != null) 'service_type_id': serviceTypeId,
      };

      
      final response = await ApiService().createServiceRequest(requestData);

      
      final requestObj = response['request'] as Map<String, dynamic>?;
      final orderId = requestObj?['id']?.toString() ??
          response['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString().substring(7);

      setState(() => _isTyping = false);
      _addBotMessage(
        '✅ تم إرسال طلبك بنجاح!\n\n'
        '🔢 رقم الطلب: #$orderId\n'
        '📋 الخدمة: ${_currentOrder.serviceTitle}\n'
        '📍 العنوان: ${_currentOrder.address}\n'
        '⏰ الوقت: ${_currentOrder.preferredTime}\n\n'
        'سيتواصل معك أحد المتطوعين قريباً 🎉',
      );

      
      _currentOrder.serviceKey = null;
      _currentOrder.serviceTitle = null;
      _currentOrder.address = null;
      _currentOrder.preferredTime = null;
      _currentOrder.notes = null;
    } catch (e) {
      setState(() {
        _isTyping = false;
        _orderStep = _OrderStep.idle;
      });
      _addBotMessage(
        '❌ حدث خطأ أثناء إرسال الطلب.\n\n'
        '${e.toString()}\n\n'
        'هل تريد المحاولة مرة أخرى؟',
      );
    }
  }

  void _cancelOrder() {
    _currentOrder.serviceKey = null;
    _currentOrder.address = null;
    _currentOrder.preferredTime = null;
    _currentOrder.notes = null;
    setState(() => _orderStep = _OrderStep.idle);
    _addBotMessage('تم إلغاء الطلب. هل يمكنني مساعدتك بشيء آخر؟ 😊');
  }

  
  
  
  Future<void> _sendMessage([String? quickText]) async {
    final text = quickText ?? _controller.text.trim();
    if (text.isEmpty) return;
    if (quickText == null) _controller.clear();

    _addUserMessage(text);

    
    if (isFamily) {
      if (_orderStep == _OrderStep.idle &&
          (text.contains('اطلب خدمة') ||
              text.contains('طلب') ||
              text.contains('أريد') ||
              text.contains('ابغى'))) {
        setState(() => _orderStep = _OrderStep.selectService);
        _addBotMessage(
            'بالطبع! 😊 اختر نوع الخدمة التي تحتاجها 👇\n(اكتب اسم الخدمة أو اضغط عليها)');
        
        setState(() {
          _messages.add({
            'text': '',
            'isUser': false,
            'time':
                '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            'type': 'service_picker',
          });
        });
        _scrollToBottom();
        return;
      }

      
      if (_orderStep != _OrderStep.idle && _orderStep != _OrderStep.done) {
        await _handleOrderFlow(text);
        return;
      }
    }

    
    if (isVolunteer) {
      if (text.contains('مواعيدي') || text.contains('اليوم')) {
        _addBotMessage(
            '📅 مواعيدك اليوم:\n\n1️⃣ 10:00ص - مرافقة مريض - حي النزهة\n2️⃣ 2:00م - توصيل أدوية - شارع الملك\n3️⃣ 5:00م - تسوق - أبو نصير\n\nهل تريد تفاصيل أي منها؟');
        return;
      }
      if (text.contains('إحصائيات') || text.contains('نقاطي')) {
        _addBotMessage(
            '📊 إحصائياتك هذا الشهر:\n\n✅ المهام المنجزة: 12\n⭐ التقييم: 4.8/5\n🏆 النقاط: 340\n🥇 المرتبة: 3 في منطقتك\n\nأداء رائع! استمر 💪');
        return;
      }
      if (text.contains('إنهاء مهمة') || text.contains('أنهيت')) {
        _addBotMessage(
            '✅ ممتاز! لتأكيد إنهاء المهمة:\n\n1. افتح قسم "مهامي النشطة"\n2. اضغط على المهمة\n3. اضغط "تم الإنجاز"\n\nأو أخبرني برقم المهمة وسأساعدك مباشرة 👍');
        return;
      }
    }

    
    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final systemContext = isFamily
        ? 'أنت مساعد تطبيق رعايتكم الإنساني. تساعد المنتفعون كبار السن في الأردن على طلب الخدمات التطوعية. ردودك باللغة العربية، ودودة ومختصرة.'
        : 'أنت مساعد تطبيق رعايتكم للمتطوعين. تساعد المتطوعين في إدارة مهامهم ومواعيدهم وإحصائياتهم. ردودك باللغة العربية، تحفيزية ومهنية.';

    final botResponse = await OpenAIService.getChatResponse(
      '$systemContext\n\nرسالة المستخدم: $text',
    );

    if (!mounted) return;
    setState(() => _isTyping = false);
    _addBotMessage(botResponse);
  }

  
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _BubblePainter())),
                ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _AnimatedMessage(
                      key: ValueKey(index),
                      child: _buildMessageWidget(msg),
                    );
                  },
                ),
              ],
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildQuickReplies(),
          
          if (_orderStep == _OrderStep.confirm) _buildConfirmButtons(),
          _buildInput(),
        ],
      ),
    );
  }

  
  
  
  Widget _buildAppBar() {
    final title = isFamily ? 'مساعد رعايتكم 🤖' : 'مساعد المتطوعين 🌟';
    final subtitle = isFamily ? 'متصل الآن · يرد فوراً' : 'دعمك في كل خطوة';
    return FadeTransition(
      opacity: _appBarController,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 16,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isFamily
                ? [
                    AppTheme.primary,
                    AppTheme.secondary,
                    const Color(0xFF6366F1)
                  ]
                : [
                    const Color(0xFF10B981),
                    const Color(0xFF059669),
                    const Color(0xFF047857)
                  ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: (isFamily ? AppTheme.primary : const Color(0xFF10B981))
                  .withValues(alpha: 0.4),
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
            _PulsingAvatar(isVolunteer: isVolunteer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                            color: Color(0xFF34D399), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(subtitle,
                          style: GoogleFonts.cairo(
                              color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(Icons.more_vert_rounded,
                  color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  
  
  
  Widget _buildMessageWidget(Map<String, dynamic> msg) {
    switch (msg['type']) {
      case 'service_picker':
        return _buildServicePicker();
      case 'order_summary':
        return _buildMessage(msg);
      default:
        return _buildMessage(msg);
    }
  }

  
  Widget _buildServicePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: kServices.map((s) {
          return GestureDetector(
            onTap: () => _sendMessage('${s['title']}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s['icon'], style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(s['title'],
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  
  Widget _buildMessage(Map<String, dynamic> msg) {
    final isUser = msg['isUser'] as bool;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _botAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isFamily
                            ? [
                                AppTheme.primary,
                                AppTheme.secondary,
                                const Color(0xFF6366F1)
                              ]
                            : [
                                const Color(0xFF10B981),
                                const Color(0xFF059669)
                              ],
                      )
                    : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? (isFamily
                                ? AppTheme.primary
                                : const Color(0xFF10B981))
                            .withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg['text'],
                    style: GoogleFonts.cairo(
                      color: isUser ? Colors.white : AppTheme.textDark,
                      fontSize: 14,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(msg['time'],
                          style: GoogleFonts.cairo(
                            color: isUser ? Colors.white60 : AppTheme.textLight,
                            fontSize: 10,
                          )),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all_rounded,
                            size: 14, color: Colors.white70),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _userAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _botAvatar() => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isFamily
                ? [AppTheme.primary, AppTheme.secondary]
                : [const Color(0xFF10B981), const Color(0xFF059669)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: (isFamily ? AppTheme.primary : const Color(0xFF10B981))
                    .withValues(alpha: 0.3),
                blurRadius: 8)
          ],
        ),
        child: Icon(
          isFamily
              ? Icons.health_and_safety_rounded
              : Icons.volunteer_activism_rounded,
          color: Colors.white,
          size: 18,
        ),
      );

  Widget _userAvatar() => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withValues(alpha: 0.2),
              AppTheme.primary.withValues(alpha: 0.08),
            ],
          ),
          shape: BoxShape.circle,
          border:
              Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
        ),
        child:
            const Icon(Icons.person_rounded, color: AppTheme.primary, size: 20),
      );

  
  Widget _buildConfirmButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _sendMessage('إلغاء'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.red.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Center(
                  child: Text('إلغاء',
                      style: GoogleFonts.cairo(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _sendMessage('تأكيد الطلب'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Center(
                  child: Text('✅ تأكيد الطلب',
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  
  
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _botAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _typingController,
                  builder: (_, __) {
                    final delay = i * 0.3;
                    final offset = ((_typingController.value - delay) % 1.0)
                        .clamp(0.0, 1.0);
                    final dy = offset < 0.5
                        ? -6.0 * (offset / 0.5)
                        : -6.0 * (1.0 - (offset - 0.5) / 0.5);
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isFamily
                                ? [AppTheme.primary, AppTheme.secondary]
                                : [
                                    const Color(0xFF10B981),
                                    const Color(0xFF059669)
                                  ],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  
  
  
  Widget _buildQuickReplies() {
    if (_messages.length > 2) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final color = isFamily ? AppTheme.primary : const Color(0xFF10B981);
          return GestureDetector(
            onTap: () => _sendMessage(_quickReplies[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.12),
                    color.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Text(_quickReplies[i],
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }

  
  
  
  Widget _buildInput() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
          parent: _inputController, curve: Curves.easeOutCubic)),
      child: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF0F4FF), Color(0xFFEFF6FF)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  textDirection: TextDirection.rtl,
                  style:
                      GoogleFonts.cairo(fontSize: 14, color: AppTheme.textDark),
                  decoration: InputDecoration(
                    hintText: _orderStep != _OrderStep.idle
                        ? _getInputHint()
                        : 'اكتب رسالتك هنا...',
                    hintStyle: GoogleFonts.cairo(
                        color: AppTheme.textLight, fontSize: 13),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.emoji_emotions_outlined,
                        color: AppTheme.textLight, size: 20),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isFamily
                        ? [
                            AppTheme.primary,
                            AppTheme.secondary,
                            const Color(0xFF6366F1)
                          ]
                        : [const Color(0xFF10B981), const Color(0xFF059669)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isFamily
                              ? AppTheme.primary
                              : const Color(0xFF10B981))
                          .withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInputHint() {
    switch (_orderStep) {
      case _OrderStep.address:
        return 'اكتب عنوانك الكامل...';
      case _OrderStep.time:
        return 'اكتب الوقت المفضل...';
      case _OrderStep.notes:
        return 'ملاحظات إضافية أو "لا"...';
      default:
        return 'اكتب رسالتك هنا...';
    }
  }
}

class _PulsingAvatar extends StatefulWidget {
  final bool isVolunteer;
  const _PulsingAvatar({this.isVolunteer = false});

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _anim,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 12)
          ],
        ),
        child: Icon(
          widget.isVolunteer
              ? Icons.volunteer_activism_rounded
              : Icons.health_and_safety_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _AnimatedMessage extends StatefulWidget {
  final Widget child;
  const _AnimatedMessage({super.key, required this.child});

  @override
  State<_AnimatedMessage> createState() => _AnimatedMessageState();
}

class _AnimatedMessageState extends State<_AnimatedMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFF3B82F6).withValues(alpha: 0.04);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.15), 70, paint);
    paint.color = const Color(0xFF8B5CF6).withValues(alpha: 0.04);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.3), 90, paint);
    paint.color = const Color(0xFF10B981).withValues(alpha: 0.04);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.7), 60, paint);
    paint.color = const Color(0xFF3B82F6).withValues(alpha: 0.03);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.85), 80, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
