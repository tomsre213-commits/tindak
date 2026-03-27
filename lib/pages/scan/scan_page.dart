import 'package:firebase_database/firebase_database.dart';
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
  bool _isUnlocking = false;

  Future<String> unlockBike(String bikeId) async {
    final ref = FirebaseDatabase.instance.ref('bikes/$bikeId');
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      throw Exception('Bike not found');
    }

    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    final currentPadlock =
        data['padlock']?.toString().trim().toLowerCase() ?? 'locked';

    if (currentPadlock == 'unlocked') {
      return 'already_unlocked';
    }

    await ref.update({
      'padlock': 'unlocked',
    });

    return 'unlocked';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isScanned || _isUnlocking) return;

    final Barcode? barcode =
    capture.barcodes.isNotEmpty ? capture.barcodes.first : null;

    final String code = barcode?.rawValue?.trim() ?? '';

    if (code.isEmpty) return;

    debugPrint('Scanned QR raw value: [$code]');

    String normalizedCode = code.toLowerCase().trim();

    normalizedCode = normalizedCode.replaceAll(' ', '');
    normalizedCode = normalizedCode.replaceAll('_', '');

    final match = RegExp(r'bike(\d+)').firstMatch(normalizedCode);
    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid bike QR code: $code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    normalizedCode = 'bike${match.group(1)}';

    setState(() {
      _isScanned = true;
    });

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        size: 38,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'QR Code Scanned',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to unlock this bike?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SelectableText(
                        normalizedCode,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUnlocking
                            ? null
                            : () async {
                          setDialogState(() {
                            _isUnlocking = true;
                          });

                          try {
                            final result =
                            await unlockBike(normalizedCode);

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            if (result == 'already_unlocked') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Bike ${normalizedCode.replaceAll('bike', '')} is already unlocked',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );

                              setState(() {
                                _isScanned = false;
                                _isUnlocking = false;
                              });
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Bike ${normalizedCode.replaceAll('bike', '')} unlocked 🚲',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );

                            setState(() {
                              _isUnlocking = false;
                            });

                            Navigator.pop(this.context, normalizedCode);
                          } catch (e) {
                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to unlock bike: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );

                            setState(() {
                              _isScanned = false;
                              _isUnlocking = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7ED957),
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isUnlocking
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                            : const Text(
                          'Unlock Bike',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isUnlocking
                            ? null
                            : () {
                          Navigator.pop(dialogContext);
                          if (mounted) {
                            setState(() {
                              _isScanned = false;
                            });
                          }
                        },
                        child: const Text(
                          'Scan Again',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
                        'Scan to Unlock',
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
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