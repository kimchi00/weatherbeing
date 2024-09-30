import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For filtering input
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weatherbeing/healthconcern.dart'; // Firestore for saving data

class BMIScreen extends StatelessWidget {
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  BMIScreen({super.key});

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
                fit: BoxFit.cover, // Makes sure the image covers the entire screen
              ),
            ),
          ),
          // Logo at the top center (Positioned and Centered)
          Positioned(
            top: -20, // Adjust this value to control how much above or below the image should be
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/logo.png', // Replace with your actual logo asset
                height: 480, // Adjust height as needed
              ),
            ),
          ),
          // Input fields and buttons
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 1), // Adjust spacing if needed (pushed down after the logo)
              // Height Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What is your height?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), // Accept digits and period
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Please enter your height in meters',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20),
                        ),
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
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), // Accept digits and period
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Please enter your weight in kilograms',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Back and Next buttons at the bottom
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
                    backgroundColor: const Color(0xFFFF5C8A), // Button color
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                  onPressed: () {
                    // Handle back action
                  },
                  child: const Icon(Icons.arrow_back),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    backgroundColor: const Color(0xFFFF5C8A), // Button color
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                  onPressed: () async {
                    // Handle save to Firebase action
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
    // Get the currently signed-in user
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Parse height and weight from input fields
        double? height = double.tryParse(heightController.text);
        double? weight = double.tryParse(weightController.text);

        if (height != null && weight != null && height > 0) {
          // Calculate BMI
          double bmi = weight / (height * height);

          // Save the height, weight, and BMI data to Firestore
          await FirebaseFirestore.instance
              .collection('users') // Collection name, adjust if necessary
              .doc(user.uid) // Use the user's UID as the document ID
              .set({
            'height': height, // Save height
            'weight': weight, // Save weight
            'bmi': bmi,       // Save BMI
          }, SetOptions(merge: true)); // Merge to update existing data without overwriting

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
