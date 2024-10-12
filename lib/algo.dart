class Fuzzy{

 /////////////////////////// Trapezoidal Membership Function (trapmf) ///////////////////////////
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

  /////////////////////////// Method to evaluate heat index and return category membership ///////////////////////////
  Map<String, double> evaluateHeatIndex(double heatIndex) {
    
    // Heat Index Membership Categories

  double ok(double heatIndex) {
    // OK: Membership is 1 when HI ≤ 26, gradually decreases after that
    // Fully OK up to 26, then decreases, and 0 at 30
    return trapmf(heatIndex, 20.0, 26.0, 26.0, 30.0);
  }

  double caution(double heatIndex) {
    // Caution: Membership is highest between 27 and 32
    // Starts at 26, fully caution at 30, fades out by 34
    return trapmf(heatIndex, 26.0, 28.0, 32.0, 34.0);
  }

  double extremeCaution(double heatIndex) {
    // Extreme Caution: Membership highest between 33 and 41
    // Starts at 33, fully extreme caution at 38, fades out by 42
    return trapmf(heatIndex, 33.0, 35.0, 38.0, 42.0);
  }

  double danger(double heatIndex) {
    // Danger: Membership highest between 42 and 51
    // Starts at 42, fully danger at 45, fades out by 52
    return trapmf(heatIndex, 42.0, 45.0, 50.0, 52.0);
  }

  double extremeDanger(double heatIndex) {
    // Extreme Danger: Membership highest when HI > 52
    // Starts at 52, fully extreme danger at 55, stays at 1 for values > 55
    return trapmf(heatIndex, 52.0, 55.0, 55.0, 60.0);
  }


    return {
      "ok": ok(heatIndex),
      "caution": caution(heatIndex),
      "extremeCaution": extremeCaution(heatIndex),
      "danger": danger(heatIndex),
      "extremeDanger": extremeDanger(heatIndex),
    };
  }
  
  ///////////////////////////  Method to evaluate UV index and return category membership ///////////////////////////
  Map<String, double> evaluateUVIndex(double uvIndex) {

      // UV Index Membership Categories

    double low(double uvIndex) {
      // Low: Fully "Low" at UV index 1-2, fades out by 4
      return trapmf(uvIndex, 1.0, 1.0, 2.0, 4.0);
    }

    double moderate(double uvIndex) {
      // Moderate: Fully "Moderate" at UV index 3-5, fades out by 7
      return trapmf(uvIndex, 2.0, 3.0, 5.0, 7.0);
    }

    double high(double uvIndex) {
      // High: Fully "High" at UV index 6-7, fades out by 8
      return trapmf(uvIndex, 5.0, 6.0, 7.0, 8.0);
    }

    double veryHigh(double uvIndex) {
      // Very High: Fully "Very High" at UV index 8-10, fades out by 11
      return trapmf(uvIndex, 7.0, 8.0, 10.0, 11.0);
    }

    double extreme(double uvIndex) {
      // Extreme: Fully "Extreme" at UV index >11
      return trapmf(uvIndex, 10.0, 11.0, 12.0, 12.0);
    }

    return {
      "low": low(uvIndex),
      "moderate": moderate(uvIndex),
      "high": high(uvIndex),
      "veryHigh": veryHigh(uvIndex),
      "extreme": extreme(uvIndex),
    };
  }

///////////////////////////  Weather condition membership values for "Clear" and "Rain" /////////////////////////// 
  Map<String, double> evaluateWeather(double mm) {

  // Weather Conditions Membership Functions
  double clear(double mm) {
    // Clear: Fully clear at 0 mm, fades out between 0.1 mm and 0.5 mm
    return trapmf(mm, 0.0, 0.0, 0.1, 0.5);
  }

  double patchyRain(double mm) {
    // Patchy Rain: Fully patchy rain between 0.1 mm and 1.9 mm, fades out by 3 mm
    return trapmf(mm, 0.1, 1.0, 1.9, 3.0);
  }

  double lightRain(double mm) {
    // Light Rain: Fully light rain between 2 mm and 4 mm, fades out by 5 mm
    return trapmf(mm, 2.0, 3.0, 4.0, 5.0);
  }

  double moderateRain(double mm) {
    // Moderate Rain: Fully moderate rain between 5 mm and 6 mm, fades out by 7 mm
    return trapmf(mm, 4.5, 5.0, 6.0, 7.0);
  }

  double strongRain(double mm) {
    // Rain or Strong Rain: Fully rain or strong rain between 15 mm and 20 mm, fades out by 25 mm
    return trapmf(mm, 10.0, 15.0, 20.0, 25.0);
  }

  double rainfall(double mm) {
    // Rainfall: Fully in rainfall from 30 mm onwards
    return trapmf(mm, 25.0, 30.0, 30.0, 35.0);
  }

    return {
      "clear": clear(mm),
      "patchyRain": patchyRain(mm),
      "lightRain": lightRain(mm),
      "moderateRain": moderateRain(mm),
      "strongRain": strongRain(mm),
      "rainfall": rainfall(mm),
    };
  }

/////////////////////////// Method to evaluate humidity and return category membership ///////////////////////////
  Map<String, double> evaluateHumidity(double humidity) {

        // Humidity Membership Categories

    double low(double humidity) {
      // Low: Fully "Low" at 10-20%, starts decreasing at 25%, gone by 30%
      return trapmf(humidity, 10.0, 15.0, 20.0, 30.0);
    }

    double moderate(double humidity) {
      // Moderate: Fully "Moderate" at 30-50%, starts decreasing at 55%, gone by 60%
      return trapmf(humidity, 25.0, 30.0, 40.0, 60.0);
    }

    double high(double humidity) {
      // High: Fully "High" at 60-70%, starts decreasing at 75%
      return trapmf(humidity, 55.0, 60.0, 65.0, 75.0);
    }

    double veryHigh(double humidity) {
      // Very High: Fully "Very High" at 80-100%, stays fully high until 100%
      return trapmf(humidity, 75.0, 80.0, 90.0, 100.0);
    }
    return {
      "low": low(humidity),
      "moderate": moderate(humidity),
      "high": high(humidity),
      "veryHigh": veryHigh(humidity),
    };
  }

 /////////////////////////// Evaluate the category name for a given AQI value /////////////////////////// 
  String evaluateAQICategory(double aqi) {
    if (aqi == 1) {
      return "Good";
    } else if (aqi == 2) {
      return "Moderate";
    } else if (aqi == 3) {
      return "Unhealthy for Sensitive Groups";
    } else if (aqi == 4) {
      return "Unhealthy";
    } else if (aqi == 5) {
      return "Very Unhealthy";
    } else if (aqi == 6) {
      return "Hazardous";
    } else {
      return "Invalid AQI value";
    }
  }

/////////////////////////// Function to evaluate age and return the category description /////////////////////////// 
  String evaluateAgeCategory(int age) {
    if (age >= 0 && age <= 12) {
      return "Child";
    } else if (age >= 13 && age <= 18) {
      return "Adolescent";
    } else if (age >= 19 && age <= 59) {
      return "Adult";
    } else if (age >= 60) {
      return "Senior Adult";
    } else {
      return "Invalid Age";  // Handle negative age or other invalid inputs
    }
  }

  /////////////////////////// Evaluate BMI membership values for all categories   ///////////////////////////
  Map<String, double> evaluateBMI(double bmi) {

        // BMI Membership Categories
    double underweight(double bmi) {
      // Underweight: Full underweight below 18.5, starts fading after
      return trapmf(bmi, 10.0, 10.0, 16.0, 18.5);
    }

    double normalWeight(double bmi) {
      // Normal weight: Fully normal between 18.5 and 24.9, fades out after
      return trapmf(bmi, 18.0, 18.5, 24.9, 25.5);
    }

    double overweight(double bmi) {
      // Overweight: Fully overweight between 25 and 29.9, starts fading after
      return trapmf(bmi, 24.0, 25.0, 29.9, 30.5);
    }

    double obese(double bmi) {
      // Obese: Fully obese above 30
      return trapmf(bmi, 29.5, 30.0, 40.0, 50.0);
    }

    return {
      "underweight": underweight(bmi),
      "normalWeight": normalWeight(bmi),
      "overweight": overweight(bmi),
      "obese": obese(bmi),
    };
  }

}