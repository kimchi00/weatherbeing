import 'package:flutter/material.dart';
import 'map.dart';

class MapWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the width of the device screen
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Illness Concentration'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Container for the Map Image
          Container(
            width: screenWidth * 0.9, // 90% of the device's screen width
            height: 450, // Adjust height proportional to width
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black12, // Border color
                width: 2, // Border width
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: InteractiveViewer(
              boundaryMargin: EdgeInsets.all(100),
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.asset(
                'assets/images/provinces-2k.png', // Path to your image
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 16), // Spacing between map and text box

          // Container for the text or other content
          Container(
            width: screenWidth * 0.9, // 90% of the device's screen width
            height: 150,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.pink[100], // Background color
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Lorem ipsum dolor sit amet consectetur. Nulla pretium diam in dui dui ipsum.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
