import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weatherbeing/congrats.dart';

class HealthConcernsScreen extends StatefulWidget {
  const HealthConcernsScreen({super.key});

  @override
  _HealthConcernsScreenState createState() => _HealthConcernsScreenState();
}

class _HealthConcernsScreenState extends State<HealthConcernsScreen> {
  // List of health concerns
  final List<String> _healthConcerns = [
    'Ischemic heart disease',
    'Acute respiratory tract infection',
    'Aneurysm',
    'Hypertension',
    'Diabetes',
    'Pneumonia',
    'Diarrhea',
    'Bronchitis',
    'Tuberculosis',
    'Urinary tract infection',
    'Asthma',
    'Chickenpox',
    'Conjunctivitis',
    'Flu',
    'Common cold',
    'Food poisoning',
    'Heatstroke',
    'Measles',
    'Eczema',
    'Heat rash',
    'Skin allergy',
    'Allergies',
  ];

  // Set to track selected health concerns
  final Set<String> _selectedConcerns = {};

  // Firebase Auth and Firestore instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save selected concerns to Firebase Firestore
  Future<void> _saveConcernsToFirestore() async {
    try {
      // Get the currently signed-in user
      User? user = _auth.currentUser;

      if (user != null) {
        // Save the selected health concerns under the user's document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'health_concerns': _selectedConcerns.toList(), // Save concerns as a list
        }, SetOptions(merge: true)); // Merge data so it doesn't overwrite the entire document

        // Navigate to congratulations screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CongratulationsScreen()), 
        );
      } else {
        // Show an error message if no user is signed in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is currently signed in.')),
        );
      }
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save health concerns: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFFC0CB), // Solid pink background color
        child: CustomScrollView(
          slivers: [
            // Sticky header: Logo and instruction text
            SliverPersistentHeader(
              pinned: true, // Makes the header sticky
              floating: true, // Allows header to float while scrolling
              delegate: _StickyHeaderDelegate(
                minHeight: 200.0, // Minimum height when scrolled
                maxHeight: 200.0, // Maximum height when at the top
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Image.asset(
                      'assets/images/logo2.png', // Replace with your logo path
                      height: 100,
                    ),
                  ],
                ),
              ),
            ),
            // Scrolling content: Health concerns grid
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 10.0, // Horizontal space between buttons
                      runSpacing: 10.0, // Vertical space between buttons
                      children: _healthConcerns.map((concern) {
                        final bool isSelected = _selectedConcerns.contains(concern);
                        return ChoiceChip(
                          label: Text(concern),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedConcerns.add(concern);
                              } else {
                                _selectedConcerns.remove(concern);
                              }
                            });
                          },
                          selectedColor: Colors.pinkAccent,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Back and Next buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
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
                            Navigator.pop(context); // Handle back action
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
                            // Save selected concerns to Firestore when pressing Next
                            await _saveConcernsToFirestore();
                          },
                          child: const Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A custom SliverPersistentHeaderDelegate to handle sticky headers
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.grey, // Set the entire sticky header's background to grey
      child: Column(
        children: [
          const SizedBox(height: 30),
          Image.asset(
            'assets/images/logo2.png', // Replace with your logo path
            height: 100,
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Please select any of the following health concerns that you may have.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxExtent ||
        minHeight != oldDelegate.minExtent ||
        child != (oldDelegate as _StickyHeaderDelegate).child;
  }
}
