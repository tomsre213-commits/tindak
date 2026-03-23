import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isScanned = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isScanned) return;

    final Barcode? barcode =
    capture.barcodes.isNotEmpty ? capture.barcodes.first : null;

    final String? code = barcode?.rawValue;

    if (code == null || code.isEmpty) return;

    _isScanned = true;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Detected'),
        content: Text('Scanned value: $code'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                setState(() {
                  _isScanned = false;
                });
              }
            },
            child: const Text('Scan Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, code);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (!mounted) return;

    setState(() {
      _torchOn = !_torchOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),

          Container(
            color: Colors.black.withOpacity(0.35),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Scan to Ride',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                ],
              ),
            ),
          ),

          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 5),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 90),
                GestureDetector(
                  onTap: _toggleTorch,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 10,
                          color: Colors.black26,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _torchOn ? Icons.flash_on : Icons.flashlight_off,
                      size: 34,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}