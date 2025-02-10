import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weatherbeing/bmi.dart';
import 'package:weatherbeing/onboard.dart';

class SexSelection extends StatefulWidget {
  const SexSelection({Key? key}) : super(key: key);

  @override
  _SexSelectionState createState() => _SexSelectionState();
}

class _SexSelectionState extends State<SexSelection> {
  String? _selectedSex;

  // Firestore and Auth instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to save the selected gender to Firestore
  Future<void> _saveSexToFirestore() async {
    // Get the current user
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        // Update user's document with the selected sex
        await _firestore.collection('users').doc(user.uid).update({
          'sex': _selectedSex,
        });
        print('User sex updated: $_selectedSex');
      } catch (e) {
        print('Error updating user sex: $e');
      }
    } else {
      print('No user is currently signed in.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image from assets
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/sex.png'),
                fit: BoxFit.cover, // Make sure the image covers the whole screen
              ),
            ),
          ),
          // Logo below the top
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/logo.png', // Replace with your actual logo asset
                height: 480,
              ),
            ),
          ),
          // Question and radio buttons for selecting sex
          Positioned(
            top: 300,
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Are you a male or female?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Change text color to white
                  ),
                ),
                const SizedBox(height: 20),
                // Radio buttons in a column
                Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text(
                        'Male',
                        style: TextStyle(color: Colors.white, fontSize: 24), // White text
                      ),
                      value: 'Male',
                      groupValue: _selectedSex,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedSex = value;
                        });
                      },
                      activeColor: const Color(0xFFFF5C8A), // Pink color for the selected radio
                    ),
                    RadioListTile<String>(
                      title: const Text(
                        'Female',
                        style: TextStyle(color: Colors.white, fontSize: 24), // White text
                      ),
                      value: 'Female',
                      groupValue: _selectedSex,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedSex = value;
                        });
                      },
                      activeColor: const Color(0xFFFF5C8A), // Pink color for the selected radio
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Navigation buttons at the bottom
          Positioned(
            bottom: 30,
            left: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
                backgroundColor: const Color(0xFFFF5C8A), // Pink color
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Onboard()),
                );
              },
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
                backgroundColor: const Color(0xFFFF5C8A), // Pink color
              ),
              onPressed: () {
                if (_selectedSex != null) {
                  _saveSexToFirestore(); // Save selected sex to Firestore
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BMIScreen()),
                  );
                } else {
                  // Show an alert or message that a selection must be made
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a gender.')),
                  );
                }
              },
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
