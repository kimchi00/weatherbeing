import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _forecast = [];
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  final String apiKey = '4f6b2fa02ea341be89850512242909';

  final double defaultLatitude = 13.6210;
  final double defaultLongitude = 123.2008;

  double? lastLatitude;
  double? lastLongitude;

  

  @override
  void initState() {
    super.initState();
    _loadLastKnownLocationWeather();
  }

  Future<void> _loadLastKnownLocationWeather() async {
    // Check if last location is already stored
    if (lastLatitude != null && lastLongitude != null) {
      // Use the last known location
      await _fetchWeather(lastLatitude!, lastLongitude!);
    } else {
      // Check for location services first
      await _checkLocationAndFetchWeather();
    }
  }

  Future<void> _checkLocationAndFetchWeather() async {
    bool serviceEnabled;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      _showLocationError("Failed to check location services: $e");
      return;
    }

    if (!serviceEnabled) {
      // Prompt user to enable location services
      _showPromptToEnableLocation();
    } else {
      _requestLocationPermission();
    }
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationError("Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationError(
          "Location permissions are permanently denied. Please enable them in settings.");
      return;
    }

    // Fetch current location if permissions are granted
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Save the last known location
      lastLatitude = position.latitude;
      lastLongitude = position.longitude;

      // Save location to Firebase
      await _saveLocationToFirebase(lastLatitude!, lastLongitude!);

      // Fetch weather for the current location
      await _fetchWeather(lastLatitude!, lastLongitude!);
    } catch (e) {
      _showLocationError("Failed to get current location: $e");
    }
  }

  Future<void> _saveLocationToFirebase(double latitude, double longitude) async {
    try {
      // Get the currently logged-in user
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print("No user is currently logged in.");
        return;
      }

      String userId = currentUser.uid; // Get the user's unique ID

      CollectionReference users = FirebaseFirestore.instance.collection('users');

      // Update the user's document with the location
      await users.doc(userId).update({
        'lastKnownLocation': {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });

      print("Location updated in Firebase successfully for user: $userId");
    } catch (e) {
      print("Failed to update location in Firebase: $e");
    }
  }





  Future<void> _fetchWeather(double latitude, double longitude) async {
    final url = Uri.parse(
        'https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$latitude,$longitude&days=5&aqi=yes&alerts=no');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final fetchedWeatherData = json.decode(response.body);
        final forecastDays = fetchedWeatherData['forecast']['forecastday'];

        // Save location to Firebase
        await _saveLocationToFirebase(latitude, longitude);

        setState(() {
          weatherData = fetchedWeatherData;
          _forecast = forecastDays;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      _showLocationError("Failed to fetch weather data.");
    }
  }


  void _showPromptToEnableLocation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Enable Location Services"),
        content: Text(
            "Location services are currently off. Please turn them on to determine your real location."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              _checkLocationAndFetchWeather(); // Recheck location services
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }


  void _showLocationError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // Navigation logic

  int _selectedIndex = 0; // Tracks the currently selected tab
  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/health');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/checklist');
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/profile');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo2.png', // Adjust the path as needed
              height: 40,
            ),
            SizedBox(width: 10),
            Text(
              'Weather-Being',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.purple),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildWeatherOverview(),
                  SizedBox(height: 20),
                  _buildScrollableForecast(),
                  SizedBox(height: 20),
                  _buildWeatherDetailsGrid(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  void _showSearchDialog() {
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Search for a Location"),
        content: TextField(
          onChanged: (value) {
            searchQuery = value;
          },
          decoration: InputDecoration(
            hintText: 'Enter location name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog
              if (searchQuery.isNotEmpty) {
                await _fetchWeatherByLocation(searchQuery);
              }
            },
            child: Text("Search"),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchWeatherByLocation(String location) async {
  final url = Uri.parse(
      'https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$location&days=5&aqi=yes&alerts=no');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final fetchedWeatherData = json.decode(response.body);
      final forecastDays = fetchedWeatherData['forecast']['forecastday'];

      setState(() {
        weatherData = fetchedWeatherData;
        _forecast = forecastDays;
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load weather data');
    }
  } catch (e) {
    print('Error fetching weather data: $e');
    _showLocationError("Failed to fetch weather data for the given location.");
  }
}

  Widget _buildWeatherOverview() {
    if (weatherData == null) return Container();
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${weatherData!['current']['temp_c']}°',
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                weatherData!['current']['condition']['text'],
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${weatherData!['location']['name']} 🌍',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${weatherData!['current']['temp_c']}°/${weatherData!['current']['feelslike_c']}° Feels like ${weatherData!['current']['feelslike_c']}°',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Image.network(
            'https:${weatherData!['current']['condition']['icon']}',
            width: 140, // Icon size
            height: 140,
          ),
        ],
      ),
    );
  }



  
  Widget _buildScrollableForecast() {
    return Container(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _forecast.length,
        itemBuilder: (context, index) {
          final forecast = _forecast[index];
          final date = forecast['date'];
          final weatherDescription = forecast['day']['condition']['text'];
          final weatherIcon = forecast['day']['condition']['icon'];

          return _buildForecastCard(
            formatDate(date),
            weatherDescription,
            weatherIcon,
          );
        },
      ),
    );
  }

       String formatDate(String dateString) {
    // Parsing the date string to DateTime object and then formatting it.
    DateTime date = DateTime.parse(dateString);
    return DateFormat('EEE').format(date); // Example: Mon, Tue, etc.
  }

  Widget _buildWeatherDetailsGrid() {
    return Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _buildDetailCardWithPopup(
            'UV Index',
            weatherData?['current']?['uv']?.toString() ?? 'N/A',
            Icons.wb_sunny,
            Colors.amber,
            'UV Index is a measure of the strength of ultraviolet radiation from the sun. A higher value means greater potential for harm to your skin and eyes.',
          ),
          _buildDetailCardWithPopup(
            'Humidity',
            weatherData?['current']?['humidity']?.toString() ?? 'N/A',
            Icons.opacity,
            Colors.lightBlueAccent,
            'Humidity is the amount of water vapor present in the air. High humidity can make the air feel hotter and more uncomfortable.',
          ),
          _buildDetailCardWithPopup(
            'Wind',
            weatherData?['current']?['wind_kph']?.toString() ?? 'N/A',
            Icons.air,
            Colors.green,
            'Wind speed indicates how fast the air is moving. Strong winds can make it feel cooler than the actual temperature.',
          ),
          _buildDetailCardWithPopup(
            'Cloud',
            weatherData?['current']?['cloud']?.toString() ?? 'N/A',
            Icons.cloud,
            Colors.pinkAccent,
            'Cloud cover is the percentage of the sky covered by clouds. More clouds mean less sunlight reaching the ground.',
          ),
          _buildDetailCardWithPopup(
            'Air Quality Index',
            _getAirQualityDescription(weatherData?['current']?['air_quality']?['us-epa-index'] ?? -1),
            Icons.air_outlined,
            Colors.purpleAccent,
            'Air Quality Index (AQI) measures air pollution levels. Lower AQI values indicate cleaner air, while higher values indicate polluted air.',
          ),
          _buildDetailCardWithPopup(
            'Pressure',
            weatherData?['current']?['pressure_mb']?.toString() ?? 'N/A',
            Icons.speed,
            Colors.orangeAccent,
            'Atmospheric pressure is the force exerted by the atmosphere. Changes in pressure can influence weather patterns.',
          ),
        ],
      ),
    );
  }



String _getAirQualityDescription(dynamic airQualityIndex) {
  if (airQualityIndex == null || airQualityIndex < 1 || airQualityIndex > 6) {
    return 'Unknown';
  }

  String description;
  switch (airQualityIndex) {
    case 1:
      description = 'Good';
      break;
    case 2:
      description = 'Moderate';
      break;
    case 3:
      description = 'Unhealthy for Sensitive Groups';
      break;
    case 4:
      description = 'Unhealthy';
      break;
    case 5:
      description = 'Very Unhealthy';
      break;
    case 6:
      description = 'Hazardous';
      break;
    default:
      description = 'Unknown';
  }
  return '$airQualityIndex ($description)';
}


  Widget _buildDetailCardWithPopup(
      String title, String value, IconData icon, Color color, String explanation) {
    return GestureDetector(
      onTap: () {
        _showExplanationPopup(title, explanation);
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showExplanationPopup(String title, String explanation) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(explanation),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildForecastCard(String day, String weatherDescription, String weatherIcon) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 10),
          Image.network('https:$weatherIcon', width: 40, height: 40),
          SizedBox(height: 10),
          AutoSizeText(
            weatherDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            minFontSize: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.pinkAccent,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      currentIndex: _selectedIndex, // Dynamically updates the selected tab
      onTap: _onItemTapped, // Handles navigation and tab selection
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Health',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle),
          label: 'Checklist',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

