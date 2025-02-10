import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'onboard.dart'; 

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _statusMessage;
  bool _isSuccess = false;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _statusMessage = 'Passwords do not match';
        _isSuccess = false;
      });
      return;
    }

    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Calculate age
      DateTime dob = DateTime.parse(_dobController.text);
      int age = _calculateAge(dob);

      // Save user information in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': _nameController.text.trim(),
        'age': age, // Storing calculated age
        'email': _emailController.text.trim(),
        'health_concerns': [], // Initialize health_concerns as an empty list
      });

      // Clear the form fields after a successful sign-up
      setState(() {
        _statusMessage = 'Sign-up successful! Redirecting...';
        _isSuccess = true;
        _nameController.clear();
        _dobController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
      });

      // Wait for 1 second and navigate to the Onboard page
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Onboard()), // Navigating to Onboard page
        );
      });
    } on FirebaseAuthException catch (e) {
      // Handle Firebase authentication errors
      setState(() {
        _statusMessage = e.message;
        _isSuccess = false;
      });
    } catch (e) {
      // Handle general errors
      setState(() {
        _statusMessage = 'An error occurred. Please try again.';
        _isSuccess = false;
      });
    }
  }

// Method to calculate age based on the date of birth
int _calculateAge(DateTime dob) {
  DateTime today = DateTime.now();
  int age = today.year - dob.year;

  if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
    age--;
  }

  return age;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16.0),

              // Date of birth field
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(labelText: 'Date of Birth'),
                keyboardType: TextInputType.datetime,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dobController.text = "${pickedDate.toLocal()}".split(' ')[0];
                    });
                  }
                },
              ),
              const SizedBox(height: 16.0),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16.0),

              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16.0),

              // Re-enter password field
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Re-enter Password'),
                obscureText: true,
              ),
              const SizedBox(height: 24.0),

              // Status message (error or success)
              if (_statusMessage != null)
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 16.0),

              // Sign Up button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _signUp();
                  }
                },
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
