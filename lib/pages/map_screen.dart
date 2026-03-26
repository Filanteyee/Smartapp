import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFFF9793D);
  static const Color _green = Color(0xFF35C84A);

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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _goToMyLocation() async {
    if (!await _requestLocationPermission()) return;
    final pos = await Geolocator.getCurrentPosition();
    mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 16),
    ));
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
        mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: 16)));
        await _setAddressFromPosition(pos);
      }
    } catch (_) {}
  }

  Future<void> _setAddressFromPosition(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isEmpty) return;
      final placemark = placemarks.first;

      final street = [placemark.street, placemark.subThoroughfare]
          .where((e) => e != null && e.trim().isNotEmpty)
          .join(' ')
          .trim();
      final city = [placemark.locality, placemark.subAdministrativeArea, placemark.administrativeArea]
          .where((e) => e != null && e.trim().isNotEmpty)
          .join(', ')
          .trim();
      final fullAddr = [street, city].where((e) => e.isNotEmpty).join(', ');

      setState(() {
        _selectedAddress = fullAddr;
        _selectedCity = placemark.locality?.trim().isNotEmpty == true ? placemark.locality!.trim() : (placemark.administrativeArea ?? '');
        _selectedStreet = street;
        _markers = {
          Marker(markerId: const MarkerId('selected_address'), position: position, infoWindow: InfoWindow(title: fullAddr)),
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

  Future<void> _onMapTapped(LatLng position) async => _setAddressFromPosition(position);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _accent,
        title: const Text('Выбор адреса'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: CameraPosition(target: _initialCenter, zoom: _currentZoom),
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
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Введите адрес...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _searchByAddress,
                      style: ElevatedButton.styleFrom(backgroundColor: _accent),
                      child: const Icon(Icons.search, color: Colors.white),
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
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _selectedAddress!,
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: ElevatedButton(
              onPressed: _confirmAddress,
              style: ElevatedButton.styleFrom(backgroundColor: _green, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Выбрать адрес', style: TextStyle(color: Colors.white)),
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
              FloatingActionButton(heroTag: 'btn1', onPressed: _zoomIn, mini: true, backgroundColor: _accent, child: const Icon(Icons.zoom_in)),
              const SizedBox(height: 8),
              FloatingActionButton(heroTag: 'btn2', onPressed: _zoomOut, mini: true, backgroundColor: _accent, child: const Icon(Icons.zoom_out)),
              const SizedBox(height: 8),
              FloatingActionButton(heroTag: 'btn3', onPressed: _goToMyLocation, backgroundColor: _green, child: const Icon(Icons.my_location)),
            ],
          ),
        ),
      ),
    );
  }
}