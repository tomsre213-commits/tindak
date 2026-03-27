import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tindak/pages/auth/login_page.dart';
import 'package:geolocator/geolocator.dart';

import 'package:tindak/pages/topup/topup_page.dart';
import 'package:tindak/pages/history/history_page.dart';
import 'package:tindak/pages/safety/safety_center_page.dart';
import 'package:tindak/pages/help/help_page.dart';
import 'package:tindak/pages/settings/settings_page.dart';
import 'package:tindak/pages/scan/scan_page.dart';

import 'package:tindak/pages/rent_bike/manage_bike_page.dart';
import 'package:tindak/pages/rent_bike/rental_history_page.dart';
import 'package:tindak/pages/rent_bike/earnings_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const LatLng _defaultCenter = LatLng(8.2280, 124.2452);

  LatLng _currentCenter = _defaultCenter;
  bool _locationEnabled = false;
  bool _notificationsGranted = false;

  Timer? _reserveTimer;
  String? _reservedBikeId;
  int _reserveSecondsLeft = 0;

  Set<Marker> _markers = {};

  final DatabaseReference _bikesRef =
  FirebaseDatabase.instance.ref().child('bikes');

  StreamSubscription<DatabaseEvent>? _bikesSubscription;
  bool _hasMovedToBikeOnce = false;

  BitmapDescriptor? _greenBikeIcon;
  BitmapDescriptor? _redBikeIcon;
  BitmapDescriptor? _blueBikeIcon;

  void _startReserveTimer(String bikeId, VoidCallback? onTick) {
    _reserveTimer?.cancel();

    setState(() {
      _reservedBikeId = bikeId;
      _reserveSecondsLeft = 120;
    });

    onTick?.call();

    _reserveTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_reserveSecondsLeft <= 1) {
        timer.cancel();

        await _bikesRef.child(bikeId).update({
          'padlock': 'locked',
          'reserveUntil': 0,
        });

        if (!mounted) return;

        setState(() {
          _reservedBikeId = null;
          _reserveSecondsLeft = 0;
        });

        onTick?.call();
      } else {
        if (!mounted) return;

        setState(() {
          _reserveSecondsLeft--;
        });

        onTick?.call();
      }
    });
  }

  Future<void> _cancelReserve() async {
    _reserveTimer?.cancel();

    final bikeId = _reservedBikeId;

    setState(() {
      _reservedBikeId = null;
      _reserveSecondsLeft = 0;
    });

    if (bikeId != null) {
      await _bikesRef.child(bikeId).update({
        'padlock': 'locked',
        'reserveUntil': 0,
      });
    }
  }
  String _formatReserveTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _listenToBikeMarkers() {
    _bikesSubscription?.cancel();

    _bikesSubscription = _bikesRef.onValue.listen((event) async {
      try {
        final snapshot = event.snapshot;

        if (!snapshot.exists) {
          if (mounted) {
            setState(() {
              _markers = {};
            });
          }
          return;
        }

        final raw = snapshot.value;
        if (raw is! Map) return;

        final data = Map<dynamic, dynamic>.from(raw);
        final Set<Marker> loadedMarkers = {};
        LatLng? firstBikePosition;

        data.forEach((key, value) {
          if (value is Map) {
            final mapValue = Map<dynamic, dynamic>.from(value);
            final lat = double.tryParse(mapValue['latitude'].toString());
            final lng = double.tryParse(mapValue['longitude'].toString());

            final padlock = mapValue['padlock']?.toString().toLowerCase() ?? 'locked';

            final icon = (padlock == 'unlocked')
                ? (_redBikeIcon ?? BitmapDescriptor.defaultMarker)
                : (padlock == 'reserve')
                    ? (_blueBikeIcon ?? BitmapDescriptor.defaultMarker)
                    : (_greenBikeIcon ?? BitmapDescriptor.defaultMarker);

            if (lat != null && lng != null) {
              final bikeId = key.toString();

              final bikePosition = LatLng(lat, lng);
              firstBikePosition ??= bikePosition;

              loadedMarkers.add(
                Marker(
                  markerId: MarkerId(bikeId),
                  position: bikePosition,
                  infoWindow: InfoWindow(
                    title: 'Bike ${bikeId.replaceAll('bike', '')}',
                  ),
                  icon: icon,
                  onTap: () => _showBikeDetailsSheet(
                    bikeId: bikeId,
                    bikeName: 'Bike ${bikeId.replaceAll('bike', '').padLeft(3, '0')}',
                    priceText: '10 php to start, then 5 php/min',
                    padlockStatus: padlock,
                  ),
                ),
              );
            }
          }
        });

        if (!mounted) return;

        setState(() {
          _markers = loadedMarkers;
        });

        if (!_hasMovedToBikeOnce && firstBikePosition != null) {
          _hasMovedToBikeOnce = true;
          _currentCenter = firstBikePosition!;
          await _moveCamera(firstBikePosition!);
        }
      } catch (e) {
        debugPrint('Error listening to bike markers: $e');
      }
    });
  }

  void _showBikeDetailsSheet({
    required String bikeId,
    required String bikeName,
    required String priceText,
    required String padlockStatus,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final bool isInUse = padlockStatus == 'unlocked';
            final bool isReserved =
                padlockStatus == 'reserve' ||
                    (!isInUse && _reservedBikeId == bikeId && _reserveSecondsLeft > 0);

            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF6F4F7),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 18),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bikeName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.pedal_bike_outlined,
                                      size: 16,
                                      color: Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        priceText,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    if (isInUse)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'In Use',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      )
                                    else if (isReserved)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8BE08E),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _formatReserveTime(_reserveSecondsLeft),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 18),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          if (isReserved) ...[
                            _actionChip(
                              icon: Icons.cancel_outlined,
                              label: 'Cancel',
                              iconColor: Colors.red, // 🔴 this makes it red
                              onTap: () async {
                                await _cancelReserve();
                                modalSetState(() {});
                              },
                            ),
                            const SizedBox(width: 10),
                          ],
                          _actionChip(
                            icon: Icons.notifications_none,
                            label: 'Ring',
                            onTap: () {},
                          ),
                          const SizedBox(width: 10),
                          _actionChip(
                            icon: Icons.report_gmailerrorred_outlined,
                            label: 'Report Issue',
                            onTap: () {},
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'PAYMENT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Apple Pay',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      Column(
                        children: [
                          const Icon(
                            Icons.public,
                            size: 48,
                            color: Color(0xFF8BE08E),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Thank you for riding Tindak\nLet\'s create a carbon-free future together',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isInUse
                              ? null
                              : () async {
                            if (isReserved) {
                              Navigator.pop(context);

                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ScanPage(),
                                ),
                              );

                              if (!mounted) return;

                              if (result != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Scanned: $result')),
                                );
                              }
                            } else {
                              await _reserveBike(
                                bikeId,
                                onTick: () {
                                  modalSetState(() {});
                                },
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInUse
                                ? Colors.red.shade300
                                : const Color(0xFF8BE08E),
                            foregroundColor: Colors.black87,
                            disabledBackgroundColor: Colors.red.shade300,
                            disabledForegroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isInUse
                                    ? 'In Use'
                                    : (isReserved ? 'Scan to ride' : 'Reserve'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              // Text(
                              //   isInUse
                              //       ? 'This bike is currently being used'
                              //       : (isReserved
                              //       ? _formatReserveTime(_reserveSecondsLeft)
                              //       : 'Free for 2 minutes'),
                              //   style: TextStyle(
                              //     fontSize: 11,
                              //     color: Colors.black.withOpacity(0.7),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _currentZoom = 17.0;

  final Set<Polygon> _msuIitPolygons = {
    const Polygon(
      polygonId: PolygonId('msu_iit_zone'),
      points: [
        LatLng(8.2440, 124.2430),
        LatLng(8.2440, 124.2431),
        LatLng(8.2437, 124.2433),
        LatLng(8.2435, 124.2433),
        LatLng(8.2430, 124.2439),
        LatLng(8.2432, 124.2441),
        LatLng(8.2431, 124.2442),
        LatLng(8.2431, 124.2443),
        LatLng(8.2431, 124.2444),
        LatLng(8.2431, 124.2445),
        LatLng(8.2422, 124.2443),
        LatLng(8.2419, 124.2449),
        LatLng(8.2401, 124.2446),
        LatLng(8.2399, 124.2448),
        LatLng(8.2399, 124.2449),
        LatLng(8.2394, 124.2445),
        LatLng(8.2391, 124.2443),
        LatLng(8.2394, 124.2434),
        LatLng(8.2395, 124.2430),
        LatLng(8.2400, 124.2430),
        LatLng(8.2399, 124.2428),
        LatLng(8.2400, 124.2426),
        LatLng(8.2407, 124.2427),
        LatLng(8.2410, 124.2430),
        LatLng(8.2418, 124.2432),
        LatLng(8.2418, 124.2430),
        LatLng(8.2422, 124.2430),
        LatLng(8.2423, 124.2426),
        LatLng(8.2423, 124.2421),
        LatLng(8.2430, 124.2422),
        LatLng(8.2430, 124.2424),
        LatLng(8.2435, 124.2426),
      ],
      strokeWidth: 2,
      strokeColor: Color(0xFF32CD32),
      fillColor: Color(0x4432CD32),
    ),
  };

  Set<Polygon> get _visiblePolygons {
    if (_currentZoom >= 18.0) {
      return {};
    }
    return _msuIitPolygons;
  }

  @override
  void initState() {
    super.initState();
    _loadBikeIcon();
    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    await _handleLocationPermission();
    await _handleNotificationPermission();
  }

  Future<void> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;
      await _showLocationServiceDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      await _showLocationPermissionDialog();
      return;
    }

    final position = await Geolocator.getCurrentPosition();

    _locationEnabled = true;
    _currentCenter = LatLng(position.latitude, position.longitude);

    if (mounted) {
      setState(() {});
      _moveCamera(_currentCenter);
    }
  }

  Future<void> _refreshCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;
        await _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        await _showLocationPermissionDialog();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newCenter = LatLng(position.latitude, position.longitude);

      setState(() {
        _locationEnabled = true;
        _currentCenter = newCenter;
      });

      await _moveCamera(newCenter);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get current location')),
      );
    }
  }

  Future<void> _handleNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    _notificationsGranted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _moveCamera(LatLng target) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 17),
      ),
    );
  }

  Future<void> _showLocationServiceDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Turn on location'),
          content: const Text(
            'Tindak needs location services to look for bikes near you and track your ride.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Not now"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Geolocator.openLocationSettings();
              },
              child: const Text("Open settings"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLocationPermissionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Allow location access'),
          content: const Text(
            'Tindak uses your location to look for bikes near you and track your ride.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Don't allow"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              child: const Text("Open app settings"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.popUntil(context, (route) => route.isFirst);

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
          (route) => false,
    );
  }

  Future<void> _onScanPressed() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanPage(),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanned: $result')),
      );
    }
  }

  Future<void> _loadBikeIcon() async {
    try {
      _greenBikeIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/green_bike_marker.png',
      );

      _redBikeIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/red_bike_marker.png',
      );

      _blueBikeIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/blue_bike_marker.png',
      );

      debugPrint('Bike marker icons loaded successfully');
    } catch (e) {
      debugPrint('Failed to load bike marker asset: $e');
      _greenBikeIcon = BitmapDescriptor.defaultMarker;
      _redBikeIcon = BitmapDescriptor.defaultMarker;
      _blueBikeIcon = BitmapDescriptor.defaultMarker;
    }

    _listenToBikeMarkers();
  }

  Future<void> _reserveBike(String bikeId, {VoidCallback? onTick}) async {
    final ref = _bikesRef.child(bikeId);

    final snapshot = await ref.get();
    if (!snapshot.exists) return;

    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    final padlock = (data['padlock'] ?? 'locked').toString().toLowerCase();

    if (padlock == 'unlocked' || padlock == 'reserve') {
      return;
    }

    final reserveUntil =
        DateTime.now().millisecondsSinceEpoch + (2 * 60 * 1000);

    await ref.update({
      'padlock': 'reserve',
      'reserveUntil': reserveUntil,
    });

    _startReserveTimer(bikeId, onTick);
  }

  String _getDisplayName(User? user) {
    if (user == null) return 'User';

    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    }

    if (user.email != null && user.email!.trim().isNotEmpty) {
      return user.email!.split('@').first;
    }

    return 'User';
  }
  void _openPage(Widget page) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }
  Widget _rentActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(icon, color: Colors.grey.shade600),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black54,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Colors.grey,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: Colors.grey.shade300,
          ),
      ],
    );
  }
  void _showRentMyBikeSheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Rent",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(top: 10, left: 12, right: 12),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F4F7),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // HEADER
                    Row(
                      children: [
                        const Spacer(),
                        const Text(
                          'Rent My Bike',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ICON
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDFF4D8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pedal_bike,
                        size: 70,
                        color: Color(0xFF62C95A),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Rent your bike and gain passive\nincome while in campus',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Enter the device code below to register',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const TextField(
                              decoration: InputDecoration(
                                hintText: 'Enter Device Code',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8BE08E),
                              foregroundColor: Colors.black87,
                              elevation: 0,
                            ),
                            child: const Text('Register'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          _rentActionItem(
                            icon: Icons.settings_outlined,
                            title: 'Manage Bike',
                            onTap: () => _openModalPage(const ManageBikePage()),
                          ),
                          _rentActionItem(
                            icon: Icons.history,
                            title: 'Rental History',
                            onTap: () => _openModalPage(const RentalHistoryPage()),
                          ),
                          _rentActionItem(
                            icon: Icons.payments_outlined,
                            title: 'Earnings',
                            onTap: () => _openModalPage(const EarningsPage()),
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },

      // 🔥 THIS CONTROLS ANIMATION (TOP SLIDE)
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(
          begin: const Offset(0, -1), // from top
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOut));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  void _openModalPage(Widget page) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.black,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  void dispose() {
    _reserveTimer?.cancel();
    _bikesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _getDisplayName(user);

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Hi $displayName',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (user?.email != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    user!.email!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _statItem(
                        icon: Icons.alt_route,
                        value: '0',
                        label: 'kilometers',
                      ),
                    ),
                    Expanded(
                      child: _statItem(
                        icon: Icons.pedal_bike,
                        value: '0',
                        label: 'Rides',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _drawerItem(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Top up',
                onTap: () => _openPage(const TopUpPage()),
              ),
              _drawerItem(
                icon: Icons.pedal_bike_outlined,
                title: 'Rent My Bike',
                onTap: () {
                  Navigator.pop(context);
                  _showRentMyBikeSheet();
                },
              ),
              _drawerItem(
                icon: Icons.history,
                title: 'History',
                onTap: () => _openPage(const HistoryPage()),
              ),
              _drawerItem(
                icon: Icons.shield_outlined,
                title: 'Safety Center',
                onTap: () => _openPage(const SafetyCenterPage()),
              ),
              _drawerItem(
                icon: Icons.help_outline,
                title: 'Help',
                onTap: () => _openPage(const HelpPage()),
              ),
              _drawerItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () => _openPage(const SettingsPage()),
              ),
              _drawerItem(
                icon: Icons.logout,
                title: 'Logout',
                onTap: () => _logout(context),
              ),
              const Spacer(),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Tindak v3.213.0 (1)',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentCenter,
              zoom: 17,
            ),
            myLocationEnabled: _locationEnabled,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            polygons: _visiblePolygons,
            onCameraMove: (position) {
              if (_currentZoom != position.zoom) {
                setState(() {
                  _currentZoom = position.zoom;
                });
              }
            },
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _roundMapButton(
                    icon: Icons.person_outline,
                    onTap: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 22,
            right: 20,
            child: SafeArea(
              child: GestureDetector(
                onTap: _showRentMyBikeSheet,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'RENT',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 130,
            child: _roundMapButton(
              icon: Icons.navigation_outlined,
              onTap: _refreshCurrentLocation,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 36,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: _onScanPressed,
                    icon: const Icon(Icons.center_focus_strong),
                    label: const Text('Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8BE08E),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
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

  Widget _roundMapButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.95),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.black54, size: 24),
        ),
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15),
      ),
      onTap: onTap,
    );
  }
}