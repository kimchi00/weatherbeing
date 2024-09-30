import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = '4f6b2fa02ea341be89850512242909'; 

  Future<Map<String, dynamic>> fetchWeather(String city) async {
    final url = 'http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$city&aqi=yes';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
