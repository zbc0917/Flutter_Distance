import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Location & Map App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

/*
* Location Service Class used to get the location with Geolocator.
*/

class LocationService {
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
}


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  
  LatLng? _currentPosition;     // Current Location  
  LatLng? _selectedCityPosition;    // Selected City 
  String _locationMessage = 'Click "Get Location"';      
  String _selectedCityMessage = "None City Selected";   
  LatLng _defaultLocation = LatLng(40.7128, -74.0060); // New York, Default City for the Map View
  String? _selectedCity;  //City Name Select
  double? _distance;  // Distance 


  // Dropdown Map 'CITY NAME': [Lat, Long]
  final Map<String, List<double>> cities = {
    'New York': [40.7128, -74.0060],
    'Chicago': [41.8781, -87.6298],
    'Singapore': [1.3521, 103.8198],
    'Paris': [48.8566, 2.3522],
  };

  // HELP FUNCTION PART  
  Future<void> _getUserLocation() async {
    try {
      Position? position = await _locationService.getCurrentLocation();

      if (position != null) {
        // Update the map position
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _locationMessage = 'Your Location: Lat: ${position.latitude}, Long: ${position.longitude}';
          _mapController.move(_currentPosition!, 13.0);
        });

      } else {
        setState(() {
          _locationMessage = 'Failed to get location';
        });
      }
    } catch (e) {
      setState(() {
        _locationMessage = 'Error: $e';
      });
    }
  }

  void _onCitySelected(String? newValue) {
    setState(() {
      _selectedCity = newValue;
      if (newValue != null) {
        final coordinates = cities[newValue];
        _selectedCityPosition = LatLng(coordinates![0], coordinates[1]);
        _selectedCityMessage = 'Selected City: $newValue\nLatitude: ${coordinates![0]}, Longitude: ${coordinates[1]}';
      } else {
        _selectedCityMessage = 'No city selected';
      }
    });
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0; // Earth's radius in kilometers

    // Convert degrees to radians
    double toRadians(double degree) => degree * pi / 180.0;

    double dLat = toRadians(lat2 - lat1);
    double dLon = toRadians(lon2 - lon1);

    double a = pow(sin(dLat / 2), 2) +
        cos(toRadians(lat1)) * cos(toRadians(lat2)) * pow(sin(dLon / 2), 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Distance Calculator APP')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.3,
              width: MediaQuery.of(context).size.width * 0.8,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition ?? _defaultLocation,
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.app',
                  ),
                  if (_currentPosition != null)  //Mark current City 
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  if (_selectedCityPosition != null) //Mark selected City 
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedCityPosition!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            //Get Location Part
            ElevatedButton(       
              onPressed: _getUserLocation,
              child: const Text('Get Current Location'),
            ),
            const SizedBox(height: 20),
            Text(
              _locationMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            //Select City Part 
            DropdownButton<String>(     
              value: _selectedCity,
              hint: const Text('Select a city'),
              items:  cities.keys.map((String city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCity = newValue;
                });
                _onCitySelected(newValue);
              },
            ),
            const SizedBox(height: 20),
            Text(
              _selectedCityMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            //Calculate Distance Part
            ElevatedButton(     
              onPressed: (_currentPosition != null && _selectedCity != null)
                  ? () {
                      double distance = calculateDistance(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      _selectedCityPosition!.latitude,
                      _selectedCityPosition!.longitude,
                    );

                    setState(() {
                      _distance = distance;
                    });

                    _mapController.move(
                      LatLng(
                        (_currentPosition!.latitude + cities[_selectedCity]![0]) / 2,
                        (_currentPosition!.longitude + cities[_selectedCity]![1]) / 2,
                      ),
                      3.0,
                    );
                  }
                  : null, // Disable button if currentPosition is null
              child: const Text('Get Current Location'),
            ),
            const SizedBox(height: 20),
            Text(
              "Distance: ${_distance}km",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}



