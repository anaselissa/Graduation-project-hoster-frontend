import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatbotBubble extends StatefulWidget {
  final Widget child;
  final String message;
  final Color bubbleColor;

  const ChatbotBubble({
    super.key,
    required this.child,
    required this.message,
    required this.bubbleColor,
  });

  @override
  State<ChatbotBubble> createState() => _ChatbotBubbleState();
}

class _ChatbotBubbleState extends State<ChatbotBubble>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  Timer? _timer;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _showOverlay();
    });
  }

  void _dismiss() {
    _timer?.cancel();
    _animController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  void _showOverlay() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: position.dx + size.width / 2,
        top: position.dy - 85,
        child: FractionalTranslation(
          translation: const Offset(-0.5, 0),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: GestureDetector(
              onTap: _dismiss,
              child: _buildBubble(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward();
    _timer = Timer(const Duration(seconds: 5), _dismiss);
  }

  Widget _buildBubble() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          constraints: const BoxConstraints(maxWidth: 180),
          decoration: BoxDecoration(
            color: widget.bubbleColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.bubbleColor.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👋', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  widget.message,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        CustomPaint(
          size: const Size(14, 8),
          painter: _TailPainter(color: widget.bubbleColor),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _overlayEntry?.remove();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _TailPainter extends CustomPainter {
  final Color color;
  const _TailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}
