// screens/home_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'landmark_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  XFile? _frontalXFile;
  XFile? _profileXFile;
  Uint8List? _frontalBytes;
  Uint8List? _profileBytes;

  bool _isAnalyzing = false;
  String? _errorMessage;

  final _picker = ImagePicker();
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFrontal) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1920,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      if (isFrontal) {
        _frontalXFile = picked;
        _frontalBytes = bytes;
      } else {
        _profileXFile = picked;
        _profileBytes = bytes;
      }
      _errorMessage = null;
    });
  }

  Future<void> _analyze() async {
    if (_frontalXFile == null && _profileXFile == null) {
      setState(() => _errorMessage = 'Please select at least one photo.');
      return;
    }
    setState(() => _errorMessage = null);
    if (mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, a, __) => LandmarkEditorScreen(
            frontalXFile: _frontalXFile,
            frontalBytes: _frontalBytes,
            profileXFile: _profileXFile,
            profileBytes: _profileBytes,
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF0A0E1A),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeaderBg(controller: _pulseCtrl),
              title: Text(
                'FaceIQ Labs',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Precision facial harmony analysis based on 40+ anthropometric ratios.',
                  style: GoogleFonts.inter(
                      color: Colors.white54, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 28),
                Text(
                  'UPLOAD PHOTOS',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _PhotoSlot(
                        label: 'Front View',
                        icon: Icons.face,
                        hint: 'Looking straight ahead, neutral expression',
                        imageBytes: _frontalBytes,
                        onTap: () => _pickImage(true),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _PhotoSlot(
                        label: 'Side Profile',
                        icon: Icons.face_retouching_natural,
                        hint: '90° profile view, chin parallel to ground',
                        imageBytes: _profileBytes,
                        onTap: () => _pickImage(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _TipsCard(),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFFF6B6B).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFFF6B6B), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: const TextStyle(
                                  color: Color(0xFFFF6B6B), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                _AnalyzeButton(
                  enabled: (_frontalXFile != null || _profileXFile != null) &&
                      !_isAnalyzing,
                  loading: _isAnalyzing,
                  onTap: _analyze,
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _HeaderBg extends StatelessWidget {
  final AnimationController controller;
  const _HeaderBg({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D1326), Color(0xFF0A0E1A)],
            ),
          ),
        ),
        Positioned(
          top: -30 + controller.value * 10,
          right: 30,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF00D4AA).withOpacity(0.15),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: -20,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF7BC8F6).withOpacity(0.1),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
      ]),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.03);
    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _PhotoSlot extends StatelessWidget {
  final String label;
  final IconData icon;
  final String hint;
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  const _PhotoSlot({
    required this.label,
    required this.icon,
    required this.hint,
    required this.imageBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF111622),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: imageBytes != null
                ? const Color(0xFF00D4AA).withOpacity(0.5)
                : Colors.white12,
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: imageBytes != null
              ? Stack(fit: StackFit.expand, children: [
                  Image.memory(imageBytes!, fit: BoxFit.cover),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xDD0A0E1A), Colors.transparent],
                        ),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF00D4AA), size: 14),
                        const SizedBox(width: 4),
                        Text(label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Icon(Icons.edit, color: Colors.white60, size: 14),
                      ]),
                    ),
                  ),
                ])
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF00D4AA).withOpacity(0.3)),
                      ),
                      child:
                          Icon(icon, color: const Color(0xFF00D4AA), size: 24),
                    ),
                    const SizedBox(height: 12),
                    Text(label,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(hint,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 10,
                              height: 1.4)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Choose Photo',
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    const tips = [
      ('Lighting', 'Bright, even lighting — avoid harsh shadows'),
      ('Expression', 'Neutral, relaxed face; mouth closed'),
      ('Angle', 'Camera at eye level for front; exactly 90° for profile'),
      ('Distance', 'Full face visible, no extreme close-ups'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111622),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7BC8F6).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.tips_and_updates_outlined,
                color: Color(0xFF7BC8F6), size: 16),
            const SizedBox(width: 8),
            Text('Photo Tips for Accurate Results',
                style: GoogleFonts.inter(
                    color: const Color(0xFF7BC8F6),
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          ...tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: TextStyle(
                            color: const Color(0xFF7BC8F6).withOpacity(0.6),
                            fontSize: 12)),
                    Text('${t.$1}: ',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    Expanded(
                        child: Text(t.$2,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _AnalyzeButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _AnalyzeButton(
      {required this.enabled, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF0099CC)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [
                    BoxShadow(
                        color: const Color(0xFF00D4AA).withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ]
                : null,
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.analytics_outlined,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text('Analyze Face',
                          style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
