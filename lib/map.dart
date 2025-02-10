import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapWidget extends StatefulWidget {
  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  List<DiseaseData> diseaseData = [];
  List<LocationData> locationData = [];
  Map<String, Map<String, int>> illnessesByLocation = {};
  bool isLoading = true;

  String apiKey = '4f6b2fa02ea341be89850512242909'; 

  @override
  void initState() {
    super.initState();
    fetchHealthConcerns();
  }

  Future<void> fetchHealthConcerns() async {
    try {
      // Fetch data from the 'users' collection
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      Map<String, int> diseaseCounts = {};
      Map<String, int> cityCounts = {};
      Map<String, Map<String, int>> tempIllnessesByLocation = {};

      for (var doc in snapshot.docs) {
        // Process health concerns
        List<dynamic> concerns = doc['health_concerns'] ?? [];
        if (concerns.isEmpty) continue; // Skip users with no health concerns

        String locationKey = 'Unknown';

        // Process location
        if (doc['lastKnownLocation'] != null) {
          double latitude = doc['lastKnownLocation']['latitude'];
          double longitude = doc['lastKnownLocation']['longitude'];

          // Fetch city name using WeatherAPI
          locationKey = await fetchCityFromCoordinates(latitude, longitude);

          // Update city counts
          cityCounts[locationKey] = (cityCounts[locationKey] ?? 0) + 1;
        }

        // Group illnesses by location with their counts
        for (var concern in concerns) {
          diseaseCounts[concern] = (diseaseCounts[concern] ?? 0) + 1;

          if (!tempIllnessesByLocation.containsKey(locationKey)) {
            tempIllnessesByLocation[locationKey] = {};
          }

          tempIllnessesByLocation[locationKey]![concern] =
              (tempIllnessesByLocation[locationKey]![concern] ?? 0) + 1;
        }
      }

      // Convert to data lists
      setState(() {
        diseaseData = diseaseCounts.entries
            .map((entry) => DiseaseData(entry.key, entry.value))
            .toList();

        locationData = cityCounts.entries
            .map((entry) => LocationData(entry.key, entry.value))
            .toList();

        illnessesByLocation = tempIllnessesByLocation;

        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }



  Future<String> fetchCityFromCoordinates(double lat, double lon) async {
    try {
      final response = await http.get(Uri.parse(
          'http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$lat,$lon'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['location']['name'] ?? 'Unknown'; // City name
      }
      return 'Unknown'; // Return 'Unknown' if city cannot be determined
    } catch (e) {
      print("Error fetching city name: $e");
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Illness Concentration'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Pie Chart for Disease Distribution
                  Container(
                    height: 500,
                    child: SfCircularChart(
                      title: ChartTitle(text: 'Disease Distribution'),
                      legend: Legend(isVisible: true),
                      series: <CircularSeries>[
                        PieSeries<DiseaseData, String>(
                          dataSource: diseaseData,
                          xValueMapper: (DiseaseData disease, _) => disease.name,
                          yValueMapper: (DiseaseData disease, _) => disease.count,
                          dataLabelSettings: DataLabelSettings(isVisible: true),
                        )
                      ],
                    ),
                  ),

                  // List of Total Illnesses
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Illnesses:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ...diseaseData.map((disease) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                '- ${disease.name}: ${disease.count}',
                                style: TextStyle(fontSize: 16),
                              ),
                            )),
                      ],
                    ),
                  ),

                  // Pie Chart for User City Distribution
                  Container(
                    height: 500,
                    child: SfCircularChart(
                      title: ChartTitle(text: 'User City Distribution'),
                      legend: Legend(isVisible: true),
                      series: <CircularSeries>[
                        PieSeries<LocationData, String>(
                          dataSource: locationData,
                          xValueMapper: (LocationData location, _) =>
                              location.name,
                          yValueMapper: (LocationData location, _) =>
                              location.count,
                          dataLabelSettings: DataLabelSettings(isVisible: true),
                        )
                      ],
                    ),
                  ),

                  // List of Cities and Illnesses with Counts
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: illnessesByLocation.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key}:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              ...entry.value.entries.map((illnessEntry) =>
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: Text(
                                      '- ${illnessEntry.key}: ${illnessEntry.value}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  )),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class DiseaseData {
  final String name;
  final int count;

  DiseaseData(this.name, this.count);
}

class LocationData {
  final String name; // City name
  final int count;

  LocationData(this.name, this.count);
}
