import 'package:flutter/material.dart';
import 'package:weatherbeing/checklist.dart';
import 'package:weatherbeing/homepage.dart';
import 'package:weatherbeing/userprofile.dart';
import 'map.dart'; 
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HealthModule extends StatefulWidget {
  @override
  _HealthModuleState createState() => _HealthModuleState();
}

class _HealthModuleState extends State<HealthModule> {

  List<String> _recommendations = ["Fetching recommendations..."]; // List to hold recommendations
  Map<String, double> _likelihoodValues = {}; // Store likelihood values for debugging
  int _currentPage = 0; // Track the current page for swipe navigation

   @override
  void initState() {
    super.initState();
    _evaluateAndPrintResults(); // Call the method to fetch the data and calculate recommendation
  }

////////////////////////////////////////////////////////////////////////
//////////////////// Fetching weather and user data ////////////////////
////////////////////////////////////////////////////////////////////////

    // Fetch the user's BMI from Firestore
  Future<double?> fetchUserBMI() async {
    try {
      User? user = FirebaseAuth.instance.currentUser; // Get the current user
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users') // Assuming your collection is named 'users'
            .doc(user.uid) // Use the logged-in user's UID
            .get();

        if (userDoc.exists) {
          double? bmi = userDoc.get('bmi'); // Assuming BMI is stored as a double
          return bmi;
        }
      }
    } catch (e) {
      print("Error fetching user BMI: $e");
    }
    return null; // Return null if the user or BMI is not found
  }


  final String apiKey = "4f6b2fa02ea341be89850512242909";
  final String location = "Naga City"; // Example: "London"

  Future<Map<String, dynamic>> fetchWeatherData() async {
    final url =
        'http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$location&aqi=yes';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load weather data');
    }
  }

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

  void _onItemTapped(int index) {
    setState(() {
    });

    // Check if the Health tab is tapped
    if (index == 0) {
      // Navigate to HealthModule when Health is selected
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
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

////////////////////////////////////////////////////////////////////////////////////
///////////////////// Fuzzy and Algorithm Logic ////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

  // Define the Fuzzy logic class functions within the widget
  double trapmf(double x, double a, double b, double c, double d) {
    if (x <= a || x >= d) {
      return 0.0; // Outside the range, membership is 0
    } else if (x > a && x <= b) {
      return (x - a) / (b - a); // Rising slope
    } else if (x > b && x <= c) {
      return 1.0; // Flat top, full membership
    } else if (x > c && x < d) {
      return (d - x) / (d - c); // Falling slope
    }
    return 0.0;
  }

    // Function to evaluate BMI based on fuzzy logic
  Map<String, double> evaluateBMI(double bmi) {
    double underweight(double bmi) => trapmf(bmi, 10.0, 10.0, 16.0, 18.5);
    double normalWeight(double bmi) => trapmf(bmi, 18.0, 18.5, 24.9, 25.5);
    double overweight(double bmi) => trapmf(bmi, 24.0, 25.0, 29.9, 30.5);
    double obese(double bmi) => trapmf(bmi, 29.5, 30.0, 40.0, 50.0);

    return {
      "underweight": underweight(bmi),
      "normalWeight": normalWeight(bmi),
      "overweight": overweight(bmi),
      "obese": obese(bmi),
    };
  }

  Map<String, double> evaluateHeatIndex(double heatIndex) {
    double ok(double heatIndex) => trapmf(heatIndex, 20.0, 26.0, 26.0, 30.0);
    double caution(double heatIndex) => trapmf(heatIndex, 26.0, 28.0, 32.0, 34.0);
    double extremeCaution(double heatIndex) => trapmf(heatIndex, 33.0, 35.0, 38.0, 42.0);
    double danger(double heatIndex) => trapmf(heatIndex, 42.0, 45.0, 50.0, 52.0);
    double extremeDanger(double heatIndex) => trapmf(heatIndex, 52.0, 55.0, 55.0, 60.0);

    return {
      "ok": ok(heatIndex),
      "caution": caution(heatIndex),
      "extremeCaution": extremeCaution(heatIndex),
      "danger": danger(heatIndex),
      "extremeDanger": extremeDanger(heatIndex),
    };
  }

  Map<String, double> evaluateUVIndex(double uvIndex) {
    double low(double uvIndex) => trapmf(uvIndex, -10.0, 1.0, 2.0, 4.0);
    double moderate(double uvIndex) => trapmf(uvIndex, 2.0, 3.0, 5.0, 7.0);
    double high(double uvIndex) => trapmf(uvIndex, 5.0, 6.0, 7.0, 8.0);
    double veryHigh(double uvIndex) => trapmf(uvIndex, 7.0, 8.0, 10.0, 11.0);
    double extreme(double uvIndex) => trapmf(uvIndex, 10.0, 11.0, 12.0, 12.0);

    return {
      "low": low(uvIndex),
      "moderate": moderate(uvIndex),
      "high": high(uvIndex),
      "veryHigh": veryHigh(uvIndex),
      "extreme": extreme(uvIndex),
    };
  }

  Map<String, double> evaluateHumidity(double humidity) {
    double low(double humidity) => trapmf(humidity, 10.0, 15.0, 20.0, 30.0);
    double moderate(double humidity) => trapmf(humidity, 25.0, 30.0, 40.0, 60.0);
    double high(double humidity) => trapmf(humidity, 55.0, 60.0, 65.0, 75.0);
    double veryHigh(double humidity) => trapmf(humidity, 75.0, 80.0, 90.0, 200.0);

    return {
      "low": low(humidity),
      "moderate": moderate(humidity),
      "high": high(humidity),
      "veryHigh": veryHigh(humidity),
    };
  }

  Map<String, double> evaluateWeather(double mm) {
    double clear(double mm) => trapmf(mm, -10.0, 0.0, 0.1, 0.5);
    double patchyRain(double mm) =>  trapmf(mm, 0.1, 1.0, 1.9, 3.0);
    double lightRain(double mm) => trapmf(mm, 2.0, 3.0, 4.0, 5.0);
    double moderateRain(double mm) => trapmf(mm, 4.5, 5.0, 6.0, 7.0);
    double strongRain(double mm) => trapmf(mm, 10.0, 15.0, 20.0, 25.0);
    double rainfall(double mm) => trapmf(mm, 25.0, 30.0, 30.0, 35.0);

    return {
      "clear": clear(mm),
      "patchyRain": patchyRain(mm),
      "lightRain": lightRain(mm),
      "moderateRain": moderateRain(mm),
      "strongRain": strongRain(mm),
      "rainfall": rainfall(mm),
    };
  }

  Map<String, double> evaluateAQICategory(double aqi) {
    // Fuzzy membership values for AQI
    double good(double aqi) => trapmf(aqi, -10.0, 1.0, 1.5, 2.0);
    double moderate(double aqi) => trapmf(aqi, 1.5, 2.0, 2.5, 3.0);
    double unhealthyForSensitive(double aqi) => trapmf(aqi, 2.5, 3.0, 3.5, 4.0);
    double unhealthy(double aqi) => trapmf(aqi, 3.5, 4.0, 4.5, 5.0);
    double veryUnhealthy(double aqi) => trapmf(aqi, 4.5, 5.0, 5.5, 6.0);
    double hazardous(double aqi) => trapmf(aqi, 5.5, 6.0, 6.0, 6.5);

    // Return the fuzzy membership values for AQI
    return {
      "good": good(aqi),
      "moderate": moderate(aqi),
      "unhealthyForSensitive": unhealthyForSensitive(aqi),
      "unhealthy": unhealthy(aqi),
      "veryUnhealthy": veryUnhealthy(aqi),
      "hazardous": hazardous(aqi),
    };
  }

  void _evaluateAndPrintResults() async {
    try {
      // Fetch the real-time weather data
      Map<String, dynamic> weatherData = await fetchWeatherData();

      // Extract the relevant values
      double heatIndex = weatherData['current']['feelslike_c'];
      double uvIndex = weatherData['current']['uv'];
      double humidity = weatherData['current']['humidity'].toDouble();
      double precipitationMM = weatherData['current']['precip_mm'];
      double aqi = weatherData['current']['air_quality']['us-epa-index'].toDouble();

      // Generate multiple recommendations
      List<String> recommendations = generateAsthmaRecommendations(
        evaluateWeather(precipitationMM), 
        evaluateHeatIndex(heatIndex), 
        evaluateUVIndex(uvIndex), 
        evaluateAQICategory(aqi), 
        evaluateHumidity(humidity)
      );

      // If no recommendations pass the threshold, show a default message
      setState(() {
        if (recommendations.isEmpty) {
          _recommendations = ["No specific recommendations for today."];
        } else {
          _recommendations = recommendations;
        }
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        _recommendations = ["Error fetching recommendations."];
      });
    }
  }


///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
/////////////// Displaying algo ///////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
///
  // Function to generate recommendations and store likelihoods for debugging
    List<String> generateAsthmaRecommendations(
      Map<String, double> weatherResults,
      Map<String, double> heatIndexResults,
      Map<String, double> uvIndexResults,
      Map<String, double> aqiResults,
      Map<String, double> humidityResults
    ) {
      List<String> validRecommendations = [];
      _likelihoodValues.clear(); // Clear previous likelihood values

      // Recommendation 1
      Map<String, double> weights1 = {
        "clearWeather": 0.7,
        "heatIndexOK": 0.7,
        "uvIndexOK": 0.7,
        "aqiGood": 0.1,
        "humidityOK": 0.1
      };
      double likelihood1 = calculateRecommendationLikelihood({
        "clearWeather": weatherResults["clear"] ?? 0.0,
        "heatIndexOK": heatIndexResults["ok"] ?? 0.0,
        "uvIndexOK": uvIndexResults["low"] ?? 0.0,
        "aqiGood": aqiResults["good"] ?? 0.0,
        "humidityOK": humidityResults["low"] ?? 0.0,
      }, weights1);

      _likelihoodValues['Recommendation 1'] = likelihood1; // Store for debugging

      const double threshold1 = 0.7;
      if (likelihood1 > threshold1) {
        validRecommendations.add(
          "Hello, 'User'! The air quality and humidity are good today. "
          "People are likely to be outside today. Take precautions in areas with fur or smoke, as they are asthma triggers!"
        );
      }

      // Recommendation 2
      Map<String, double> weights2 = {
         "clearWeather": 0.7,
        "heatIndexOK": 0.7,
        "uvIndexOK": 0.7,
        "aqiGood": 0.1,
        "humidityOK": 0.1,
        "lightRain": 0.7,
        "humidityHigh": 0.3
      };
      double likelihood2 = calculateRecommendationLikelihood({
        "clearWeather": weatherResults["clear"] ?? 0.0,
        "heatIndexOK": heatIndexResults["ok"] ?? 0.0,
        "uvIndexOK": uvIndexResults["low"] ?? 0.0,
        "aqiGood": aqiResults["good"] ?? 0.0,
        "humidityOK": humidityResults["low"] ?? 0.0,
        "lightRain": weatherResults["lightRain"] ?? 0.0,
        "humidityHigh": humidityResults["high"] ?? 0.0,
      }, weights2);

      _likelihoodValues['Recommendation 2'] = likelihood2; // Store for debugging

      const double threshold2 = 0.4;
      if (likelihood2 > threshold2) {
        validRecommendations.add(
          "Hello, 'User'! It's quite rainy today, and the humidity is high. "
          "High humidity can irritate the airways, making it harder for individuals with asthma to breathe. "
          "It’s best to stay indoors where humidity is controlled. Keep safe!"
        );
      }

      // Recommendation 3
      Map<String, double> weights3 = {
        "heatIndexExtreme": 0.5,
        "uvIndexExtreme": 0.5,
      };

      double likelihood3 = calculateRecommendationLikelihood({
        "heatIndexExtreme": heatIndexResults["extremeDanger"] ?? 0.0,
        "uvIndexExtreme": uvIndexResults["extreme"] ?? 0.0,
      }, weights3);

      _likelihoodValues['Recommendation 3'] = likelihood3; // Store for debugging

      const double threshold3 = 0.8;
      if (likelihood3 > threshold3) {
        validRecommendations.add(
          "The UV index is extremely high today, and the heat index is dangerous. "
          "It's best to avoid outdoor activities as much as possible, especially for people with respiratory issues like asthma."
        );
      }

      // Add more recommendations as needed...

      return validRecommendations;
    }

    // Function to print all likelihood values when "i" button is pressed
    void _printLikelihoodValues() {
      print("Likelihood values for recommendations:");
      _likelihoodValues.forEach((key, value) {
        print('$key: $value');
      });
    }



    double calculateRecommendationLikelihood(Map<String, double> factors, Map<String, double> weights) {
      double weightedSum = 0.0;
      double totalWeight = 0.0;

      // Step-by-step likelihood calculation
      factors.forEach((factor, value) {
        double weight = weights[factor] ?? 0.0;
        weightedSum += value * weight;
        totalWeight += weight;
        print("Factor: $factor | Membership: $value | Weight: $weight | Contribution: ${value * weight}");
      });

      // Return the normalized weighted likelihood
      return totalWeight == 0.0 ? 0.0 : weightedSum / totalWeight;
  }

////////////////////////////////////////////////////////////////////////
//////////////////////// App Body /////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
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
            icon: Icon(Icons.info_outline, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Recommendations Section
            _buildSectionTitle('General Recommendations'),
            SizedBox(height: 8),
            _buildRecommendationCard(
              'Lorem ipsum dolor sit amet consectetur. Habitant nunc suscipit nunc nibh dignissim.',
              Colors.lightGreenAccent,
              Icons.checkroom, // Example icon, change as needed
            ),
            SizedBox(height: 8),
            _buildRecommendationCard(
              'Lorem ipsum dolor sit amet consectetur. Sed tristique suscipit et in viverra mi consequat faucibus.',
              Colors.lightBlueAccent,
              Icons.water_drop, // Example icon, change as needed
            ),
            SizedBox(height: 20),

          // Specific Recommendations Section
          _buildSectionTitle('Specific Recommendations'),
          SizedBox(height: 8),

          // Add PageView for swiping between recommendations
          Container(
            height: 200, // Set a fixed height for the recommendation cards area
            child: PageView.builder(
              controller: PageController(),
              itemCount: _recommendations.length, // Number of recommendations to display
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index; // Update the current page index on swipe
                });
              },
              itemBuilder: (context, index) {
                return _buildRecommendationCard(
                  _recommendations[index], // Display each recommendation
                  Colors.pinkAccent.shade100, // Set the card background color
                  Icons.healing, // Example icon, can be changed to suit the recommendation
                );
              },
            ),
          ),
          SizedBox(height: 10),

          // Page Indicator (optional)
          Center(
            child: Text(
              "${_currentPage + 1} / ${_recommendations.length}", // Display the current page out of total
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          SizedBox(height: 20),


            // Illness Concentration Section
            _buildSectionTitle('Illness Concentration'),
            SizedBox(height: 8),
            _buildStaticMap(context), // Pass context for navigation
            SizedBox(height: 20),

            // Other Articles Section
            _buildSectionTitle('Other Articles'),
            SizedBox(height: 8),
            _buildArticleRow(
              'Lorem ipsum dolor sit amet consectetur. Ipsum amet ultricies imperdiet dui a vestibulum.',
              Colors.lightBlueAccent,
              'Lorem ipsum dolor sit amet consectetur. Nulla pretium diam in dui dui ipsum.',
              Colors.pinkAccent.shade100,
            ),
            SizedBox(height: 8),
            _buildArticleRow(
              'Lorem ipsum dolor sit amet consectetur. Venenatis dui maecenas aliquet ut sem blandit ac quam maecenas.',
              Colors.lightGreenAccent.shade100,
              'Lorem ipsum dolor sit amet consectetur. Eget malesuada lectus vitae diam quis massa quis neque varius.',
              Colors.grey.shade200,
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: Icon(Icons.info_outline, color: Colors.grey),
          onPressed: _printLikelihoodValues,
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
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
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(width: 10),
          Icon(icon, size: 40, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildStaticMap(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MapWidget()), // Navigate to MapWidget on tap
        );
      },
      child: Container(
        height: 200,  // Fixed height for the map
        width: double.infinity,  // Full width of the container
        decoration: BoxDecoration(
          color: Colors.lightGreenAccent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/provinces-2k.png', // Replace with your static map image
            fit: BoxFit.cover, // Cover the entire container
            width: double.infinity, // Take up the full width
            height: 200, // Keep the image within the container's height
          ),
        ),
      ),
    );
  }

  Widget _buildArticleRow(String text1, Color color1, String text2, Color color2) {
    return Row(
      children: [
        Expanded(
          child: _buildArticleCard(text1, color1),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildArticleCard(text2, color2),
        ),
      ],
    );
  }

  Widget _buildArticleCard(String text, Color color) {
    return Container(
      width: 150,  // Fixed width for the card
      height: 150, // Fixed height for the card
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Center( // Center the text
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
          textAlign: TextAlign.center, // Center align the text
          maxLines: 5, // Limit to a maximum of 5 lines (adjust if necessary)
          overflow: TextOverflow.ellipsis, // Use ellipsis for overflow
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.pinkAccent,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      currentIndex: 1,
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