import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:weatherbeing/checklist.dart';
import 'package:weatherbeing/healthmodule.dart';
import 'package:weatherbeing/homepage.dart';
import 'package:weatherbeing/signin.dart';
import 'package:weatherbeing/signup.dart';
import 'package:weatherbeing/userprofile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCOB9l8un8-xy_NAok6qDCPjzzuDudDDOk",
      appId: "1:883465778101:android:3e4e08b811d46d2d171ffc",
      messagingSenderId: "883465778101",
      projectId: "weatherbeingg",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather-Being',
      theme: ThemeData(
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(),
        '/home': (context) =>  HomePage(),
        '/health': (context) => HealthModule(),
        '/checklist': (context) => ChecklistPage(),
        '/profile': (context) => UserProfile(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('404 - Page Not Found'),
            ),
            body: Center(
              child: Text('The page ${settings.name} does not exist.'),
            ),
          ),
        );
      },
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
