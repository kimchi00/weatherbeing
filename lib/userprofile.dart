import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weatherbeing/main.dart';
import 'package:weatherbeing/settings.dart';

class UserProfile extends StatefulWidget {
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String name = '';
  int age = 0;
  String gender = '';
  double height = 0.0;
  double weight = 0.0;
  double bmi = 0.0;
  List<String> healthConcerns = [];
  int points = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

 int _selectedIndex = 3; // This tracks the currently selected tab
  void _onItemTapped(int index) {
    // Navigate only if the selected tab changes
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index; // Update the selected index
      });

      // Navigate to the corresponding route
      switch (index) {
        case 0:
          Navigator.pushNamed(context, '/home');
          break;
        case 1:
          Navigator.pushNamed(context, '/health');
          break;
        case 2:
          Navigator.pushNamed(context, '/checklist');
          break;
        case 3:
          Navigator.pushNamed(context, '/profile');
          break;
      }
    }
  }

Future<void> _loadUserData() async {
  final currentUser = _auth.currentUser;
  if (currentUser != null) {
    final userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
    final userData = userDoc.data();

    setState(() {
      if (userData != null) {
        name = userData['name'] ?? '';
        age = userData['age'] ?? 0;
        gender = userData['sex'] ?? '';
        height = double.tryParse(userData['height']?.toString() ?? '0') ?? 0.0;
        weight = double.tryParse(userData['weight']?.toString() ?? '0') ?? 0.0;
        bmi = _calculateBMI(weight, height);
        healthConcerns = List<String>.from(userData['health_concerns'] ?? []);
        // Get points or initialize to 0 if not present
        points = userData['points'] ?? 0;
      }
    });
  }
}


  double _calculateBMI(double weight, double height) {
    return weight / (height * height);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('User Profile', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeader(),
            SizedBox(height: 20),
            _buildAchievements(),
            SizedBox(height: 20),
            _buildUserInfo(),
            SizedBox(height: 20),
            _buildHealthConcerns(),
            SizedBox(height: 20),
            _buildSettingsAndSignOut(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

Widget _buildHeader() {
  return Column(
    children: [
      CircleAvatar(
        radius: 50,
        backgroundColor: Colors.pinkAccent.withOpacity(0.3),
        backgroundImage: AssetImage(
          gender.toLowerCase() == 'male' ? 'assets/images/man.png' : 'assets/images/woman.png',
        ),
      ),
      SizedBox(height: 10),
      Text(
        name,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 10),
      TextButton(
        onPressed:  _showEditProfileDialog,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Edit Profile",
              style: TextStyle(color: Colors.black54),
            ),
            Icon(Icons.edit, color: Colors.black54),
          ],
        ),
      ),
      SizedBox(height: 10),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.pinkAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$points ${points == 1 ? 'point' : 'points'}', // Dynamically set singular or plural
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}





  Widget _buildAchievements() {
    final achievements = [
      {'points': 20, 'title': 'Health Novice', 'color': Colors.red},
      {'points': 40, 'title': 'Health Apprentice', 'color': Colors.pink},
      {'points': 60, 'title': 'Health Adept', 'color': Colors.purple},
      {'points': 80, 'title': 'Health Enthusiast', 'color': Colors.blue},
      {'points': 100, 'title': 'Health Champion', 'color': Colors.green},
      {'points': 120, 'title': 'Health Master', 'color': Colors.teal},
      {'points': 140, 'title': 'Health Guru', 'color': Colors.orange},
      {'points': 160, 'title': 'Health Sage', 'color': Colors.amber},
      {'points': 180, 'title': 'Health Legend', 'color': Colors.brown},
      {'points': 200, 'title': 'Health Icon', 'color': Colors.black},
    ];

    // Filter the achievements user has earned
    final earnedAchievements = achievements
        .where((achievement) => points >= (achievement['points'] as int))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        if (earnedAchievements.isEmpty)
          Center(
            child: Text(
              'Earn more points to earn your first title and achievement!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          )
        else
          ...earnedAchievements.map((achievement) => _buildAchievement(
                '${achievement['points']} points - ${achievement['title']}',
                achievement['color'] as Color,
              )),
      ],
    );
  }


Widget _buildAchievement(String text, Color color) {
  return Row(
    children: [
      Icon(Icons.check_circle, color: color),
      SizedBox(width: 10),
      Text(text, style: TextStyle(fontSize: 14)),
    ],
  );
}


Widget _buildUserInfo() {
  return Column(
    children: [
      _buildInfoRow('Age', age.toString()),
      _buildInfoRow('Gender', gender),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoColumn('Height', '${height.toStringAsFixed(2)} m'),
          _buildInfoColumn('Weight', '${weight.toStringAsFixed(2)} kg'),
        ],
      ),
      _buildInfoRowWithIcon(
        'BMI',
        '${bmi.toStringAsFixed(2)} (${_getBMICategory(bmi)})',
        Icons.info_outline,
        _showBMIExplanation, // Call the explanation dialog
      ),
    ],
  );
}

String _getBMICategory(double bmi) {
  if (bmi < 18.5) {
    return 'Underweight';
  } else if (bmi < 24.9) {
    return 'Normal';
  } else if (bmi < 29.9) {
    return 'Overweight';
  } else {
    return 'Obese';
  }
}



  Widget _buildInfoRowWithIcon(
    String title, String value, IconData icon, VoidCallback onIconPressed) {
  return Container(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(title, style: TextStyle(fontSize: 16)),
            SizedBox(width: 5),
            IconButton(
              icon: Icon(icon, color: Colors.grey, size: 20),
              onPressed: onIconPressed,
            ),
          ],
        ),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

void _showBMIExplanation() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('What is BMI?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BMI (Body Mass Index) is a measure of body fat based on height and weight. It is calculated using the formula:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              'BMI = Weight (kg) / (Height (m) * Height (m))',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              'Categories:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 5),
            Text('• Underweight: < 18.5', style: TextStyle(fontSize: 14)),
            Text('• Normal weight: 18.5 - 24.9', style: TextStyle(fontSize: 14)),
            Text('• Overweight: 25 - 29.9', style: TextStyle(fontSize: 14)),
            Text('• Obesity: >= 30', style: TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text('Close'),
          ),
        ],
      );
    },
  );
}




  Widget _buildInfoRow(String title, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16)),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildHealthConcerns() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Health concerns:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.black54),
            onPressed: _editHealthConcernsDialog, // Call an edit dialog or function
          ),
        ],
      ),
      SizedBox(height: 10),
      Wrap(
        spacing: 10.0,
        children: healthConcerns.isNotEmpty
            ? healthConcerns
                .map((concern) => Chip(
                      label: Text(concern),
                      backgroundColor: Colors.pinkAccent.withOpacity(0.2),
                    ))
                .toList()
            : [
                Text(
                  'No health concerns added.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
      ),
    ],
  );
}


  Widget _buildSettingsAndSignOut() {
    return Column(
      children: [
        // Settings Button
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UpdateCredentialsPage()), // Redirect to FuzzyPage
            );
          },
          icon: Icon(Icons.settings, color: Colors.black),
          label: Text('Settings', style: TextStyle(color: Colors.black)),
        ),
        SizedBox(height: 10),
        // Sign Out Button
        TextButton.icon(
          onPressed: () async {
            await _auth.signOut();  // Sign out the user
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MyHomePage()),  // Redirect to home after sign out
            );
          },
          icon: Icon(Icons.logout, color: Colors.black),
          label: Text('Sign out', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }


  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.pinkAccent,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      currentIndex: _selectedIndex, // Dynamically updates the selected tab
      onTap: _onItemTapped, // Handles navigation and tab selection
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Health',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle),
          label: 'Checklist',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

void _editHealthConcernsDialog() {
  final allConcerns = [
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
    'Allergies',
  ];

  // Create a copy of the user's current concerns for toggling
  List<String> modifiedConcerns = List<String>.from(healthConcerns);

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Health Concerns'),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: allConcerns.map((concern) {
                  final isSelected = modifiedConcerns.contains(concern);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          modifiedConcerns.remove(concern);
                        } else {
                          modifiedConcerns.add(concern);
                        }
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.pinkAccent
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        concern,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Update Firebase with modified concerns
                    await _firestore
                        .collection('users')
                        .doc(_auth.currentUser!.uid)
                        .update({'health_concerns': modifiedConcerns});

                    // Update the parent's state directly
                    setState(() {
                      healthConcerns = modifiedConcerns;
                    });

                    Navigator.pop(context); // Close the dialog

                    setState(() {
                      healthConcerns = modifiedConcerns;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Health concerns updated successfully!'),
                    ));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to update health concerns: $e'),
                    ));
                  }
                },
                child: Text('Okay'),
              ),
            ],
          );
        },
      );
    },
  );
}



////////////////////////////////////////////////////////////////////////////////
///              Edit Profile Code                                           ///
////////////////////////////////////////////////////////////////////////////////

void _showEditProfileDialog() {
  final TextEditingController nameController =
      TextEditingController(text: name);
  final TextEditingController ageController =
      TextEditingController(text: age.toString());
  final TextEditingController heightController =
      TextEditingController(text: height.toStringAsFixed(2));
  final TextEditingController weightController =
      TextEditingController(text: weight.toStringAsFixed(2));

  String selectedGender = gender;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Age'),
              ),
              DropdownButtonFormField<String>(
                value: selectedGender,
                items: ['Male', 'Female', 'Other']
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedGender = value!;
                },
                decoration: InputDecoration(labelText: 'Gender'),
              ),
              TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Height (m)'),
              ),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Weight (kg)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final updatedName = nameController.text.trim();
                final updatedAge = int.tryParse(ageController.text) ?? age;
                final updatedHeight =
                    double.tryParse(heightController.text) ?? height;
                final updatedWeight =
                    double.tryParse(weightController.text) ?? weight;

                await _firestore
                    .collection('users')
                    .doc(_auth.currentUser!.uid)
                    .update({
                  'name': updatedName,
                  'age': updatedAge,
                  'sex': selectedGender,
                  'height': updatedHeight,
                  'weight': updatedWeight,
                });

                setState(() {
                  name = updatedName;
                  age = updatedAge;
                  gender = selectedGender;
                  height = updatedHeight;
                  weight = updatedWeight;
                  bmi = _calculateBMI(updatedWeight, updatedHeight);
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Profile updated successfully!'),
                ));
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Failed to update profile: $e'),
                ));
              }
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}

}


