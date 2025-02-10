import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weatherbeing/climate.dart';
import 'package:weatherbeing/heathealth.dart';
import 'package:weatherbeing/map.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weatherbeing/morbidity.dart';
import 'package:weatherbeing/summerillness.dart';
import 'package:shared_preferences/shared_preferences.dart';


class HealthModule extends StatefulWidget {
  @override
  _HealthModuleState createState() => _HealthModuleState();
}

class _HealthModuleState extends State<HealthModule> {

  List<String> _recommendations = ["Fetching recommendations..."]; // List to hold recommendations
  Map<String, double> _likelihoodValues = {}; // Store likelihood values for debugging
  int _currentPage = 0; // Track the current page for swipe navigation
  
  // Manage active async operations
  final List<Future> _activeOperations = [];

  @override
  void initState() {
    super.initState();
    _evaluateAndPrintResults(); // Call the method to fetch the data and calculate recommendation
  }


////////////////////////////////////////////////////////////////////////
//////////////////// Fetching weather and user data ////////////////////
////////////////////////////////////////////////////////////////////////

  Future<Map<String, dynamic>> fetchUserDetails(BuildContext context) async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch user document from Firestore using UID
        DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          // Extract and validate the data
          final data = userDoc.data() ?? {};
          String userName = data['name'] as String? ?? 'User'; // Default to 'User' if null
          List<String> healthConcerns = List<String>.from(data['health_concerns'] ?? []);
          double? bmi = data['bmi'] is num ? (data['bmi'] as num).toDouble() : null; // Ensure double
          String? sex = data['sex'] as String?;
          int? age = data['age'] is num ? (data['age'] as num).toInt() : null; // Ensure int

          // Check for the weekly pop-up
          await _checkAndShowWeeklyPopup(context, userName, healthConcerns);

          // Return all values in a map
          return {
            'name': userName,
            'healthConcerns': healthConcerns,
            'bmi': bmi,
            'sex': sex,
            'age': age,
          };
        }
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }

    // Default values in case of error or missing data
    return {
      'name': 'User',
      'healthConcerns': [],
      'bmi': null,
      'sex': null,
      'age': null,
    };
  }

  Future<void> _checkAndShowWeeklyPopup(
      BuildContext context, String userName, List<String> healthConcerns) async {
    final prefs = await SharedPreferences.getInstance();
    final lastPopupDate = prefs.getString('last_popup_date');
    final currentDate = DateTime.now();

    if (lastPopupDate == null ||
        DateTime.parse(lastPopupDate).isBefore(currentDate.subtract(Duration(days: 7)))) {
      // Show the weekly pop-up
      _showWeeklyPopup(context, userName, healthConcerns);

      // Update the last pop-up date
      await prefs.setString('last_popup_date', currentDate.toIso8601String());
    }
  }

  void _showWeeklyPopup(
      BuildContext context, String userName, List<String> healthConcerns) {
    final concernsText = healthConcerns.isNotEmpty
        ? healthConcerns.join(", ")
        : "no specific health concerns";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Hello, $userName!"),
          content: Text(
            "Last week, you were concerned about $concernsText. Are you feeling better now?",
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Remove concerns from Firebase
                await _clearUserHealthConcerns();

                Navigator.pop(context); // Close the dialog
              },
              child: const Text("Yes, I'm better"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                // Additional logic for "No" can be added here
              },
              child: const Text("No, not yet"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearUserHealthConcerns() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update the health_concerns field to an empty list in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'health_concerns': []});

        print("User's health concerns cleared successfully.");
      }
    } catch (e) {
      print("Error clearing user's health concerns: $e");
    }
  }






  final String apiKey = "4f6b2fa02ea341be89850512242909";


  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get the current location
    return await Geolocator.getCurrentPosition();
  }

  // final String location = "Naga City"; 

  // Future<Map<String, dynamic>> fetchWeatherData() async {
  //   final url =
  //       'http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$location&aqi=yes';
  //   final response = await http.get(Uri.parse(url));

  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic> data = json.decode(response.body);
  //     return data;
  //   } else {
  //     throw Exception('Failed to load weather data');
  //   }
  // }

  Future<Map<String, dynamic>> fetchWeatherData() async {
    try {
      Position position = await _getCurrentLocation();
      final url =
          'http://api.weatherapi.com/v1/current.json?key=$apiKey&q=${position.latitude},${position.longitude}&aqi=yes';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }

    Future<String> _getCurrentCity() async {
    try {
      Position position = await _getCurrentLocation();
      final url =
          'http://api.weatherapi.com/v1/current.json?key=$apiKey&q=${position.latitude},${position.longitude}&aqi=no';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['location']['name']; // Get the city name
      } else {
        throw Exception('Failed to load location data');
      }
    } catch (e) {
      return 'Unknown Location';
    }
  }

    void _showLocationPopup() async {
    String location = await _getCurrentCity();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Your Current Location'),
          content: Text(location),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

    // Define a method to handle the navigation
  int _selectedIndex = 1; // This tracks the currently selected tab
  void _onItemTapped(int index) {
    // Navigate only if the selected tab changes
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index; // Update the selected index
      });

      // Navigate to the corresponding route
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

  //   // Function to evaluate BMI based on fuzzy logic
  // Map<String, double> evaluateBMI(double bmi) {
  //   double underweight(double bmi) => trapmf(bmi, 10.0, 10.0, 16.0, 18.5);
  //   double normalWeight(double bmi) => trapmf(bmi, 18.0, 18.5, 24.9, 25.5);
  //   double overweight(double bmi) => trapmf(bmi, 24.0, 25.0, 29.9, 30.5);
  //   double obese(double bmi) => trapmf(bmi, 29.5, 30.0, 40.0, 50.0);

  //   return {
  //     "underweight": underweight(bmi),
  //     "normalWeight": normalWeight(bmi),
  //     "overweight": overweight(bmi),
  //     "obese": obese(bmi),
  //   };
  // }

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
    double clear(double mm) => trapmf(mm, 0.0, 0.0, 0.01, 0.5);
    double patchyRain(double mm) => trapmf(mm, 0.01, 0.02, 1.9, 3.0);
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
      double aqi = weatherData['current']['air_quality']['us-epa-index'].toDouble();

      // Fetch user details (name and health concerns)
      Map<String, dynamic> userDetails = await fetchUserDetails(context);
      String userName = userDetails['name'];
      List<String> healthConcerns = userDetails['healthConcerns'];
      double? bmi = userDetails['bmi'];
      String? sex = userDetails['sex'];
      int? age = userDetails['age'];

      // Generate multiple recommendations
      List<String> recommendations = await generateAsthmaRecommendations(
        evaluateHeatIndex(heatIndex), 
        evaluateUVIndex(uvIndex), 
        evaluateAQICategory(aqi), 
        evaluateHumidity(humidity),
        healthConcerns,
        userName,
        sex,
        age,
        bmi,
      );

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


/// set for rain codes
  Set<int> rainCodes = {
    1063, 1087, 1150, 1153, 1168, 1171, 1180, 1183, 1186, 1189, 
    1192, 1195, 1240, 1243, 1246, 1273, 1276
  };

  Future<bool> isChanceOfRain() async {
    try {
      // Fetch the weather data
      Map<String, dynamic> weatherData = await fetchWeatherData();

      // Extract the current weather condition code
      int currentWeatherCode = weatherData['current']['condition']['code'];

      // Check if the current weather code indicates rain
      return rainCodes.contains(currentWeatherCode);
    } catch (e) {
      print("Error fetching weather condition code: $e");
      return false; // Default to no chance of rain if there's an error
    }
  }


  // Function to generate recommendations and store likelihoods for debugging
    Future<List<String>> generateAsthmaRecommendations(
      // Map<String, double> //,
      Map<String, double> heatIndexResults,
      Map<String, double> uvIndexResults,
      Map<String, double> aqiResults,
      Map<String, double> humidityResults,
      List<String> healthConcerns,
      String userName,
      String? sex,
      int? age,
      double? bmi,
    ) async {
      List<String> validRecommendations = [];
      _likelihoodValues.clear(); // Clear previous likelihood values


      double calculateRecommendation({
        // required Map<String, double> //,
        required Map<String, double> heatIndexResults,
        required Map<String, double> uvIndexResults,
        required Map<String, double> aqiResults,
        required Map<String, double> humidityResults,
        required Map<String, double> weights,
      }) {
        // Use the provided weights and evaluate each factor
        return calculateRecommendationLikelihood({
          // // weather
          // "clearWeather": //["clear"] ?? 0.0,
          // "patchyRain": //["patchyRain"] ?? 0.0,
          // "lightRain": //["lightRain"] ?? 0.0,
          // "moderateRain": //["moderateRain"] ?? 0.0,
          // "strongRain": //["strongRain"] ?? 0.0,
          // "rainfall": //["rainfall"] ?? 0.0,
          // heat index
          "heatIndexOK": heatIndexResults["ok"] ?? 0.0,
          "caution": heatIndexResults["caution"] ?? 0.0,
          "extremeCaution": heatIndexResults["extremeCaution"] ?? 0.0,
          "danger": heatIndexResults["danger"] ?? 0.0,
          "extremeDanger": heatIndexResults["extremeDanger"] ?? 0.0,
          // uv index
          "low": uvIndexResults["low"] ?? 0.0,
          "moderate": uvIndexResults["moderate"] ?? 0.0,
          "high": uvIndexResults["high"] ?? 0.0,
          "veryHigh": uvIndexResults["veryHigh"] ?? 0.0,
          "extreme": uvIndexResults["extreme"] ?? 0.0,
          // aqi
          "good": aqiResults["good"] ?? 0.0,
          "moderateAqi": aqiResults["moderate"] ?? 0.0,
          "unhealthyForSensitive": aqiResults["unhealthyForSensitive"] ?? 0.0,
          "unhealthy": aqiResults["unhealthy"] ?? 0.0,
          "veryUnhealthy": aqiResults["veryUnhealthy"] ?? 0.0,
          "hazardous": aqiResults["hazardous"] ?? 0.0,
          // humidity
          "humidityOK": humidityResults["low"] ?? 0.0,
          "humiditymoderate": humidityResults["moderate"] ?? 0.0,
          "humidityhigh": humidityResults["high"] ?? 0.0,
          "humidityveryHigh": humidityResults["veryHigh"] ?? 0.0,
        }, weights);
      }


      // Recommendation 1
      Map<String, double> weights1 = {
        // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

      double likelihood1 = calculateRecommendation(
        // //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights1,
      );

      _likelihoodValues['Recommendation 1'] = likelihood1; // Store for debugging

      const double threshold1 = 0.7;
      bool chanceOfRain = await isChanceOfRain();

    if (likelihood1 > threshold1 && healthConcerns.contains("Asthma") && (age != null && age <= 12) && (!chanceOfRain)) {
      validRecommendations.add(
        "Hello, $userName! The air quality and humidity are good today. "
        "People are likely to be outside today. Take precautions in areas with fur or smoke, as they are asthma triggers!"
      );
    }



      // Recommendation 2
      Map<String, double> weights2 = {
        // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

      double likelihood2 = calculateRecommendation(
        // //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights2,
      );

      _likelihoodValues['Recommendation 2'] = likelihood2; // Store for debugging

      const double threshold2 = 0.7;
      if (likelihood2 > threshold2 && healthConcerns.contains("Asthma") && (age != null && age <= 12) && (!chanceOfRain)) {
      validRecommendations.add(
        "Hello, $userName! It’s a great day to play outside! Be careful of pollen from flowers though, they may be pretty,but they can trigger your asthma.Their beauty can still be appreciated by our eyes!"
      );
    }

      // Recommendation 3
      Map<String, double> weights3 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood3 = calculateRecommendation(
        // // // //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights3,
      );

      _likelihoodValues['Recommendation 3'] = likelihood3; // Store for debugging

      const double threshold3 = 0.7;
      if (likelihood3 > threshold3 && healthConcerns.contains("Asthma") && (age != null && age <= 12) && (!chanceOfRain)) {
      validRecommendations.add(
        "Hello, $userName!  It’s sunny outside today, a perfect day to play with your friends! Please be careful and try not to overexert yourself, asthma can be triggered by intense activities. Have fun!"
      );
    }

 // Recommendation 4
      Map<String, double> weights4 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood4 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights4,
      );

      _likelihoodValues['Recommendation 4'] = likelihood4; // Store for debugging

      const double threshold4 = 0.7;
      if (likelihood4 > threshold4 && healthConcerns.contains("Asthma") && (age != null && age > 12) && (bmi != null && bmi > 25)&& (!chanceOfRain)) {
      validRecommendations.add(
        "Hello, $userName!  Today looks like a wonderful day! It’s the perfect weather for exercising. Swimming, for example, is a great way for managing your asthma and is even used for asthma therapy.  Have a good day!"
      );
    }
      
      // Recommendation 5
      Map<String, double> weights5 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood5 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights5,
      );

      _likelihoodValues['Recommendation 5'] = likelihood5; // Store for debugging

      const double threshold5 = 0.7;
      if (likelihood5 > threshold5 && healthConcerns.contains("Asthma") && (age != null && age > 12) && (bmi != null && bmi > 25) && (!chanceOfRain)) {
      validRecommendations.add(
        "Hello, $userName!  It’s a great day for a walk outside! Remember to wear breathable clothes and bring your inhaler in case of asthma attacks. Also, try to stay away from common asthma triggers like smoke and dust. Enjoy your day!"
      );
    }

        // Recommendation 6
      Map<String, double> weights6 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood6 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights6,
      );

      _likelihoodValues['Recommendation 6'] = likelihood6; // Store for debugging

      const double threshold6 = 0.7;
      if (likelihood6 > threshold6 && healthConcerns.contains("Asthma") && (age != null && age > 12) && (bmi != null && bmi > 25) && (!chanceOfRain)) {
      validRecommendations.add(
        "Hello, $userName! Looks like the sun is smiling on us today! It’s a perfect day for outdoor activities like biking! Biking is an exercise that can help manage your asthma, it’s also fun! But please be vigilant and try to not overexert yourself, it may trigger an asthma attack. Have a good day!"
      );
    }

      // Recommendation for  rain /////////////////////////
      ////////////////////////////////////////////////////
      ////////////////////////////////////////////////////
      

            Map<String, double> weights7 = {
       // weather
        // "clearWeather": 0.7,
        // "patchyRain": 0.0,
        // "lightRain": 0.0,
        // "moderateRain": 0.0,
        // "strongRain": 0.0,
        // "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.9,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.9,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.9,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.0,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.9,
      };

        double likelihood7 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights7,
      );

      _likelihoodValues['Recommendation 7'] = likelihood7; // Store for debugging
      const double threshold7 = 0.7;
      if (likelihood7 > threshold7 &&healthConcerns.contains("Asthma") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! It might rain today and the humidity is really high! High humidity can irritate the airways, making it harder for individuals with asthma to breathe. It’s best to stay indoors where humidity is more controlled. Keep safe!"
        );
        validRecommendations.add(
          "Hello, $userName! It looks like we're in for a bit of rain today. Humidity is also quite high. Please stay cautious today as high humidity can trigger bronchial spasms and inflammation. Have a nice day!"
        );
        validRecommendations.add(
          "Hello, $userName! It’s best to stay indoors today, it's quite hot, it might rain and the humidity is high. Make sure to stay dry if you need to go outside. Bring a face mask too, raindrops can stir up allergens like pollen which can trigger asthma. Stay dry and safe!"
        );
        }

      if (healthConcerns.contains("Allergies") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! It might be rainy today. If you have watery, itchy eyes and a runny or stuffy nose, it might be because of the weather. It’s best to stay dry to avoid worsening your symptoms. Have a nice day!"
        );
      }

      if (healthConcerns.contains("Acute respiratory tract infection") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! It might get quite hot today but there is still chance of rain. Hot temperatures have been known to increase emergency department visits for acute upper respiratory infections and influenza, keep safe today!"
        );
      }

      if (healthConcerns.contains("Diabetes") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Although it may rain today, the UV Index is still high. Aside from the heat making us sweat, diabetes complications, such as damage to blood vessels and nerves, can affect your sweat glands so your body can't cool as effectively. It’s extra important to stay cool and stay in the shade today! "
        );
      }
      if (healthConcerns.contains("Pneumonia") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! It might get quite hot today, but it might still rain, try to stay cool and out of the sun. Cold spells are not the only cause of pneumonia, heatwaves can cause the illness too! Stay hydrated!"
        );
      }

      if (healthConcerns.contains("Diarrhea") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName!  Try to stay out of the sun today! Heat exhaustion and dehydration can cause heat-induced diarrhea, which emerges as a result of the body’s response to extreme temperatures. Stay hydrated out there!"
        );
      }

      if (healthConcerns.contains("Dehydration") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Hot day, huh? Remember that dehydration can be caused by something as small as not intaking enough water during hot weather, but watch out! Diarrhea and heat exhaustion can cause dehydration too, and they are both common in the hot weather. Stay hydrated and cool!"
        );
      }

      if (healthConcerns.contains("Heatstroke") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Heatstroke is a condition caused by the body overheating, usually as a result of prolonged exposure to or physical exertion in high temperatures, stay in the shade and out of the sun as much as you can today!"
        );
      }

          // 8 FOR HYPERTENSION Sunny, Moderate Heat Index && Humidity, Normal Range AQI && UV Index
      Map<String, double> weights8 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood8 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights8,
      );

      _likelihoodValues['Recommendation 8'] = likelihood8; // Store for debugging

      const double threshold8 = 0.7;
      if (likelihood8 > threshold8 && healthConcerns.contains("Hypertension") && (age != null && age < 30) && (bmi != null && bmi < 25)) {
        validRecommendations.add(
          "Hello, $userName! It’s the perfect weather for fun and relaxation! Stress management is great for managing high blood pressure. Enjoy the beautiful day, have fun outside, but wear comfortable clothes to avoid heat exhaustion!"
        );
        validRecommendations.add(
          "Hello, $userName! The weather is wonderful outside! It’s perfect for fun times like eating out! Try to incorporate potassium in your diet. Fruits and whole grains are also great for managing your blood pressure. Happy eating!"
        );
      }

      if (likelihood8 > threshold8 && healthConcerns.contains("Hypertension") && (age != null && age < 30) && (bmi != null && bmi > 25)) {
        validRecommendations.add(
          "Hello, $userName! It’s the perfect day for a bit of exercise, although rain might fall in certain times of the day! Maintaining a healthy weight can help lower high blood pressure and will do wonders for your health and body. Enjoy your day!"
        );
        validRecommendations.add(
          "Hello, $userName! Regular physical activity can help you maintain a healthy weight and lower your blood pressure. Stay healthy!"
        );
        validRecommendations.add(
        "Hello, $userName!  Let’s enjoy the sun while it is out today! It’s not too hot for a bit of outdoor activity. Did you know that just by sitting less, you can help prevent and lower high blood pressure?  Have fun today!"
      );
      }

      if (likelihood8 > threshold8 && healthConcerns.contains("Hypertension") && (age != null && age > 30)) {
        validRecommendations.add(
          "Hello, $userName! Did you know that our risk of getting high blood pressure tends to rise with age? But it can be prevented and maintained! Today is a perfect day for exercise. A simple walk or a workout can make a big difference in keeping your blood pressure in check."
        );
        validRecommendations.add(
          "Hello, $userName! Studies have found out that we are more at risk of hypertension when we age, symptoms are also more severe. But it can be managed! It’s a perfect day for outdoor activities with benefits, like brisk walking and yoga!  "
        );
        validRecommendations.add(
        "Hello, $userName! It’s a perfect day to take proactive steps to help keep hypertension under control! Exercise and a good diet goes a long way for managing your health and managing high blood pressure. Have a good day!"
        );
      }

       if (likelihood8 > threshold8 && healthConcerns.contains("Hypertension") && (age != null && age > 30) && sex == 'Female') {
        validRecommendations.add(
          "Hello, $userName! Hormonal changes can lead to a higher risk of hypertension. Hypertension becomes more common in women as they age, especially after menopause. A healthy diet and exercise goes a long way for your overall health! Stay healthy!"
        );
         validRecommendations.add(
          "Hello, $userName! Did you know that women are more likely to experience atypical symptoms of hypertension? This means that the symptoms are not as pronounced. It’s important to stay vigilant and healthy. Exercise is good for you!"
        );
       }
        // Recommendation 9 !! Rainy day for hypertension
      Map<String, double> weights9 = {
       // weather
        "clearWeather": 0.0,
        "patchyRain": 0.7,
        "lightRain": 0.7,
        "moderateRain": 0.7,
        "strongRain": 0.7,
        "rainfall": 0.7,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.7,
        "humidityveryHigh": 0.7,
      };

        double likelihood9 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights9,
      );

      _likelihoodValues['Recommendation 9'] = likelihood9; // Store for debugging

      const double threshold9 = 0.7;
      if (likelihood9 > threshold9 && healthConcerns.contains("Hypertension") && (age != null && age > 44) ) {
      validRecommendations.add(
        "Hello, $userName! It’s raining at the moment but it’s still quite hot and it’s very humid. Humidity affects us more as we age, it causes the heart to beat faster while circulating twice as much blood per minute than on a normal day. It’s best to stay dry and cool to stay healthy!"
      );
      validRecommendations.add(
        "Hello, $userName!  It's quite humid today because of the rain. Humidity can make it harder for sweat to evaporate, which can lead to dehydration, which raises blood pressure as the body tries to conserve fluids. It’s best to relax and stay indoors today. Stay healthy!"
      );
      validRecommendations.add(
        "Hello, $userName! Did you know that as we age, our heart functions can decline? it is important to stay dry and cool especially during humid days, the extra strain on our heart is not ideal for our health. Have a good day!"
      );
    }

      // Recommendation 10 !!Allergies
      Map<String, double> weights10 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.0,
        "caution": 0.3,
        "extremeCaution": 0.7,
        "danger": 0.7,
        "extremeDanger": 0.7,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.7,
        "humidityveryHigh": 0.7,
      };

        double likelihood10 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights10,
      );

      _likelihoodValues['Recommendation 10'] = likelihood10; // Store for debugging

      const double threshold10 = 0.7;
      if (likelihood10 > threshold10 && healthConcerns.contains("Allergies") && (age != null && age < 12)) {
        validRecommendations.add(
          "Hello, $userName! It’s quite hot today. If you want to go play outside, remember to stay away from flowers as their pollen can cause your allergies to flare up! Stay safe!"
        );
        validRecommendations.add(
          "Hello, $userName! It’s very hot and humid today! Try to stay cool and hydrated because our body will naturally sweat more during hot and humid days. Sweat can trap allergens like dust mites, mold spores, and pollen in the air, making them more likely to irritate your eyes, nose, and throat. Don’t play too hard outside today!"
        );
      }

       if (likelihood10 > threshold10 && healthConcerns.contains("Allergies") && (age != null && age > 12)) {
        validRecommendations.add(
          "Hello, $userName! We’re in for a bit of heat today. If you want to exercise, remember to do it indoors, as the high heat outside is bad for your health, pollen can also stick to our clothes, which can flare up allergies. Stay safe!"
          );
        validRecommendations.add(
          "Hello, $userName! It’s too hot to stay outside for too long. Make sure to drink plenty of fluids to help thin mucus and ease congestion. Stay healthy!"
          );
      }

            // Recommendation 11 !!Allergies rainy
      Map<String, double> weights11 = {
       // weather
        "clearWeather": 0.0,
        "patchyRain": 0.7,
        "lightRain": 0.7,
        "moderateRain": 0.7,
        "strongRain": 0.7,
        "rainfall": 0.7,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood11 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights11,
      );

      _likelihoodValues['Recommendation 11'] = likelihood11; // Store for debugging

      const double threshold11 = 0.7;
      if (likelihood11 > threshold11 && healthConcerns.contains("Allergies") && (chanceOfRain)) {
      validRecommendations.add(
        "Hello, $userName! It’s raining and cold today! The cold can trigger allergies like allergic rhinitis, so it’s best to stay warm and cozy for today. Staying indoors is highly recommended, stay dry and healthy!"
      );
      validRecommendations.add(
        "Hello, $userName! It’s quite cold and rainy today. If you have watery, itchy eyes and a runny or stuffy nose, it might be because of the weather. It’s best to stay warm and dry to avoid worsening your symptoms. Have a nice day!"
      );
    }

      // Recommendation 12 UTI
      Map<String, double> weights12 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.9,
      };

        double likelihood12 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights12,
      );

      _likelihoodValues['Recommendation 12'] = likelihood12; // Store for debugging

      const double threshold12 = 0.7;
      if (likelihood12 > threshold12 && healthConcerns.contains("Urinary tract infection")) {
        validRecommendations.add(
          "Hello, $userName!  It might get hot today due to high humidity. Remember to stay cool and hydrated, but also to keep clean! Warmer weather makes UTI-causing bacteria grow. Keep that in mind if you are going out today!"
        );
      }
      if (likelihood12 > threshold12 && healthConcerns.contains("Urinary tract infection") && sex == 'Female') {
        validRecommendations.add(
          "Hello, $userName! Avoid humid places. UTI-causing bacteria love this kind of weather. Also, because of our anatomy females are more likely to contract UTI than males. It’s important to stay extra vigilant and safe to avoid this heat-loving disease. Stay safe out there!"
        );
      }


      // Recommendation 13  Ischemic heart disease
      Map<String, double> weights13 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.0,
        "caution": 0.7,
        "extremeCaution": 0.7,
        "danger": 0.7,
        "extremeDanger": 0.7,
        // uv index
        "low": 0.0,
        "moderate": 0.0,
        "high": 0.7,
        "veryHigh": 0.7,
        "extreme": 0.7,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood13 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights13,
      );

      _likelihoodValues['Recommendation 13'] = likelihood13; // Store for debugging

      const double threshold13 = 0.7;
      if (likelihood13 > threshold13 && healthConcerns.contains("Ischemic heart disease")) {
        validRecommendations.add(
          "Hello, $userName! It’s very hot today. Remember to stay cool and hydrated, exposure to high heat increases the risk for heat exhaustion and heat stroke, but it can also place a particular burden on heart health. This can increase chances of heart attacks. Stay safe out there!"
        );
      }
      
      if (likelihood13 > threshold13 && healthConcerns.contains("Ischemic heart disease")  && (bmi != null && bmi < 18.5)) {
        validRecommendations.add(
          "Hello, $userName! It’s very hot today. Being underweight means you have lower muscle mass and glycogen (stored energy) reserves.This can make you more susceptible to fatigue and weakness in hot conditions. Focus on consuming nutritious meals and snacks to maintain adequate energy stores."
        );
        validRecommendations.add(
          "Hello, $userName!  It’s very hot today. Sweating leads to loss of electrolytes increasing the risk of electrolyte imbalance and its associated problems like muscle cramps, nausea, and dizziness. Drink plenty of water and electrolyte-rich fluids throughout the day, even before feeling thirsty."
        );
      }

      if (likelihood13 > threshold13 && healthConcerns.contains("Ischemic heart disease") && (age != null && age > 60) && (bmi != null && bmi > 25)) {
        validRecommendations.add(
          "Hello, $userName! It’s very hot today. The body works harder to cool itself down in hot weather. This increases heart rate and cardiac output, which can be challenging for a heart that's already narrowed arteries. Stay safe out there!"
        );
        validRecommendations.add(
          "Hello, $userName! It’s very hot today. As we age, the body is more prone to the dangerous effects of certain chemicals. Drink plenty of fluids, even if you don't feel thirsty. Avoid sugary drinks and alcohol, which can dehydrate you. Stay safe out there!"
        );
      }


      // Recommendation 14 !! Heart disease (Rainy)
      Map<String, double> weights14 = {
       // weather
        "clearWeather": 0.0,
        "patchyRain": 0.7,
        "lightRain": 0.7,
        "moderateRain": 0.7,
        "strongRain": 0.7,
        "rainfall": 0.7,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.0,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.7,
      };

        double likelihood14 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights14,
      );

      _likelihoodValues['Recommendation 14'] = likelihood14; // Store for debugging

      const double threshold14 = 0.7;
      if (likelihood14 > threshold14 && healthConcerns.contains("Ischemic heart disease") && (chanceOfRain)) {
      validRecommendations.add(
        "Hello, $userName! It might get quite cold because of the rain today. Try to stay warm and cozy today, cold weather can give you angina pectoris (chest pain or discomfort). It can be quite dangerous if you already have prior heart problems. Stay safe out there!"
      );
    }
    
      // Recommendation 15 !! Acute respiratory tract infection 
      Map<String, double> weights15 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.9,
      };

        double likelihood15 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights15,
      );

      _likelihoodValues['Recommendation 15'] = likelihood15; // Store for debugging

      const double threshold15 = 0.7;
      if (likelihood15 > threshold15 && healthConcerns.contains("Acute respiratory tract infection")) {
        validRecommendations.add(
          "Hello, $userName! It might get hot today because of the high humidity. Hot weather encourages sweating, which can worsen dehydration in someone already fighting an infection. Drink plenty of fluids, even if you don't feel thirsty. Choose water or electrolyte-rich drinks. Stay safe out there!"
        );
      }
      if (likelihood15 > threshold15 && healthConcerns.contains("Acute respiratory tract infection") && (age != null && age > 60) && (bmi != null && bmi > 25)) {
        validRecommendations.add(
          "Hello, $userName! It’s quite hot today. As we age, our bodies become less efficient at regulating temperature and fighting off infections. Focus on getting plenty of rest to allow your body to fight off the infection, keep safe today!"
        );
        validRecommendations.add(
          "Hello, $userName! It’s quite hot today.  Excess weight can make breathing more difficult in general, and during hot weather, this can be further exacerbated. Limit strenuous activity, stay in air conditioning when possible, and take cool showers or baths. Stay safe out there!"
        );
      }

      // Recommendation 16 !!! Acute respiratory tract infection  FOR RAINY !!!
      Map<String, double> weights16 = {
       // weather
        "clearWeather": 0.0,
        "patchyRain": 0.3,
        "lightRain": 0.7,
        "moderateRain": 0.7,
        "strongRain": 0.7,
        "rainfall": 0.7,
        // heat index
        "heatIndexOK": 0.0,
        "caution": 0.0,
        "extremeCaution": 0.7,
        "danger": 0.7,
        "extremeDanger": 0.7,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.0,
        "humiditymoderate": 0.4,
        "humidityhigh": 0.7,
        "humidityveryHigh": 0.7,
      };

        double likelihood16 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights16,
      );

      _likelihoodValues['Recommendation 16'] = likelihood16; // Store for debugging

      const double threshold16 = 0.7;
      if (likelihood16 > threshold16 && healthConcerns.contains("Acute respiratory tract infection ")) {
        validRecommendations.add(
          "Hello, $userName! Did you know that cold temperatures increased the risk of most respiratory diseases? This is because our body’s protective response becomes inhibited in colder temperatures. Keep warm to avoid lung diseases!"
        );
        validRecommendations.add(
          "Hello, $userName! It's quite chilly today. Cold weather can exacerbate symptoms of ARTI, such as coughing, wheezing, and shortness of breath. The cold air can irritate the respiratory tract and cause inflammation. Stay safe out there!"
        );
      }

      if (likelihood16 > threshold16 && healthConcerns.contains("Acute respiratory tract infection ") && (age != null && age > 60) && (bmi != null && bmi > 25)) {
        validRecommendations.add(
          "Hello, $userName! It's quite chilly today. Did you know that the cold can cause blood vessels to constrict, leading to increased blood pressure. This can put additional strain on the heart and respiratory system, particularly in older adults who are overweight. Let’s engage in light indoor exercises to maintain physical health. Stay safe out there!"
        );
        validRecommendations.add(
          "Hello, $userName!  It's quite chilly today. FYI, cold weather can strain the respiratory system, leading to more severe outcomes, especially with the combination of age, ARTI, and being overweight, which can increase the risk of complications such as pneumonia. Let’s try to maintain a balanced diet rich in fruits, vegetables, and lean proteins to support immune health."
        );
      }


      // Recommendation 17 !! Diabetes
      Map<String, double> weights17 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.0,
        "caution": 0.7,
        "extremeCaution": 0.7,
        "danger": 0.7,
        "extremeDanger": 0.7,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.0,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.7,
        "humidityveryHigh": 0.7,
      };

       Map<String, double> weights18 = {
       // weather
        "clearWeather": 0.0,
        "patchyRain": 0.3,
        "lightRain": 0.7,
        "moderateRain": 0.7,
        "strongRain": 0.7,
        "rainfall": 0.7,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.7,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood17 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights17,
      );

      double likelihood18 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights18,
      );

      _likelihoodValues['Recommendation 17'] = likelihood17; // Store for debugging
      _likelihoodValues['Recommendation 18'] = likelihood18;

      const double threshold17 = 0.7;
      const double threshold18 = 0.7;
      if (likelihood17 > threshold17 && healthConcerns.contains("Diabetes")) {
        validRecommendations.add(
          "Hello, $userName! Today looks like a very hot day. Aside from the heat making us sweat, diabetes complications, such as damage to blood vessels and nerves, can affect your sweat glands so your body can't cool as effectively. It’s extra important to stay cool and stay in the shade today! "
        );
        validRecommendations.add(
        "Hello, $userName! It is important to keep cool today as it is really hot, but as we’re not very active during hot weather, long periods of inactivity may affect your diabetes because you're not being very active, making blood sugar levels higher than usual. Keep busy, but stay hydrated and cool."
        );
      }
      if (likelihood17 > threshold17 && healthConcerns.contains("Diabetes") && (age != null && age > 59) && (bmi != null && bmi > 25)) {
        validRecommendations.add(
          "Hello, $userName! Today looks like a very hot day. Sweating can lead to dehydration. Dehydration makes it harder for the body to use insulin effectively, causing blood sugar levels to rise and become difficult to manage for diabetics. Stay hydrated and cool today!"
        );
        validRecommendations.add(
        "Hello, $userName! Today looks like a very hot day. High temperatures can disrupt the body's natural processes, making blood sugar levels more susceptible to swings. This can lead to both hyperglycemia (high blood sugar) and hypoglycemia (low blood sugar). Wear cool clothes, stay in the shade, and stay hydrated!"
      );
      }
      //rainy!!!!!!!!
      if (likelihood18 > threshold18 && healthConcerns.contains("Diabetes")) {
        validRecommendations.add(
          "Hello, $userName! Cold day today, huh? Did you know that the body releases stress hormones like cortisol in response to cold temperatures. These hormones can counteract insulin's effects, making it harder for the body to use insulin and leading to higher blood sugar levels. Stay warm today!"
        );
      }
      if (likelihood18 > threshold18 && healthConcerns.contains("Diabetes") && (bmi != null && bmi > 25)) {
        validRecommendations.add(
          "Hello, $userName!  Cold day today, huh? Did you know that cold weather can slow blood flow around the body, which can increase the risk of heart attacks and stroke, which is even riskier for those with diabetes. Stay warm!"
        );
      }


      // Reco 19 !! Pneumonia
      Map<String, double> weights19 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.0,
        "caution": 0.4,
        "extremeCaution": 0.7,
        "danger": 0.7,
        "extremeDanger": 0.7,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.0,
        "humiditymoderate": 0.7,
        "humidityhigh": 0.7,
        "humidityveryHigh": 0.7,
      };

      Map<String, double> weights20 = { //for rainy
       // weather
        "clearWeather": 0.0,
        "patchyRain": 0.3,
        "lightRain": 0.4,
        "moderateRain": 0.7,
        "strongRain": 0.7,
        "rainfall": 0.7,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.7,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood19 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights19,
      );

        double likelihood20 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights20,
      );

      _likelihoodValues['Recommendation 19'] = likelihood19; // Store for debugging
      _likelihoodValues['Recommendation 20'] = likelihood20; // Store for debugging

      const double threshold19 = 0.7;
      if (likelihood19 > threshold19 && healthConcerns.contains("Pneumonia")) {
        validRecommendations.add(
          "Hello, $userName! It’s quite hot today, try to stay cool and out of the sun. Cold spells are not the only cause of pneumonia, heatwaves can cause the illness too! Stay hydrated!"
        );
         validRecommendations.add(
          "Hello, $userName! It’s quite hot today, try to stay hydrated because dehydration thickens mucus in the lungs, making it harder to cough up and clear the congestion caused by pneumonia. Stay hydrated!"
        );
      }

       if (likelihood19 > threshold19 && healthConcerns.contains("Pneumonia") && (age != null && age > 60) && (bmi != null && bmi > 25)) {
        validRecommendations.add(
          "Hello, $userName! It’s quite hot today. Older adults and overweight individuals are more susceptible to heat stress, which can exacerbate underlying health conditions like pneumonia. Stay cool!"
        );
      }

      //rainy

      if (likelihood20 > threshold19 && healthConcerns.contains("Pneumonia")) {
        validRecommendations.add(
          "Hello, $userName!  It might get really cold today, so we gotta watch out for the chances of getting pneumonia! Although the disease is caused by bacteria and fungi, recent studies have found out that the cold has been associated with increased hospital visits for pneumonia."
        );
        validRecommendations.add(
          "Hello, $userName! It might get really cold today, cold air can irritate the respiratory tract, triggering the body to produce more mucus. This can worsen congestion and coughing in someone already suffering from pneumonia. Stay warm and out of the cold air!"
        );
        validRecommendations.add(
          "Hello, $userName! It might get really cold today. Exposure to cold can slightly suppress the immune system, potentially prolonging recovery from pneumonia. Try to stay out of the rain and cold air!"
        );
      }

      // Recommendation 21 !! Diarrhea
      Map<String, double> weights21 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.0,
        "caution": 0.3,
        "extremeCaution": 0.7,
        "danger": 0.7,
        "extremeDanger": 0.7,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.7,
        "humidityhigh": 0.7,
        "humidityveryHigh": 0.7,
      };

        double likelihood21 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights21,
      );

      _likelihoodValues['Recommendation 21'] = likelihood21; // Store for debugging

      const double threshold21 = 0.7;
      if (likelihood21 > threshold21 && healthConcerns.contains("Diarrhea")) {
        validRecommendations.add(
          "Hello, $userName! Try to stay out of the sun today! Heat exhaustion and dehydration can cause heat-induced diarrhea, which emerges as a result of the body’s response to extreme temperatures. Stay hydrated out there!"
        );
         validRecommendations.add(
          "Hello, $userName! Try to stay out of the sun today! High heat can significantly worsen diarrhea. Diarrhea causes the body to expel fluids through loose stools. This can lead to dehydration, which is the loss of fluids and electrolytes. Drink plenty of fluids, even if you don't feel thirsty!"
        );
         validRecommendations.add(
          "Hello, $userName!  It’s really hot today! Stay hydrated throughout the day to avoid dehydration. Dehydration can actually make diarrhea worse. When the body is dehydrated, the stool becomes harder to pass and can lead to constipation following diarrhea."
        );
      }

      //rainy

      if (likelihood20 > threshold19 && healthConcerns.contains("Diarrhea")) {
        validRecommendations.add(
          "Hello, $userName! Did you know that high temperatures can alter the balance of beneficial bacteria in the gut, exacerbating existing digestive conditions? But sudden rain causes a risk for diarrhea due to the appearance of pathogens or microorganisms that can cause diseases in the environment. Stay safe, wear a facemask!"
        );
      }

      // Recommendation 22 !! Tuberculosis
      Map<String, double> weights22 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.0,
        "caution": 0.7,
        "extremeCaution": 0.7,
        "danger": 0.7,
        "extremeDanger": 0.7,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood22 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights22,
      );

      _likelihoodValues['Recommendation 22'] = likelihood22; // Store for debugging

      const double threshold22 = 0.7;
      if (likelihood22 > threshold22 && healthConcerns.contains("Tuberculosis") && (age != null && age >  35) && sex == 'Female') {
        validRecommendations.add(
          "Hello, $userName! It’s really hot and humid today! Try to stay out of the sun today! Recent research found out that high temperatures have a long-term lag effect risk for female groups and the age group over 35 years. It’s better to be safe than sorry! Wear a facemask!"
        );
      }

       //rainy!!!!!!!!
      if (likelihood18 > threshold18 && healthConcerns.contains("Tuberculosis")) {
        validRecommendations.add(
          "Hello, $userName! It’s quite chilly today, did you know that extremely low temperatures could increase the risk of TB transmission? Prevention is always better than cure. A little knowledge goes a long way! "
        );
      }

      // Recommendation 23 !! Chickenpox
      Map<String, double> weights23 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.7,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.7,
        "humiditymoderate": 0.7,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood23 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights23,
      );

      _likelihoodValues['Recommendation 23'] = likelihood23; // Store for debugging

      const double threshold23 = 0.7;
      if (likelihood23 > threshold23 && healthConcerns.contains("Chickenpox") ) {
        validRecommendations.add(
          "It’s a perfect day to play outside! But remember, chickenpox  infection caused by the varicella-zoster virus may be more common in the summer months in the Philippines. The hotter and more humid weather may create favorable conditions for the varicella-zoster virus to spread. Try to stay safe out there!"
        );
      }
      if (likelihood23 > threshold23 && healthConcerns.contains("Chickenpox") && (age != null && age < 12) ) {
        validRecommendations.add(
          "Hello, $userName!  It’s a perfect day to play outside! But remember, chickenpox is really common in the hotter season! Sweating also  increases the risk of skin infections. If you haven’t been vaccinated yet, it’s best to put that in your priority list!"
        );
      }

      //rainy!!!!!!!!
      if (likelihood18 > threshold18 && healthConcerns.contains("Chickenpox")) {
        validRecommendations.add(
          "Hello, $userName! It’s quite chilly today, Chickenpox is also fairly known to start during the colder season. Just a little food for thought that might come in handy in the future!"
        );
      }

      // Recommendation 24 !! Conjunctivitis 
      Map<String, double> weights24 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.7,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood24 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights24,
      );

      _likelihoodValues['Recommendation 24'] = likelihood24; // Store for debugging

      const double threshold24 = 0.7;
      if (likelihood24 > threshold24 && healthConcerns.contains("Conjunctivitis")) {
        validRecommendations.add(
          "Hello, $userName! Great day to go outside! If you want to lessen the risk of contracting sore eyes, try to wear sunglasses when outdoors. It’s also best to avoid touching or rubbing your eyes!"
        );
         validRecommendations.add(
          "Hello, $userName! It's quite hot out today! Hot weather can be dry and windy, which can dry out the eyes and worsen irritation caused by conjunctivitis. Keep safe always!"
        );
      }

      //rainy!!!!!!!!
      if (likelihood18 > threshold18 && healthConcerns.contains("Conjunctivitis")) {
        validRecommendations.add(
          "Hello, $userName! It’s quite cold today. The frigid air can dry our eyes quicker, making them tear up more, leading to itchiness. Sore eyes are spread through direct contact, so make sure your hands are clean!"
        );
      }

      // Recommendation 25 !! Flu and the common cold
      Map<String, double> weights25 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.1,
        "humiditymoderate": 0.7,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood25 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights25,
      );

      _likelihoodValues['Recommendation 25'] = likelihood25; // Store for debugging

      const double threshold25 = 0.7;
      if (likelihood25 > threshold25 && healthConcerns.contains("Flu")) {
        validRecommendations.add(
          "Hello, $userName!  Good sunny day to you! Although we associate flu and cold with the colder seasons, summer flu is quite real! We tend to go to malls to cool off, but the enclosed space is perfect for flu transmission. Stay safe!"
        );
      }

       //rainy!!!!!!!!
      if (likelihood18 > threshold18 && healthConcerns.contains("Flu")) {
        validRecommendations.add(
          "Hello, $userName! Very chilly today! Try to stay warm and cozy to avoid contracting the flu and common cold! Cold and flu viruses survive better and are more transmissible if it's cooler and if there's lower humidity, so keep safe always!"
        );
        validRecommendations.add(
          "Hello, $userName! Very chilly today!  Exposure to cold weather can mildly suppress the immune system, making it potentially harder for your body to fight off infections like the flu or common cold. Stay warm if you’re feeling a bit under the weather! "
        );
        validRecommendations.add(
          "Hello, $userName! Very chilly today! If you’re mostly staying indoors because of the rain and cold, avoid people with coughs and colds because they might transmit the illness to you! Stay safe!"
        );
      }

      // Recommendation 26 !! Food poisoning 
      Map<String, double> weights26 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.7,
        "humiditymoderate": 0.7,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood26 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights26,
      );

      _likelihoodValues['Recommendation 26'] = likelihood26; // Store for debugging

      const double threshold26 = 0.7;
      if (likelihood26 > threshold26 && healthConcerns.contains("Food poisoning")) {
        validRecommendations.add(
          "Hello, $userName! Good day for a picnic outside! Remember though, foodborne illnesses are twice as common during the summer season than other months of the year since food spoils easily in the heat, so keep that in mind if you’re eating out!"
        );
      }

            // Recommendation 27 !! Measles
      Map<String, double> weights27 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.7,
        "humiditymoderate": 0.7,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood27 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights27,
      );

      _likelihoodValues['Recommendation 27'] = likelihood27; // Store for debugging

      const double threshold27 = 0.7;
      if (likelihood27 > threshold27 && healthConcerns.contains("Measles")) {
        validRecommendations.add(
          "Hello, $userName! It looks like summer is still in full bloom! Try to watch out for measles which are more common in the current season, especially here in our tropical country."
        );
      }

            // Recommendation 28 !! Dehydration
      Map<String, double> weights28 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.7,
        "humiditymoderate": 0.7,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood28 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights28,
      );

      _likelihoodValues['Recommendation 28'] = likelihood28; // Store for debugging

      const double threshold28 = 0.7;
      if (likelihood28 > threshold28 && healthConcerns.contains("Dehydration")) {
        validRecommendations.add(
          "Hello, $userName!Hot day, huh? Remember that dehydration can be caused by something as small as not intaking enough water during hot weather, but watch out! Diarrhea and heat exhaustion can cause dehydration too, and they are both common in the hot weather. Stay hydrated and cool!"
        );
        validRecommendations.add(
          "Hello, $userName! Hot day, huh? Our bodies sweat to cool down in hot weather. This sweating process leads to fluid loss. The hotter and more humid the environment, the more we sweat to maintain a normal body temperature. Stay cool and hydrated to avoid dehydration!"
        );
        validRecommendations.add(
          "Hello, $userName! Headache, fatigue, dizziness, dry mouth, decreased urination, and muscle cramps are symptoms of dehydration. In severe cases, dehydration can lead to heatstroke, a life-threatening condition. Drink plenty of fluids today!"
        );
        validRecommendations.add(
          "Hello, $userName! Dehydration is a preventable condition, drink plenty of fluids throughout the day, even if you don't feel thirsty. Water is ideal, but electrolyte-rich drinks can be helpful for those sweating heavily. Try to wear cooler clothes too!"
        );
      }

             //rainy!!!!!!!!
      if (likelihood18 > threshold18 && healthConcerns.contains("Dehydration")) {
        validRecommendations.add(
          "Hello, $userName! It’s gonna be cold today! It’s good to know that the body does not sense thirst as well when it's cold outside, so keep track of your water intake today! Stay warm and cozy!"
        );
      }

            // Recommendation 29 !! Skin conditions
      Map<String, double> weights29 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.7,
        "humiditymoderate": 0.0,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.7,
      };

        double likelihood29 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights29,
      );

      _likelihoodValues['Recommendation 29'] = likelihood29; // Store for debugging

      const double threshold29 = 0.7;


      // Check for likelihood and rain condition

      if (likelihood29 > threshold29 &&
        (healthConcerns.contains("Eczema") || 
        healthConcerns.contains("Heat rash") || 
        healthConcerns.contains("Skin allergy"))) {
          validRecommendations.add(
            "Hello, $userName!  It might get hot today because of the high humidity! Let’s prepare for it by wearing cool clothes to avoid sweating. Heat rash, also known as prickly heat, is an itchy skin irritation caused by excessive sweating, so it’s important to stay cool today!"
          );
      }
      // rainy
      if (likelihood18 > threshold18 && healthConcerns.contains("Eczema") || healthConcerns.contains("Heat rash") || healthConcerns.contains("Skin allergy")) {
        validRecommendations.add(
          "Hello, $userName! Did you know that extreme cold can cause skin asthma or eczema? This is because cold, dry air and harsh wind can cause your symptoms to flare up. If you want to avoid it, make sure to wear clothing that keeps you warm and safe from the wind!"
        );
      }

            // Recommendation 30 !! Bronchitis
      Map<String, double> weights30 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.7,
        "caution": 0.0,
        "extremeCaution": 0.0,
        "danger": 0.0,
        "extremeDanger": 0.0,
        // uv index
        "low": 0.7,
        "moderate": 0.0,
        "high": 0.0,
        "veryHigh": 0.0,
        "extreme": 0.0,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.7,
        "humiditymoderate": 0.7,
        "humidityhigh": 0.0,
        "humidityveryHigh": 0.0,
      };

        double likelihood30 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights30,
      );

      _likelihoodValues['Recommendation 30'] = likelihood30; // Store for debugging

      const double threshold30 = 0.7;
      if (likelihood30 > threshold30 && healthConcerns.contains("Bronchitis")) {
        validRecommendations.add(
          "Hello, $userName! It’s gonna be a hot day today! Keep in mind that the hot weather affects you more when you have bronchitis. It can also cause your symptoms to flare up. Drink lots of water and stay cool and out of the shade! "
        );
      }

        //rainy!!!!!!!!
      if (likelihood18 > threshold18 && healthConcerns.contains("Bronchitis")) {
        validRecommendations.add(
          "Hello, $userName!  Quite chilly today, the cold air can irritate the airways if you have bronchitis, so it's important to stay warm and out of the cold and the wind. Viruses and bacteria also live on surfaces longer in cold temperatures as opposed to warm ones, so it;s a good day to clean if you have the time!"
        );
      }

      // Recommendation 31 !! Heatstroke 
      Map<String, double> weights31 = {
       // weather
        "clearWeather": 0.7,
        "patchyRain": 0.0,
        "lightRain": 0.0,
        "moderateRain": 0.0,
        "strongRain": 0.0,
        "rainfall": 0.0,
        // heat index
        "heatIndexOK": 0.0,
        "caution": 0.7,
        "extremeCaution": 0.7,
        "danger": 0.7,
        "extremeDanger": 0.7,
        // uv index
        "low": 0.7,
        "moderate": 0.7,
        "high": 0.7,
        "veryHigh": 0.7,
        "extreme": 0.7,
        // aqi
        "good": 0.1,
        "moderateAqi": 0.0,
        "unhealthyForSensitive": 0.0,
        "unhealthy": 0.0,
        "veryUnhealthy": 0.0,
        "hazardous": 0.0,
        // humidity
        "humidityOK": 0.7,
        "humiditymoderate": 0.7,
        "humidityhigh": 0.7,
        "humidityveryHigh": 0.7,
      };

        double likelihood31 = calculateRecommendation(
        //: //,
        heatIndexResults: heatIndexResults,
        uvIndexResults: uvIndexResults,
        aqiResults: aqiResults,
        humidityResults: humidityResults,
        weights: weights31,
      );

      _likelihoodValues['Recommendation 31'] = likelihood31; // Store for debugging

      const double threshold31 = 0.7;
      if (likelihood31 > threshold31 && healthConcerns.contains("Heatstroke")) {
        validRecommendations.add(
          "Hello, $userName! It’s sweltering hot outside today! Heatstroke is a condition caused by the body overheating, usually as a result of prolonged exposure to or physical exertion in high temperatures, stay in the shade and out of the sun as much as you can today!"
        );
        validRecommendations.add(
          "Hello, $userName!  It’s sweltering hot outside today! Hot weather is the single biggest risk factor for heat stroke, a life-threatening condition. Confusion, agitation, slurred speech, seizures, or coma can occur. Avoid alcohol and caffeinated drinks, they can dehydrate you further."
        );        
      }
       if (likelihood31 > threshold31 && healthConcerns.contains("Heatstroke") && (age != null && age > 59) && (bmi != null && bmi > 25)) {
        validRecommendations.add(
          "Hello, $userName! It’s sweltering hot outside today! As we age, our bodies become less efficient at regulating internal temperature. This makes it harder to cool down in hot weather. Skin thins with age, making it less effective at sweating and dissipating heat. Stay cool and hydrated!"
        );
        validRecommendations.add(
          "Hello, $userName! Excess body fat can act as insulation, trapping heat inside the body and making it harder to cool down. Limit strenuous activity outdoors, especially during peak heat hours. Spend time in air-conditioned spaces when possible. Wear loose, breathable clothing made from natural fibers like cotton. Take cool showers or baths to lower body temperature."
        );        
      }

      //default recommendations clear
       if (healthConcerns.contains("Ischemic heart disease") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Avoid over exertion in hot weather; the humidity can make it feel more hot than it really is, stay in cool, shaded areas and drink plenty of water to avoid heat stress."
        );
       }
       if (healthConcerns.contains("Acute respiratory tract infection") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Stay hydrated and avoid outdoor activities during high pollution or dusty conditions to reduce respiratory irritation."
        );
       }
        if (healthConcerns.contains("Aneurysm") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Avoid activities in extreme heat as high temperatures can increase blood pressure and strain on blood vessels. High humidity can make it hotter than it really is, so stay cool and hydrated."
        );
       }
        if (healthConcerns.contains("Hypertension") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Stay indoors during peak heat hours to prevent dehydration and avoid salt-heavy snacks that increase blood pressure."
        );
       }
        if (healthConcerns.contains("Diabetes") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Monitor blood sugar levels closely in the heat, as dehydration can affect insulin effectiveness. The high humidity will make certain places more hot than usual. Stay hydrated."
        );
       }
        if (healthConcerns.contains("Pneumonia") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Avoid exposure to dusty or polluted air that can irritate the lungs. Wear a mask if needed."
        );
       }
        if (healthConcerns.contains("Diarrhea") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Avoid consuming foods that can spoil in the heat; opt for freshly prepared, hygienic meals."
        );
       }
        if (healthConcerns.contains("Bronchitis") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Avoid dusty outdoor environments and drink warm fluids to soothe the respiratory tract."
        );
       }
        if (healthConcerns.contains("Tuberculosis") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Avoid prolonged exposure to direct sunlight as it may lead to fatigue. Rest in well-ventilated spaces."
        );
       }
        if (healthConcerns.contains("Urinary tract infection") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Drink plenty of water and avoid caffeine, which can irritate the bladder."
        );
       }
        if (healthConcerns.contains("Asthma") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Avoid outdoor activities during high pollen or pollution levels. Carry an inhaler at all times."
        );
       }
        if (healthConcerns.contains("Chickenpox") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Avoid direct sunlight as it can irritate the skin. Stay indoors in a cool, shaded environment."
        );
       }
        if (healthConcerns.contains("Conjunctivitis") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Wear sunglasses outdoors to protect your eyes from bright light and dust."
        );
       }
        if (healthConcerns.contains("Flu") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Stay hydrated and avoid crowds to reduce the risk of spreading or contracting the virus."
        );
       }
        if (healthConcerns.contains("Common cold") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Use saline sprays to keep your nasal passages moist in dry, hot conditions."
        );
       }
        if (healthConcerns.contains("Food poisoning") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Avoid eating food left in the open heat, as bacteria multiply faster in warm conditions."
        );
       }
        if (healthConcerns.contains("Heatstroke") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Avoid prolonged sun exposure and drink electrolyte-rich fluids to stay hydrated."
        );
       }
        if (healthConcerns.contains("Measles") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Avoid direct sunlight as it can worsen rash discomfort. Stay indoors in a cool environment."
        );
       }
        if (healthConcerns.contains("Eczema") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Use a gentle moisturizer to prevent dryness caused by heat. Avoid sweating excessively."
        );
       }
        if (healthConcerns.contains("Heat rash") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Wear light, breathable clothing and avoid excessive sweating to prevent skin irritation."
        );
       }
        if (healthConcerns.contains("Allergies") && (!chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Avoid going out during high pollen counts or windy conditions. Use an air purifier indoors."
        );
       }


      //default recommendations rainy
       if (healthConcerns.contains("Ischemic heart disease") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Limit outdoor activities to prevent getting wet and cold, which can stress your heart. Wear warm, waterproof clothing."
        );
       }
       if (healthConcerns.contains("Acute respiratory tract infection") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Use a mask or scarf when outdoors to avoid inhaling damp air, which can worsen symptoms."
        );
       }
        if (healthConcerns.contains("Aneurysm") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Maintain warmth to avoid sudden cold exposure, which can cause blood vessel constriction."
        );
       }
        if (healthConcerns.contains("Hypertension") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Ensure warm, comfortable clothing to maintain steady blood pressure levels in cooler conditions."
        );
       }
        if (healthConcerns.contains("Diabetes") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Wear waterproof footwear to prevent foot infections, as diabetics are more prone to wounds and slow healing."
        );
       }
        if (healthConcerns.contains("Pneumonia") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Stay indoors as much as possible to avoid cold and damp conditions, which can worsen symptoms."
        );
       }
        if (healthConcerns.contains("Diarrhea") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Drink clean, boiled water to avoid waterborne infections prevalent during rainy seasons."
        );
       }
        if (healthConcerns.contains("Bronchitis") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Use a humidifier indoors to balance damp air and prevent cold air from aggravating your bronchitis."
        );
       }
        if (healthConcerns.contains("Tuberculosis") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Stay dry and warm to prevent damp conditions from exacerbating symptoms."
        );
       }
        if (healthConcerns.contains("Urinary tract infection") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Stay dry and avoid sitting in damp clothing to reduce the risk of bacterial growth."
        );
       }
        if (healthConcerns.contains("Asthma") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Be cautious of mold growth indoors and damp air, which can trigger asthma attacks. Use a dehumidifier if needed."
        );
       }
        if (healthConcerns.contains("Chickenpox") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Keep your skin dry and avoid damp clothing to prevent secondary infections."
        );
       }
        if (healthConcerns.contains("Conjunctivitis") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Avoid touching your eyes and use clean tissues to dry them if exposed to rain."
        );
       }
        if (healthConcerns.contains("Flu") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Stay warm and dry; damp clothing can worsen symptoms."
        );
                 validRecommendations.add(
          "Hello, $userName! Dress warmly and boost your immunity with vitamin-rich foods to stay protected from the flu."
        );
          validRecommendations.add(
          "Hello, $userName! Spend some time in natural sunlight to get vitamin D, but keep warm to avoid catching the flu."
        );
       }
        if (healthConcerns.contains("Common cold") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Avoid cold beverages and dress warmly to prevent chills."
        );
          validRecommendations.add(
          "Hello, $userName! It might get cold today, so keep warm to avoid catching a cold. There is also chance of rain, so stay dry and warm to avoid getting sick."
        );
                 validRecommendations.add(
          "Hello, $userName! There's a chance of rain today, avoid getting drenched in the rain to prevent catching a cold. Keep warm and dry to stay healthy."
        );
       }
        if (healthConcerns.contains("Food poisoning") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Ensure food is thoroughly cooked and avoid raw salads, as water contamination is more common."
        );
       }
        if (healthConcerns.contains("Heatstroke") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Stay in well-ventilated areas, as humidity can still lead to overheating indoors."
        );
       }
        if (healthConcerns.contains("Measles") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Ensure dry, warm clothing to avoid chills and damp skin irritation."
        );
       }
        if (healthConcerns.contains("Eczema") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Avoid damp, wet conditions as they can worsen eczema flare-ups."
        );
       }
        if (healthConcerns.contains("Heat rash") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Stay dry and avoid sitting in damp clothes, which can aggravate the rash."
        );
       }
        if (healthConcerns.contains("Allergies") && (chanceOfRain)) {
        validRecommendations.add(
          "Hello, $userName! Watch for mold growth indoors, which can trigger allergic reactions."
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
        //print("Factor: $factor | Membership: $value | Weight: $weight | Contribution: ${value * weight}");
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
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo2.png', // Adjust the path as needed
              height: 40,
            ),
            const SizedBox(width: 10),
            Text(
              'Weather-Being',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.grey),
            onPressed: _showLocationPopup,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Recommendations Section
            _buildRotatingRecommendations(),
            const SizedBox(height: 20),

            // Specific Recommendations Section
            _buildSectionTitle('Specific Recommendations'),
            const SizedBox(height: 8),

            // Add PageView for swiping between recommendations
            SizedBox(
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
            const SizedBox(height: 10),

            // Page Indicator (optional)
            Center(
              child: Text(
                "${_currentPage + 1} / ${_recommendations.length}", // Display the current page out of total
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            // Illness Concentration Section
            _buildSectionTitle('Illness Concentration'),
            const SizedBox(height: 8),
            _buildStaticMap(context), // Pass context for navigation
            const SizedBox(height: 20),

            // Other Articles Section
            _buildSectionTitle('Other Articles'),
            const SizedBox(height: 8),
            _buildArticleRow(
              'Climate change and heat health',
              Colors.lightBlueAccent,
              const ClimateChangeScreen(), // Screen for the first card
              'Weather-related morbidity',
              Colors.pinkAccent.shade100,
              const MorbidityScreen(), // Screen for the second card
            ),
            const SizedBox(height: 16), // Spacing between rows
            _buildArticleRow(
              'Common summer illnesses',
              Colors.lightGreenAccent.shade100,
              const SummerIllnessesScreen(), // Screen for the first card
              'Heat-related illnesses',
              Colors.grey.shade200,
              const HeatHealthScreen(), // Screen for the second card
            ),
            const SizedBox(height: 20),
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: Icon(Icons.info_outline, color: Colors.grey),
          onPressed: () {
            _showInfoPopup(title); // Call the info popup function based on the section title
          },
        ),
      ],
    );
  }

    void _showInfoPopup(String title) {
      String explanation = '';

      // Provide explanations for each section based on the title
      switch (title) {
        case 'General Recommendations':
          explanation =
              'General recommendations include guidelines for maintaining good health and staying safe in your environment.';
          break;
        case 'Specific Recommendations':
          explanation =
              'Specific recommendations are tailored to your location, health concerns, physical details, and weather conditions, helping you stay safe and healthy.';
          break;
        case 'Illness Concentration':
          explanation =
              'This section shows the total illnesses that we have collected from all of our users. It also shows the locations where these illnesses are most concentrated.';
          break;
        case 'Other Articles':
          explanation =
              'Read articles about climate, health, and weather-related topics to stay updated on essential information.';
          break;
        default:
          explanation = 'This section provides useful information.';
      }

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Text(explanation),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }

  Widget _buildRecommendationCard(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
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
              style: const TextStyle(
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

  Widget _buildRotatingRecommendations() {
  final List<Map<String, dynamic>> recommendations = [
    {
      'text': 'Drink water and stay out of the sun! Stay cool out there!',
      'color': Colors.lightGreenAccent,
      'icon': Icons.checkroom,
    },
    {
      'text': 'Hydrate! Hydrate! Hydrate! Wear cool clothes and bring an umbrella!',
      'color': Colors.lightBlueAccent,
      'icon': Icons.water_drop,
    },
    {
      'text': 'Avoid strenuous activity during the hottest parts of the day.',
      'color': Colors.orangeAccent,
      'icon': Icons.wb_sunny,
    },
    {
      'text': 'Use sunscreen and wear a hat when outdoors.',
      'color': Colors.yellowAccent,
      'icon': Icons.beach_access,
    },
    {
      'text': 'Stay in shaded or air-conditioned areas whenever possible to avoid heat exposure.',
      'color': Colors.orangeAccent,
      'icon': Icons.ac_unit, // Represents cooling or air-conditioning
    },
    {
      'text': 'Consume foods with high water content, like fruits and vegetables, to stay hydrated.',
      'color': Colors.greenAccent,
      'icon': Icons.local_dining, // Represents food and healthy eating
    },
    {
      'text': 'Take frequent breaks if you’re working or exercising outdoors.',
      'color': Colors.redAccent,
      'icon': Icons.fitness_center, // Represents exercise or outdoor activities
    },
    {
      'text': 'Avoid caffeine and alcohol, as they can increase dehydration in hot weather.',
      'color': Colors.purpleAccent,
      'icon': Icons.no_drinks, // Represents avoiding certain drinks
    },
  ];

  final PageController pageController = PageController();

  // Start a timer to auto-rotate the pages every 5 seconds
  Timer.periodic(const Duration(seconds: 5), (timer) {
    if (pageController.hasClients) {
      int nextPage = (pageController.page?.toInt() ?? 0) + 1;
      if (nextPage >= recommendations.length) {
        nextPage = 0; // Loop back to the first page
      }
      pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  });

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle('General Recommendations'),
      const SizedBox(height: 8),
      SizedBox(
        height: 150, // Fixed height for the recommendation card
        child: PageView.builder(
          controller: pageController,
          itemCount: recommendations.length,
          itemBuilder: (context, index) {
            final recommendation = recommendations[index];
            return _buildRecommendationCard(
              recommendation['text'],
              recommendation['color'],
              recommendation['icon'],
            );
          },
        ),
      ),
    ],
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
            'assets/images/map.png', // Replace with your static map image
            fit: BoxFit.cover, // Cover the entire container
            width: double.infinity, // Take up the full width
            height: 200, // Keep the image within the container's height
          ),
        ),
      ),
    );
  }

  Widget _buildArticleRow(
    String text1, 
    Color color1, 
    Widget screen1, 
    String text2, 
    Color color2, 
    Widget screen2,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildArticleCard(text1, color1, screen1), // Navigate to the first screen
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildArticleCard(text2, color2, screen2), // Navigate to the second screen
        ),
      ],
    );
  }



  Widget _buildArticleCard(String text, Color color, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => screen, // Navigate to the respective screen
          ),
        );
      },
      child: Container(
        width: 150, // Fixed width for the card
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
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
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