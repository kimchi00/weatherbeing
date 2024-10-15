import 'package:flutter/material.dart';
import 'package:my_todo_app/main.dart';
//import 'main.dart';

class ChecklistPage extends StatefulWidget {
  @override
  _ChecklistScreenState createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistPage> {
  int waterIntake = 0;
  final List<Map<String, dynamic>> _todoList = [];

  void _incrementWaterIntake() {
    setState(() {
      waterIntake++;
      if (waterIntake == 13) {
        _showCongratulatoryMessage();
      }
    });
  }

  void _decrementWaterIntake() {
    if (waterIntake > 0) {
      setState(() {
        waterIntake--;
      });
    }
  }

  void _showCongratulatoryMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Congratulations!'),
          content: Text(
              'You have reached your daily water intake goal! Keep up the good work!'),
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

  void _showWaterIntakeExplanation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Water Intake Explanation'),
          content: Text(
              'These is the number of optimal daily water intake advised for the user.'),
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
          title: Text('Goals Explanation'),
          content: Text(
              'This part of the health checklist page contains the goals that the users set for themselves.'),
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
      context: context,
      builder: (context) {
        String? newTitle;
        String? newBody;
        return Padding(
          padding: const EdgeInsets.all(16.0),
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
                  //labelText: 'To-Do Body',
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
        );
      },
    );
  }

  void _showEditToDoDialog(int index) {
    String? editedTitle = _todoList[index]['title'];
    String? editedBody = _todoList[index]['body'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Edit To-Do',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  editedTitle = value;
                },
                controller:
                    TextEditingController(text: _todoList[index]['title']),
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
                controller:
                    TextEditingController(text: _todoList[index]['body']),
                maxLines: 5,
                decoration: InputDecoration(
                  //labelText: 'To-Do Body',
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
                        if (editedTitle != null && editedTitle!.isNotEmpty) {
                          _editToDoItem(index, editedTitle!, editedBody ?? '');
                        }
                        Navigator.pop(context);
                      },
                      child: Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _addToDoItem(String title, String body) {
    setState(() {
      _todoList.insert(0, {'title': title, 'body': body, 'isDone': false});
    });
  }

  void _editToDoItem(int index, String newTitle, String newBody) {
    setState(() {
      _todoList[index]['title'] = newTitle;
      _todoList[index]['body'] = newBody;
    });
  }

  void _removeToDoItem(int index) {
    setState(() {
      _todoList.removeAt(index);
    });
  }

  void _toggleToDoItem(int index) {
    setState(() {
      _todoList[index]['isDone'] = !_todoList[index]['isDone'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather-Being'),
        //automaticallyImplyLeading: false, // This removes the default back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                  flex: 13 -
                      waterIntake, //this is responsible for the display for the water intake meter
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
              'Water Intake: $waterIntake glasses',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Goals',
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
                itemCount: _todoList.length,
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
                        _todoList[index]['title'],
                        style: TextStyle(
                          decoration: _todoList[index]['isDone']
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      subtitle: Text(
                        _todoList[index]['body'] != null &&
                                _todoList[index]['body'].isNotEmpty
                            ? _todoList[index]['body'].split('\n').first
                            : '',
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: Checkbox(
                        value: _todoList[index]['isDone'],
                        onChanged: (value) {
                          _toggleToDoItem(index);
                        },
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons
                            .delete), //if I wanted to change the color of the delet icon to red just add (Icons.delete, color: Colors.red)
                        onPressed: () => _removeToDoItem(index),
                      ),
                      onTap: () => _showEditToDoDialog(index),
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
      //disregard this part, since I just tried using adding a bottom nav bar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety),
            label: 'Health',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_sharp),
            label: 'Checklist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
