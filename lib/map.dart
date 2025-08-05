import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rehabspace/settings.dart';
import 'homedash.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final LatLng _center = const LatLng(1.3521, 103.8198);
  final Set<Marker> _markers = {};
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchMarkers();
  }

  Future<void> _fetchMarkers() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('maplocations').get();

    final newMarkers =
        snapshot.docs.map((doc) {
          final data = doc.data();
          final lat = double.tryParse(data['latitude'] ?? '') ?? 0;
          final lng = double.tryParse(data['longitude'] ?? '') ?? 0;

          return Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: data['name'] ?? 'Unknown Clinic',
              snippet: data['address'] ?? 'No Address',
            ),
            onTap:
                () => _mapController.animateCamera(
                  CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
                ),
          );
        }).toSet();

    setState(() => _markers.addAll(newMarkers));
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeDash()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Clinic Locator")),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(target: _center, zoom: 11.5),
        markers: _markers,
        myLocationEnabled: true,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 9, 95, 255),
        unselectedItemColor: Colors.grey,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
