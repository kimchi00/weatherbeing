import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weatherbeing/checklist.dart';
import 'package:weatherbeing/healthmodule.dart';
import 'package:weatherbeing/homepage.dart';
import 'package:weatherbeing/main.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

    void _onItemTapped(int index) {
    setState(() {
    });

    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HealthModule()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChecklistPage()),
      );
    }
  }

  Future<void> _loadUserData() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data()!;
      
      setState(() {
        name = userData['name'];
        age = userData['age'];
        gender = userData['sex'];
        height = double.parse(userData['height'].toString());
        weight = double.parse(userData['weight'].toString());
        bmi = _calculateBMI(weight, height);
        healthConcerns = List<String>.from(userData['health_concerns'] ?? []);
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
          child: Icon(Icons.person, size: 60, color: Colors.pinkAccent),
        ),
        SizedBox(height: 10),
        Text(
          name,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        TextButton(
          onPressed: () {},
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
            '30 pts.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        _buildAchievement('30 points - Health Adept', Colors.purple),
        _buildAchievement('20 points - Health Apprentice', Colors.pink),
        _buildAchievement('10 points - Health Novice', Colors.red),
      ],
    );
  }

  Widget _buildAchievement(String text, Color color) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: color),
        SizedBox(width: 10),
        Text(text),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        _buildInfoRow('Age', age.toString()),
        _buildInfoRow('Gender', gender),
        _buildInfoRow('BMI', bmi.toStringAsFixed(2)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoColumn('Height', '${height.toStringAsFixed(2)} m'),
            _buildInfoColumn('Weight', '${weight.toStringAsFixed(2)} kg'),
          ],
        ),
      ],
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
        Text('Health concerns:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Wrap(
          spacing: 10.0,
          children: healthConcerns
              .map((concern) => Chip(
                    label: Text(concern),
                    backgroundColor: Colors.pinkAccent.withOpacity(0.2),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSettingsAndSignOut() {
    return Column(
      children: [
        TextButton.icon(
          onPressed: () {},
          icon: Icon(Icons.settings, color: Colors.black),
          label: Text('Settings', style: TextStyle(color: Colors.black)),
        ),
        SizedBox(height: 10),
        TextButton.icon(
          onPressed: () async {
            await _auth.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MyHomePage()),
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
      currentIndex: 3,
      onTap: _onItemTapped, // This handles the tap and navigation logic
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
}
