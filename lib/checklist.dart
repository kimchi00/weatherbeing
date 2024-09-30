import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:weatherbeing/healthmodule.dart';
import 'package:weatherbeing/homepage.dart';
import 'package:weatherbeing/userprofile.dart';

class ChecklistPage extends StatefulWidget {
  @override
  _ChecklistPageState createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final TextEditingController _goalTitleController = TextEditingController();
  final TextEditingController _goalDescriptionController = TextEditingController();
  bool _showGoalInput = false; // Track whether to show the goal input

  Future<void> _saveGoal() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).collection('goals').add({
        'title': _goalTitleController.text,
        'description': _goalDescriptionController.text,
        'completed': false,
        'timestamp': Timestamp.now(),
      });
      _goalTitleController.clear();
      _goalDescriptionController.clear();
    }
  }

    void _onItemTapped(int index) {
    setState(() {
    });

    // Check if the Health tab is tapped
    if (index == 0) {
      // Navigate to HealthModule when Health is selected
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HealthModule()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserProfile()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F6FA),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo2.png', // Adjust the path as needed
              height: 40,
            ),
            SizedBox(width: 10),
            Text(
              'Weather-Being',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Water Intake Section
            _buildWaterIntakeSection(),
            SizedBox(height: 20),

            // Goals Section
            _buildGoalsSection(),

            SizedBox(height: 20),

            // Show Goal Input Section
            _showGoalInput ? _buildGoalInputSection() : Container(),

            // Floating Action Button
            _buildAddGoalButton(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildWaterIntakeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Water intake',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Icon(Icons.info_outline, color: Colors.grey),
      ],
    );
  }

  Widget _buildGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Goals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Icon(Icons.info_outline, color: Colors.grey),
          ],
        ),
        SizedBox(height: 10),
        // Goals list would go here - dynamically populate from Firestore
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .collection('goals')
              .orderBy('timestamp', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            final goals = snapshot.data!.docs;
            List<Widget> goalWidgets = [];
            for (var goal in goals) {
              final goalTitle = goal['title'];
              final goalDescription = goal['description'];
              final completed = goal['completed'];

              goalWidgets.add(_buildGoalCard(goalTitle, goalDescription, completed));
            }
            return Column(
              children: goalWidgets,
            );
          },
        ),
      ],
    );
  }

  Widget _buildGoalCard(String title, String description, bool completed) {
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: completed,
          onChanged: (bool? value) {
            // Update goal completion status in Firestore
            setState(() {
              completed = value!;
            });
          },
        ),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildGoalInputSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _goalTitleController,
            decoration: InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: _goalDescriptionController,
            decoration: InputDecoration(
              labelText: 'Input new goal here',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  _saveGoal();
                  setState(() {
                    _showGoalInput = false;
                  });
                },
                child: Icon(Icons.check),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showGoalInput = false;
                  });
                },
                child: Icon(Icons.close),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddGoalButton() {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          _showGoalInput = !_showGoalInput;
        });
      },
      child: Icon(Icons.add),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.pinkAccent,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      currentIndex: 2,
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
