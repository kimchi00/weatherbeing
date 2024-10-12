import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:weatherbeing/algotest.dart';
import 'package:weatherbeing/homepage.dart';
import 'package:weatherbeing/signin.dart';
import 'package:weatherbeing/signup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBhXyTUgfXqdqxOvv3RHykUHECWWE3cZLw",
      appId: "1:749917510033:android:e54bb30bab35d3fb3aa230",
      messagingSenderId: "749917510033",
      projectId: "weatherbeing-987a3",
      storageBucket: "weatherbeing-987a3.appspot.com",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather-Being',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home:  const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with the curved shape
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF1F1FA), 
            ),
          ),
          Align(
            alignment: Alignment.topCenter, // Aligning the grey container to the top
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Color(0xFFFAAEC3),  
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(60), // Curves downwards
                  bottomRight: Radius.circular(60),
                ),
              ),
            ),
          ),
          // Logo and title in the center
          Center( // Wrap Column with Center
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 480, // Adjust height to fit the logo size
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          // Sign in and Sign up buttons at the bottom
          Positioned(
            bottom: 50,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    backgroundColor: const Color(0xFFFF5C8A), // Button color
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignIn()), // Navigating to the SignIn/Login page
                    );
                  },
                  child: const Text(
                    'Sign in',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    backgroundColor: const Color(0xFFFF5C8A),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUp()), // Navigating to the SignUp page
                    );
                  },
                  child: const Text(
                    'Sign up',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
