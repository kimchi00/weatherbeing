import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FuzzyPage extends StatefulWidget {
  @override
  _FuzzyPageState createState() => _FuzzyPageState();
}

class _FuzzyPageState extends State<FuzzyPage> {
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

  // Replace with your own API key
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

  void _evaluateAndPrintResults() async {
    try {
      // Fetch the real-time weather data
      Map<String, dynamic> weatherData = await fetchWeatherData();

      // Extract the relevant values
      double heatIndex = weatherData['current']['feelslike_c'];
      double uvIndex = weatherData['current']['uv'];
      double humidity = weatherData['current']['humidity'].toDouble();
      double precipitationMM = weatherData['current']['precip_mm']; // Fetch precipitation in mm
      double aqi = weatherData['current']['air_quality']['us-epa-index'].toDouble(); // Fetch AQI (example)

      // Fetch user BMI from Firestore
      double? userBMI = await fetchUserBMI();
      if (userBMI != null) {
        Map<String, double> bmiResults = evaluateBMI(userBMI);
        print("User BMI: $userBMI");
        bmiResults.forEach((category, value) {
          print("BMI Category: $category, Membership: $value");
        });
      } else {
        print("User BMI not found.");
      }

      // Evaluate the fuzzy logic results using the fetched weather data
      Map<String, double> heatIndexResults = evaluateHeatIndex(heatIndex);
      Map<String, double> uvIndexResults = evaluateUVIndex(uvIndex);
      Map<String, double> humidityResults = evaluateHumidity(humidity);
      Map<String, double> weatherResults = evaluateWeather(precipitationMM); // Evaluate weather condition based on precipitation
      Map<String, double> aqiResults = evaluateAQICategory(aqi);

      // Print the weather condition results
      print("Precipitation (mm): $precipitationMM");
      weatherResults.forEach((category, value) {
        print("Weather Condition: $category, Membership: $value");
      });

      // Print the heat index results
      print("Heat Index: $heatIndex");
      heatIndexResults.forEach((category, value) {
        print("Heat Index Category: $category, Membership: $value");
      });

      // Print the UV index results
      print("UV Index: $uvIndex");
      uvIndexResults.forEach((category, value) {
        print("UV Index Category: $category, Membership: $value");
      });

      // Print the humidity results
      print("Humidity: $humidity");
      humidityResults.forEach((category, value) {
        print("Humidity Category: $category, Membership: $value");
      });

        // Print the AQI results
      print("AQI: $aqi");
      aqiResults.forEach((category, value) {
        print("AQI Category: $category, Membership: $value");
      });

     generateAsthmaRecommendation(weatherResults, heatIndexResults, uvIndexResults, aqiResults, humidityResults);
      
    } catch (e) {
      print('Error: $e');
    }
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

///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
/////////////// Displaying algo ///////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////


  void generateAsthmaRecommendation(
    Map<String, double> weatherResults,
    Map<String, double> heatIndexResults,
    Map<String, double> uvIndexResults,
    Map<String, double> aqiResults,
    Map<String, double> humidityResults
  ) {
  // Define the weights for the factors
  Map<String, double> weights = {
    "clearWeather": 0.7,
    "heatIndexOK": 0.7,
    "heatIndexCaution": 0.05,
    "uvIndexOK": 0.7,
    "uvIndexCaution": 0.05,
    "aqiGood": 0.1,
    "aqiCaution": 0.05,
    "humidityOK": 0.1,
    "humidityCaution": 0.05,
    "humidityHigh": 0.05,  // Added weight for "high" humidity
    "humidityVeryHigh": 0.05,  // Added weight for "very high" humidity
  };

  // Get the relevant fuzzy membership values for each factor
  Map<String, double> factors = {
    "clearWeather": weatherResults["clear"] ?? 0.0,
    "heatIndexOK": heatIndexResults["ok"] ?? 0.0,
    "heatIndexCaution": heatIndexResults["caution"] ?? 0.0,
    "uvIndexOK": uvIndexResults["low"] ?? 0.0,
    "uvIndexCaution": uvIndexResults["moderate"] ?? 0.0,
    "aqiGood": aqiResults["good"] ?? 0.0,
    "aqiCaution": aqiResults["moderate"] ?? 0.0,
    "humidityOK": humidityResults["low"] ?? 0.0,
    "humidityCaution": humidityResults["moderate"] ?? 0.0,
    "humidityHigh": humidityResults["high"] ?? 0.0,  // Added membership for "high" humidity
    "humidityVeryHigh": humidityResults["veryHigh"] ?? 0.0,  // Added membership for "very high" humidity
  };

    print("Step-by-step factor membership values:");
    factors.forEach((factor, value) {
      print("$factor Membership: $value");
    });

    print("\nStep-by-step weights for each factor:");
    weights.forEach((factor, weight) {
      print("$factor Weight: $weight");
    });

    // Calculate the weighted likelihood
    double likelihood = calculateRecommendationLikelihood(factors, weights);
    
    print("\nFinal likelihood value: $likelihood");

    // Define a threshold for showing the recommendation
    const double threshold = 0.7;

    // Show the recommendation if the likelihood exceeds the threshold
    if (likelihood > threshold) {
      print("Hello, 'User'! The air quality and humidity are good today, but take precautions. "
            "People are likely to be outside today. Let's be vigilant of places that can trigger asthma, "
            "such as animal parks or streets with heavy traffic. Remember, fur and smoke are asthma triggers!");
    } else {
      print("The conditions today are generally safe for asthma.");
    }
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fuzzy Logic with Weather API'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _evaluateAndPrintResults,
          child: Text('Evaluate Fuzzy Logic from API Data'),
        ),
      ),
    );
  }

 
}
