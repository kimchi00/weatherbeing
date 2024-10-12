import 'package:flutter/material.dart';
import 'package:weatherbeing/checklist.dart';
import 'package:weatherbeing/healthmodule.dart';
import 'package:weatherbeing/userprofile.dart';
import 'package:weatherbeing/weather_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'algo.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _forecast = [];
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  final String apiKey = 'knHUUCmBDDA1VdfVcjTaFTFFm51t2QVn';

 final Map<int, String> weatherDescriptions = {
    0: "Unknown",
    10000: "Clear, Sunny",
    11000: "Mostly Clear",
    11010: "Partly Cloudy",
    11020: "Mostly Cloudy",
    10010: "Cloudy",
    11030: "Partly Cloudy and Mostly Clear",
    21000: "Light Fog",
    21010: "Mostly Clear and Light Fog",
    21020: "Partly Cloudy and Light Fog",
    21030: "Mostly Cloudy and Light Fog",
    21060: "Mostly Clear and Fog",
    21070: "Partly Cloudy and Fog",
    21080: "Mostly Cloudy and Fog",
    20000: "Fog",
    42040: "Partly Cloudy and Drizzle",
    42030: "Mostly Clear and Drizzle",
    42050: "Mostly Cloudy and Drizzle",
    40000: "Drizzle",
    42000: "Light Rain",
    42130: "Mostly Clear and Light Rain",
    42140: "Partly Cloudy and Light Rain",
    42150: "Mostly Cloudy and Light Rain",
    42090: "Mostly Clear and Rain",
    42080: "Partly Cloudy and Rain",
    42100: "Mostly Cloudy and Rain",
    40010: "Rain",
    42110: "Mostly Clear and Heavy Rain",
    42020: "Partly Cloudy and Heavy Rain",
    42120: "Mostly Cloudy and Heavy Rain",
    42010: "Heavy Rain",
  };

    // Define a method to handle the navigation
  void _onItemTapped(int index) {
    setState(() {
    });

    // Check if the Health tab is tapped
    if (index == 1) {
      // Navigate to HealthModule when Health is selected
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HealthModule()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChecklistPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserProfile()),
      );
    }
  }


  @override
  void initState() {
    super.initState();
    _loadWeather();
    _fetchWeather();
  }
   Future<void> _fetchWeather() async {
    // Hardcoded coordinates: 13.6218° N, 123.1948° E
    final lat = 13.6218;
    final lon = 123.1948;

    final url = Uri.parse(
        'https://api.tomorrow.io/v4/timelines?location=$lat,$lon&fields=weatherCodeDay&timesteps=1d&units=metric&apikey=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final weatherData = json.decode(response.body);
      final intervals = weatherData['data']['timelines'][0]['intervals'];

      setState(() {
        _forecast = intervals.take(5).toList(); // Taking the next 5 days
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load weather data');
    }
  }

    String formatDate(String dateString) {
    // Parsing the date string to DateTime object and then formatting it.
    DateTime date = DateTime.parse(dateString);
    return DateFormat('EEE').format(date); // Example: Mon, Tue, etc.
  }

  String getWeatherDescription(int? weatherCode) {
    if (weatherCode == null || !weatherDescriptions.containsKey(weatherCode)) {
      return weatherDescriptions[0]!;
    }
    return weatherDescriptions[weatherCode]!;
  }

  Future<void> _loadWeather() async {
    try {
      WeatherService weatherService = WeatherService();
      final data = await weatherService.fetchWeather('Naga City'); 
      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Failed to fetch weather: $e');
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
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Weather Overview
                  _buildWeatherOverview(),
                  SizedBox(height: 20),
                  // Lorem Ipsum Box or some other text placeholder
                  _buildLoremIpsumBox(),
                  SizedBox(height: 20),
                  // Forecast section, you can extend this to real forecast data as well
                  _buildScrollableForecast(),
                  SizedBox(height: 20),
                  // Weather Details Grid
                  _buildWeatherDetailsGrid(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildWeatherOverview() {
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

  Widget _buildLoremIpsumBox() {
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
        children: [
          Expanded(
            child: Text(
              'Lorem ipsum dolor sit amet consectetur. Tellus senectus nec enim volutpat nunc.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(width: 10),
          Icon(
            Icons.info_outline,
            color: Colors.blue,
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
          final date = forecast['startTime'];
          final weatherCode = forecast['values']['weatherCodeDay'];

          return _buildForecastCard(
            formatDate(date),
            getWeatherDescription(weatherCode),
            Icons.wb_sunny, // Adjust the icon based on actual weather code
          );
        },
      ),
    );
  }

  Widget _buildWeatherDetailsGrid() {
    return Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _buildDetailCard(
            'UV Index',
            '${weatherData!['current']['uv']}',
            Icons.wb_sunny,
            Colors.amber,
          ),
          _buildDetailCard(
            'Humidity',
            '${weatherData!['current']['humidity']}%',
            Icons.opacity,
            Colors.lightBlueAccent,
          ),
          _buildDetailCard(
            'Wind',
            '${weatherData!['current']['wind_kph']} kph',
            Icons.air,
            Colors.green,
          ),
          _buildDetailCard(
            'Cloud',
            '${weatherData!['current']['cloud']}%',
            Icons.cloud,
            Colors.pinkAccent,
          ),
          _buildDetailCard(
            'Air Quality Index',
            _getAirQualityDescription(weatherData!['current']['air_quality']['us-epa-index']), 
            Icons.air_outlined,
            Colors.purpleAccent,
          ),
          _buildDetailCard(
            'Pressure',
            '${weatherData!['current']['pressure_mb']} hPa',
            Icons.speed,
            Colors.orangeAccent,
          ),
        ],
      ),
    );
  }

  String _getAirQualityDescription(int airQualityIndex) {
  String description = '';

  if (airQualityIndex == 1) {
    description = 'Good';
  } else if (airQualityIndex == 2) {
    description = 'Moderate';
  } else if (airQualityIndex == 3) {
    description = 'Unhealthy for Sensitive Groups';
  } else if (airQualityIndex == 4) {
    description = 'Unhealthy';
  } else if (airQualityIndex == 5) {
    description = 'Very Unhealthy';
  } else if (airQualityIndex == 6) {
    description = 'Hazardous';
  } else {
    description = 'Unknown';
  }

  return '$airQualityIndex ($description)';
}

Widget _buildForecastCard(String day, String weatherDescription, IconData icon) {
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
        Icon(icon, size: 40, color: Colors.grey),
        SizedBox(height: 10),
        AutoSizeText(
          weatherDescription, // Here we use AutoSizeText for weather description
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
          maxLines: 2, // Limit to 2 lines to prevent overflow
          overflow: TextOverflow.ellipsis, // Add ellipsis if text is too long
          minFontSize: 12, // Ensure the text doesn't get too small
        ),
      ],
    ),
  );
}


  Widget _buildDetailCard(String title, String value, IconData icon, Color color) {
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
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.pinkAccent,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      currentIndex: 0,
      onTap: _onItemTapped, // This handles the tap and navigation logic
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
