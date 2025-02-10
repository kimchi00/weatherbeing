import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weatherbeing/healthconcern.dart';
import 'package:weatherbeing/sex.dart';

class BMIScreen extends StatefulWidget {
  BMIScreen({super.key});

  @override
  _BMIScreenState createState() => _BMIScreenState();
}

class _BMIScreenState extends State<BMIScreen> {
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  String heightUnit = 'Meters'; // Default unit for height
  String weightUnit = 'Kilograms'; // Default unit for weight

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bmi.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Logo at the top center
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 480,
              ),
            ),
          ),
          // Input fields and buttons
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 1),
              // Height Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What is your height?',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: heightController,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                hintText: 'Enter your height',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: heightUnit,
                            onChanged: (value) {
                              setState(() {
                                heightUnit = value!;
                              });
                            },
                            items: const [
                              DropdownMenuItem(value: 'Meters', child: Text('Meters')),
                              DropdownMenuItem(value: 'Centimeters', child: Text('Centimeters')),
                              DropdownMenuItem(value: 'Feet/Inches', child: Text('Feet/Inches')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Weight Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What is your weight?',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: weightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                              ],
                              decoration: const InputDecoration(
                                hintText: 'Enter your weight',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: weightUnit,
                            onChanged: (value) {
                              setState(() {
                                weightUnit = value!;
                              });
                            },
                            items: const [
                              DropdownMenuItem(value: 'Kilograms', child: Text('Kilograms')),
                              DropdownMenuItem(value: 'Pounds', child: Text('Pounds')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Back and Next buttons
          Positioned(
            bottom: 50,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    backgroundColor: const Color(0xFFFF5C8A),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SexSelection()),
                    );
                  },
                  child: const Icon(Icons.arrow_back),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    backgroundColor: const Color(0xFFFF5C8A),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: () async {
                    await _saveDataToFirebase();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HealthConcernsScreen()),
                    );
                  },
                  child: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDataToFirebase() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        double? weight = double.tryParse(weightController.text);
        String heightInput = heightController.text;

        double? heightInMeters;
        double? weightInKilograms;

        // Convert height to meters
        if (heightUnit == 'Meters') {
          heightInMeters = double.tryParse(heightInput);
        } else if (heightUnit == 'Centimeters') {
          heightInMeters = double.tryParse(heightInput)! / 100;
        } else if (heightUnit == 'Feet/Inches') {
          List<String> parts = heightInput.split("'");
          if (parts.length == 2) {
            double feet = double.tryParse(parts[0].trim()) ?? 0;
            double inches = double.tryParse(parts[1].trim()) ?? 0;
            heightInMeters = (feet * 12 + inches) * 0.0254;
          }
        }

        // Convert weight to kilograms
        if (weightUnit == 'Kilograms') {
          weightInKilograms = weight;
        } else if (weightUnit == 'Pounds') {
          weightInKilograms = weight! * 0.453592;
        }

        if (heightInMeters != null && weightInKilograms != null && heightInMeters > 0) {
          double bmi = weightInKilograms / (heightInMeters * heightInMeters);

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'height': heightInMeters,
            'weight': weightInKilograms,
            'bmi': bmi,
          }, SetOptions(merge: true));

          print("Height, Weight, and BMI saved successfully");
        } else {
          print("Invalid input for height or weight");
        }
      } catch (e) {
        print("Error saving data to Firebase: $e");
      }
    } else {
      print("No user is signed in");
    }
  }
}
