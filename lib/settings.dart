import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weatherbeing/main.dart';


class UpdateCredentialsPage extends StatefulWidget {
  @override
  _UpdateCredentialsPageState createState() => _UpdateCredentialsPageState();
}

class _UpdateCredentialsPageState extends State<UpdateCredentialsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _updateInformation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;

      if (user == null) {
        _showMessage("No user is currently logged in.");
        return;
      }

      // Validate email format
      if (_emailController.text.isNotEmpty &&
          !_emailController.text.contains('@')) {
        _showMessage("Please enter a valid email.");
        return;
      }

      // Validate passwords match and are not empty
      if (_passwordController.text.isNotEmpty &&
          _passwordController.text != _confirmPasswordController.text) {
        _showMessage("Passwords do not match.");
        return;
      }

      // Update email if provided
      if (_emailController.text.isNotEmpty) {
        await user.verifyBeforeUpdateEmail(_emailController.text);
        _showMessage(
            "A verification email has been sent to ${_emailController.text}. Please verify it to complete the email update.");
      }

      // Update password if provided
      if (_passwordController.text.isNotEmpty) {
        if (_passwordController.text.length < 6) {
          _showMessage("Password must be at least 6 characters long.");
          return;
        }
        await user.updatePassword(_passwordController.text);
        _showMessage("Password updated successfully.");
      }

      if (_emailController.text.isEmpty && _passwordController.text.isEmpty) {
        _showMessage("Please enter new email or password to update.");
      }
    } catch (e) {
      _showMessage("Failed to update information: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;

      if (user == null) {
        _showMessage("No user is currently logged in.");
        return;
      }

      // Firestore reference
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Delete user data from Firestore
      await userDocRef.delete();
      print("User data deleted from Firestore.");

      // Delete user from Firebase Authentication
      await user.delete();
      print("User account deleted successfully.");

      _showMessage("Account and data deleted successfully.");

      // Navigate to MyHomePage
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyHomePage()),
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      print("Error during account deletion: $e");
      _showMessage("Failed to delete account: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Credentials'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'New Email (optional)',
                prefixIcon: const Icon(Icons.email),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'New Password (optional)',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _updateInformation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Update Information',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
            const Spacer(),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Delete Account',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
