import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/app_store.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/product_detail_sheet.dart';
import '../widgets/add_edit_product_sheet.dart';
import '../widgets/toast.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  MobileScannerController? _ctrl;
  bool _scanning = false;
  bool _handled = false;

  void _startScan() {
    setState(() {
      _ctrl = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
      _scanning = true;
      _handled = false;
    });
  }

  void _stopScan() {
    _ctrl?.dispose();
    setState(() {
      _ctrl = null;
      _scanning = false;
    });
  }

  void _onDetect(BarcodeCapture capture, AppStore store) {
    if (_handled) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    _handled = true;
    _stopScan();
    _lookupCode(code, store);
  }

  void _lookupCode(String code, AppStore store) {
    final found = store.findByBarcode(code);
    if (found != null) {
      showToast(context, 'Found: ${found.name}');
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ProductDetailSheet(product: found, showAddToCart: true),
      );
    } else {
      showToast(context, '⚠️ Product not found — add it?', color: AppColors.warn);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddEditProductSheet(),
          );
        }
      });
    }
  }

  void _showManualEntry(AppStore store) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.dark2,
        title: const Text('Enter Barcode', style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppColors.textColor),
          decoration: const InputDecoration(hintText: '4901085118368'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final code = ctrl.text.trim();
              if (code.isNotEmpty) _lookupCode(code, store);
            },
            child: const Text('Search', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const AppTopBar(
        wordmark: 'Scanner',
        title: 'Scan Product',
        subtitle: 'Barcode or manual entry',
      ),

      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // Camera view
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassBorder),
              ),
              clipBehavior: Clip.hardEdge,
              child: _scanning && _ctrl != null
                  ? Stack(fit: StackFit.expand, children: [
                      MobileScanner(
                        controller: _ctrl!,
                        onDetect: (capture) => _onDetect(capture, store),
                      ),
                      // Corner overlays
                      _ScanOverlay(),
                    ])
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.qr_code_scanner, size: 64, color: AppColors.accent.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text('Camera not active', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                    ]),
            ),

            const SizedBox(height: 16),
            const Text(
              'Point your camera at a barcode.\nWe\'ll find it in your inventory instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 24),

            // Buttons
            if (!_scanning)
              GradientButton(label: 'Start Camera', icon: Icons.camera_alt_outlined, onTap: _startScan, width: double.infinity)
            else
              GestureDetector(
                onTap: _stopScan,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.stop_circle_outlined, color: AppColors.danger, size: 18),
                    SizedBox(width: 8),
                    Text('Stop Camera', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                ),
              ),

            const SizedBox(height: 12),

            GestureDetector(
              onTap: () => _showManualEntry(store),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.keyboard_outlined, color: AppColors.muted2, size: 18),
                  SizedBox(width: 8),
                  Text('Enter Barcode Manually', style: TextStyle(color: AppColors.muted2, fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Scanning line animation
      const _LaserLine(),
      // Corners
      ..._corners(),
    ]);
  }

  List<Widget> _corners() {
    const size = 24.0;
    const thick = 3.0;
    const color = AppColors.accent;
    const r = 4.0;
    return [
      _corner(top: 16, left: 16, size: size, thick: thick, color: color, r: r, top_: true, left_: true),
      _corner(top: 16, right: 16, size: size, thick: thick, color: color, r: r, top_: true, left_: false),
      _corner(bottom: 16, left: 16, size: size, thick: thick, color: color, r: r, top_: false, left_: true),
      _corner(bottom: 16, right: 16, size: size, thick: thick, color: color, r: r, top_: false, left_: false),
    ];
  }

  Widget _corner({double? top, double? bottom, double? left, double? right,
      required double size, required double thick, required Color color, required double r, required bool top_, required bool left_}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: SizedBox(width: size, height: size,
        child: CustomPaint(painter: _CornerPainter(color: color, thick: thick, topLeft: top_ && left_, topRight: top_ && !left_, bottomLeft: !top_ && left_, bottomRight: !top_ && !left_)),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thick;
  final bool topLeft, topRight, bottomLeft, bottomRight;

  _CornerPainter({required this.color, required this.thick, this.topLeft = false, this.topRight = false, this.bottomLeft = false, this.bottomRight = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = thick..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final w = size.width; final h = size.height;
    if (topLeft) { canvas.drawLine(Offset(0, h), Offset(0, 0), paint); canvas.drawLine(Offset(0, 0), Offset(w, 0), paint); }
    if (topRight) { canvas.drawLine(Offset(0, 0), Offset(w, 0), paint); canvas.drawLine(Offset(w, 0), Offset(w, h), paint); }
    if (bottomLeft) { canvas.drawLine(Offset(0, 0), Offset(0, h), paint); canvas.drawLine(Offset(0, h), Offset(w, h), paint); }
    if (bottomRight) { canvas.drawLine(Offset(w, 0), Offset(w, h), paint); canvas.drawLine(Offset(w, h), Offset(0, h), paint); }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _LaserLine extends StatefulWidget {
  const _LaserLine();

  @override
  State<_LaserLine> createState() => _LaserLineState();
}

class _LaserLineState extends State<_LaserLine> with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.1, end: 0.9).animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Positioned(
        top: _anim.value * 200,
        left: 16, right: 16,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.transparent, AppColors.accent.withOpacity(0.8), Colors.transparent]),
          ),
        ),
      ),
    );
  }
}
