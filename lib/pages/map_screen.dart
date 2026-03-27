import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? mapController;

  LatLng _initialCenter = const LatLng(51.1694, 71.4491);
  double _currentZoom = 14.0;

  Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();

  String? _selectedAddress;
  String? _selectedCity;
  String? _selectedStreet;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _goToMyLocation() async {
    if (!await _requestLocationPermission()) return;

    final pos = await Geolocator.getCurrentPosition();

    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(pos.latitude, pos.longitude),
          zoom: 16,
        ),
      ),
    );
  }

  void _zoomIn() => mapController?.animateCamera(CameraUpdate.zoomIn());
  void _zoomOut() => mapController?.animateCamera(CameraUpdate.zoomOut());

  Future<void> _searchByAddress() async {
    final addr = _searchController.text.trim();
    if (addr.isEmpty) return;

    try {
      final locs = await locationFromAddress(addr);

      if (locs.isNotEmpty) {
        final pos = LatLng(locs.first.latitude, locs.first.longitude);

        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: pos, zoom: 16),
          ),
        );

        await _setAddressFromPosition(pos);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Адрес не найден')),
      );
    }
  }

  Future<void> _setAddressFromPosition(LatLng position) async {
    try {
      final placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isEmpty) return;

      final placemark = placemarks.first;

      final street = [
        placemark.street,
        placemark.subThoroughfare,
      ].where((e) => e != null && e.trim().isNotEmpty).join(' ').trim();

      final city = [
        placemark.locality,
        placemark.subAdministrativeArea,
        placemark.administrativeArea,
      ].where((e) => e != null && e.trim().isNotEmpty).join(', ').trim();

      final fullAddr = [street, city].where((e) => e.isNotEmpty).join(', ');

      setState(() {
        _selectedAddress = fullAddr;
        _selectedCity = placemark.locality?.trim().isNotEmpty == true
            ? placemark.locality!.trim()
            : (placemark.administrativeArea ?? '');
        _selectedStreet = street;

        _markers = {
          Marker(
            markerId: const MarkerId('selected_address'),
            position: position,
            infoWindow: InfoWindow(title: fullAddr),
          ),
        };
      });
    } catch (_) {}
  }

  void _confirmAddress() {
    if (_selectedAddress == null || _selectedAddress!.isEmpty) return;

    Navigator.pop(context, {
      'address': _selectedAddress,
      'city': _selectedCity ?? '',
      'street': _selectedStreet ?? '',
    });
  }

  Future<void> _onMapTapped(LatLng position) async {
    await _setAddressFromPosition(position);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор адреса'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _initialCenter,
              zoom: _currentZoom,
            ),
            markers: _markers,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            onTap: _onMapTapped,
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(16),
                        color: colors.surface,
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Введите адрес...',
                            hintStyle: TextStyle(
                              color: colors.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: colors.primary,
                                width: 1.4,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      width: 56,
                      child: FilledButton(
                        onPressed: _searchByAddress,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Icon(Icons.search),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_selectedAddress != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 96,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _selectedAddress!,
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: FilledButton(
              onPressed: _confirmAddress,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: const Text('Выбрать адрес'),
            ),
          ),
        ],
      ),
      floatingActionButton: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'btn1',
                onPressed: _zoomIn,
                mini: true,
                child: const Icon(Icons.zoom_in),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'btn2',
                onPressed: _zoomOut,
                mini: true,
                child: const Icon(Icons.zoom_out),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'btn3',
                onPressed: _goToMyLocation,
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
      ),
    );
  }
}