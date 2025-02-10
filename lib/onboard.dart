import 'package:flutter/material.dart';
import 'package:weatherbeing/sex.dart';

class Onboard extends StatelessWidget {
  const Onboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with light grey color
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF1F1FA), // Light grey background color
            ),
          ),
          // Pink curved background
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7, // Cover 50% of the screen height
              decoration: const BoxDecoration(
                color: Color(0xFFFAAEC3), // Pink color
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(60), // Curves downwards
                  bottomRight: Radius.circular(60),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
                children: [
                  Image.asset(
                    'assets/images/logo.png', // Replace with your logo asset
                    height: 480, // Adjust the size to fit well inside the pink background
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Let's Get Started!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Text color
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Button with an arrow icon at the bottom right
          Positioned(
            bottom: 30,
            right: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(), // Circular button
                padding: const EdgeInsets.all(15), // Button padding
                backgroundColor: const Color(0xFFFF5C8A), // Pink button color
              ),
              onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SexSelection()), 
                    );
              },
              child: const Icon(
                Icons.arrow_forward, // Arrow icon
                size: 24,
                color: Colors.white, // White arrow color
              ),
            ),
          ),
        ],
      ),
    );
  }
}
