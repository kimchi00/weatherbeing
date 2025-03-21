import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ChecklistPage extends StatefulWidget {
  @override
  _ChecklistScreenState createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistPage> {
  int waterIntake = 0;
  final List<Map<String, dynamic>> _todoList = [];
  final List<Map<String, dynamic>> _activeGoals = [];
  final List<Map<String, dynamic>> _completedGoals = [];
  
  

  void _showEditToDoDialog(int index) {
  String? editedTitle = _todoList[index]['title'];
  String? editedBody = _todoList[index]['body'];

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Edit To-Do'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) {
                editedTitle = value;
              },
              controller: TextEditingController(text: _todoList[index]['title']),
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              onChanged: (value) {
                editedBody = value;
              },
              controller: TextEditingController(text: _todoList[index]['body']),
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (editedTitle != null && editedTitle!.isNotEmpty) {
                setState(() {
                  _todoList[index]['title'] = editedTitle!;
                  _todoList[index]['body'] = editedBody ?? '';
                });
              }
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}

  void _incrementWaterIntake() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Fetch the last completion timestamp from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        Timestamp? lastCompletionTimestamp = userData?['lastWaterCompletion'];

        if (lastCompletionTimestamp != null) {
          DateTime lastCompletion = lastCompletionTimestamp.toDate();
          DateTime now = DateTime.now();

          // Check if 24 hours have passed
          if (now.difference(lastCompletion).inHours < 24) {
            _showMessage(
                "You can only complete your water intake goal once every 24 hours. Try again later!");
            return;
          }
        }

        // Increment water intake
        setState(() {
          waterIntake++;
          if (waterIntake == 8) {
            _showCongratulatoryMessage(); // Show the message when goal is reached
          }
        });
      } catch (e) {
        print('Error checking last completion: $e');
      }
    }
  }


  void _decrementWaterIntake() {
    if (waterIntake > 0) {
      setState(() {
        waterIntake--;
      });
    }
  }

  void _showMessage(String message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}


  void _showCongratulatoryMessage() {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Congratulations!'),
            content: Text(
                'You have reached your daily water intake goal! Keep up the good work!'),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Increment points by 1 in Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({
                      'points': FieldValue.increment(1), // Add 1 point
                      'lastWaterCompletion': Timestamp.now(), // Update timestamp
                    });

                    print('1 point added for completing water intake goal.');
                  } catch (e) {
                    print('Failed to update points: $e');
                  }

                  setState(() {
                    waterIntake = 0; // Reset the water intake bar
                  });

                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }



  void _showWaterIntakeExplanation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Water Intake Explanation'),
          content: Text(
              'This is the number of optimal daily water intake advised for you.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showGoalsExplanation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Your Goals'),
          content: Text('Set your own goals to earn more points!'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

void _showAddToDoDialog() {
  showModalBottomSheet(
    isScrollControlled: true, // Allows the dialog to resize with the keyboard
    context: context,
    builder: (context) {
      String? newTitle;
      String? newBody;

      return Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  newTitle = value;
                },
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                onChanged: (value) {
                  newBody = value;
                },
                maxLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: () {
                        if (newTitle != null && newTitle!.isNotEmpty) {
                          _addToDoItem(newTitle!, newBody ?? '');
                        }
                        Navigator.pop(context);
                      },
                      child: Text('Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
  // Add to the active goals
void _addToDoItem(String title, String body) async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    String goalId = Uuid().v4(); // Generate a unique ID for the goal
    DateTime createdAt = DateTime.now(); // Store the current time when the goal is added
    Map<String, dynamic> newGoal = {
      'id': goalId,
      'title': title,
      'body': body,
      'isDone': false,
      'createdAt': createdAt, // Add createdAt timestamp to the goal
    };

    try {
      // Add the goal to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'goals': FieldValue.arrayUnion([newGoal]) // Add new goal to the array
      });

      // Add the goal to the local active list
      setState(() {
        _activeGoals.insert(0, newGoal);
      });

      print('Goal added successfully!');

      // Set a reminder after 24 hours to remind the user to complete the goal
      Future.delayed(const Duration(hours: 24), () {
        _showGoalReminder(goalId); // Show reminder popup after 24 hours
      });

    } catch (e) {
      print('Failed to add goal: $e');
    }
  } else {
    print('No user is logged in.');
  }
}

// Function to show a reminder pop-up
void _showGoalReminder(String goalId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Goal Reminder'),
        content: const Text('You have a goal that is pending. Please complete it!'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              // Handle goal completion or dismiss the reminder
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

  // Mark the goal as completed and move to completed goals list
  void _toggleToDoItem(int index) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Map<String, dynamic> updatedGoal = {
        ..._activeGoals[index],
        'isDone': !_activeGoals[index]['isDone'], // Toggle the isDone status
      };

      try {
        // Update the goal in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'goals': FieldValue.arrayRemove([_activeGoals[index]]),
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'goals': FieldValue.arrayUnion([updatedGoal]),
        });

        // Update the local list
        setState(() {
          _activeGoals[index] = updatedGoal;
          if (updatedGoal['isDone']) {
            _completedGoals.add(updatedGoal);
            _activeGoals.removeAt(index);
          }
        });
      } catch (e) {
        print('Failed to update goal: $e');
      }
    }
  }

  // Reuse completed goal and add it back to active goals
  void _reuseCompletedGoal(int index) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Map<String, dynamic> goalToReuse = _completedGoals[index];

      try {
        // Update goal status to active in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'goals': FieldValue.arrayUnion([goalToReuse]),
        });

        // Remove it from completed goals list
        setState(() {
          _completedGoals.removeAt(index);
          goalToReuse['isDone'] = false; // Reset completion status
          _activeGoals.add(goalToReuse);
        });
      } catch (e) {
        print('Failed to reuse goal: $e');
      }
    }
  }

  // Show dialog to confirm if user wants to reuse the completed goal
  void _showReuseGoalDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reuse this goal?'),
          content: Text('Do you want to move this goal back to your active list?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dismiss the dialog
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                _reuseCompletedGoal(index);
                Navigator.pop(context); // Dismiss the dialog
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

void _removeToDoItem(int index) async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    Map<String, dynamic> goalToRemove = _todoList[index];

    try {
      // Remove the goal from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'goals': FieldValue.arrayRemove([goalToRemove]) // Remove the goal
      });

      // Remove the goal from the local list
      setState(() {
        _todoList.removeAt(index);
      });

      print('Goal removed successfully!');
    } catch (e) {
      print('Failed to remove goal: $e');
    }
  } else {
    print('No user is logged in.');
  }
}


void _showCompletionMessage(int index) {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Well done!'),
          content: Text(
              'Keep up the good work to stay healthy and earn more points!'),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Map<String, dynamic> goalToComplete = _todoList[index];

                try {
                  // Increment points by 2 in Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'points': FieldValue.increment(2), // Add 2 points
                  });

                  // Remove the goal from Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'goals': FieldValue.arrayRemove([goalToComplete]),
                  });

                  print('2 points added for completing a goal.');
                } catch (e) {
                  print('Failed to update points or remove goal: $e');
                }

                // Remove the goal locally
                setState(() {
                  _todoList.removeAt(index);
                });

                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}






  int _selectedIndex = 2; 
  void _onItemTapped(int index) {
    // Navigate only if the selected tab changes
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index; // Update the selected index
      });

      // Navigate to the corresponding route
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/health');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/checklist');
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/profile');
          break;
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather-Being'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Water Intake Meter Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Water Intake Meter',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.info_outline),
                  onPressed: _showWaterIntakeExplanation,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: waterIntake,
                  child: Container(
                    height: 20,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  flex: 8 - waterIntake,
                  child: Container(
                    height: 20,
                    color: Colors.grey[300],
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _incrementWaterIntake,
                    ),
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: _decrementWaterIntake,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Water Intake: $waterIntake / 8 glasses',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),

            // Active Goals Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Goals',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.info_outline),
                  onPressed: _showGoalsExplanation,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _activeGoals.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      title: Text(
                        _activeGoals[index]['title'],
                        style: TextStyle(
                          decoration: _activeGoals[index]['isDone']
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      subtitle: Text(
                        _activeGoals[index]['body'] != null &&
                                _activeGoals[index]['body'].isNotEmpty
                            ? _activeGoals[index]['body'].split('\n').first
                            : '',
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: Checkbox(
                        value: _activeGoals[index]['isDone'],
                        onChanged: (value) {
                          _toggleToDoItem(index);
                        },
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _removeToDoItem(index),
                      ),
                      onTap: () => _showEditToDoDialog(index),
                    ),
                  );
                },
              ),
            ),
            
            // Completed Goals Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Completed Goals',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _completedGoals.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      title: Text(
                        _completedGoals[index]['title'],
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle: Text(
                        _completedGoals[index]['body'] != null &&
                                _completedGoals[index]['body'].isNotEmpty
                            ? _completedGoals[index]['body'].split('\n').first
                            : '',
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _showReuseGoalDialog(index),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddToDoDialog,
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}