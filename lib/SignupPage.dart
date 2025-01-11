import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartlocks/LockControlPage.dart';
import 'package:smartlocks/LoginPage.dart';
import 'myColors.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  String _accountType = 'user';  // Default selection
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _smartlockIdController = TextEditingController();
  final TextEditingController _secretCodeController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _lockNameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }
  Future<void> _sendRequest() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('lockRequests').add({
          'email': _auth.currentUser?.email ?? '',
          'lockId': _smartlockIdController.text.trim(),
          'lockName': _lockNameController.text.trim(),
          'status': 'waiting',  // Status when the request is first sent
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Request sent successfully.'),
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send request: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _signup() async {
    try {
      // Dismiss keyboard if open
      _dismissKeyboard();

      // Input validation
      if (_emailController.text.trim().isEmpty ||_nameController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty ||
          _pinController.text.trim().isEmpty) {
        _showSnackBar("All fields are required!");
        return;
      }

      // Check if the keypad code already exists
      bool isKeypadCodeTaken = await _checkIfKeypadCodeExists(_pinController.text.trim());
      if (isKeypadCodeTaken) {
        _showSnackBar("This keypad code is already in use. Please choose a different one.");
        return;
      }

      // Additional validation for admin users
      if (_accountType == 'admin') {
        if (_smartlockIdController.text.trim().isEmpty || _secretCodeController.text.trim().isEmpty) {
          _showSnackBar("SmartLock ID and Secret Code are required for admin accounts.");
          return;
        }

        // Validate SmartLock ID and secret code
        bool isValidSmartLock = await _validateSmartLock(
          _smartlockIdController.text.trim(),
          _secretCodeController.text.trim(),
          _emailController.text.trim(),
        );

        if (!isValidSmartLock) {
          _showSnackBar("SmartLock validation failed. Ensure the ID and secret code are correct.");
          return;
        }
      }

      // Create user account
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user == null) {
        _showSnackBar("Account creation failed. Please try again.");
        return;
      }

      // Save user details to Firestore
      Map<String, dynamic> userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'smartlockId': _smartlockIdController.text.trim(),
        'type': _accountType,
        'status': _accountType == 'admin' ? "active" : "pending",
        'keypadcode': _pinController.text.trim(),
      };

      if (_accountType == 'admin') {
        userData['lockName'] = _lockNameController.text.trim();
      } else {
        userData['lockName'] = null;
      }

      await _firestore.collection('users').doc(user.uid).set(userData);

      // Send lock request for non-admin users
      if (_accountType != 'admin') {
        await _sendRequest();
      }

      // Notify success and navigate
      _showSnackBar("Account created successfully!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LockControlPage()),
      );
    } catch (e) {
      print("Error during signup: $e");
      _showSnackBar("Error creating account: $e");
    }
  }

  Future<bool> _checkIfKeypadCodeExists(String keypadCode) async {
    try {
      // Check if the keypad code exists in Firestore
      QuerySnapshot snapshot = await _firestore
          .collection('users')  // Check the 'users' collection
          .where('smartlockId', isEqualTo: _smartlockIdController.text.trim())
          .where('keypadcode', isEqualTo: keypadCode)  // Look for matching keypad code
          .get();

      // If snapshot has any documents, the keypad code is already taken
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking keypad code: $e");
      return false;
    }
  }


  Future<bool> _validateSmartLock(String smartlockId, String secretCode, String email) async {
    try {
      // Try to fetch the document by its ID (SmartLock ID)
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('smartlocks')  // Replace 'smartlocks' with your Firestore collection name
          .doc(smartlockId)  // Use the SmartLock ID as the document ID
          .get();

      if (!documentSnapshot.exists) {
        // If the document does not exist, return false
        return false;
      }

      // Check if the secret code matches
      var storedSecretCode = documentSnapshot['secret_code'];  // Assuming 'secret_code' is the field name

      // Convert storedSecretCode to String if it's not already a String
      if (storedSecretCode is int) {
        storedSecretCode = storedSecretCode.toString();
      }

      if (storedSecretCode != secretCode) {
        // If the secret code does not match, return false
        return false;
      }

      // Check if admin already exists for this SmartLock
      var currentAdmin = documentSnapshot['admin'];

      if (currentAdmin != null && currentAdmin.isNotEmpty) {
        // If admin already exists, return false
        return false;
      }

      // If the secret code matches and admin does not exist, update the 'admin' field with the user's email
      await _firestore.collection('smartlocks').doc(smartlockId).update({
        'admin': email,  // Update the admin field with the user's email
      });

      // If the secret code matches and no admin exists, return true
      return true;

    } catch (e) {
      print("Error during SmartLock validation: $e");
      return false; // If an error occurs during Firestore query, return false
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.darkCarbon,
      body: SingleChildScrollView( // Allow scrolling when the keyboard appears
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 15),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  hintStyle: TextStyle(color: Colors.white70),
                  labelText: 'name',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35),
                    borderSide: BorderSide(color: myColors.gold),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35),
                    borderSide: BorderSide(color: myColors.gold, width: 2),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 15),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(color: Colors.white70),
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35),
                    borderSide: BorderSide(color: myColors.gold),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35),
                    borderSide: BorderSide(color: myColors.gold, width: 2),
                  ),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: TextStyle(color: Colors.white70),
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35),
                    borderSide: BorderSide(color: myColors.gold),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35),
                    borderSide: BorderSide(color: myColors.gold, width: 2),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),

              SizedBox(height: 15),
              TextField(
                controller: _smartlockIdController,
                decoration: InputDecoration(
                  hintText: 'Enter lockId',
                  hintStyle: TextStyle(color: Colors.white70),
                  labelText: 'lockId',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35),
                    borderSide: BorderSide(color: myColors.gold),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35),
                    borderSide: BorderSide(color: myColors.gold, width: 2),
                  ),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,

              ),
              SizedBox(height: 20),
              TextField(
                controller: _lockNameController,
                decoration: InputDecoration(
                  hintText: 'Enter lockname',
                  hintStyle: TextStyle(color: Colors.white70),
                  labelText: 'lockName',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35),
                    borderSide: BorderSide(color: myColors.gold),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35),
                    borderSide: BorderSide(color: myColors.gold, width: 2),
                  ),
                ),
                style: TextStyle(color: Colors.white),

              ),
              SizedBox(height: 20),
              // Keypad for 6-digit code
              TextField(
                controller: _pinController,
                decoration: InputDecoration(
                  hintText: 'Enter 6-digit code',
                  hintStyle: TextStyle(color: Colors.white70),
                  labelText: '6-digit code',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35),
                    borderSide: BorderSide(color: myColors.gold),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35),
                    borderSide: BorderSide(color: myColors.gold, width: 2),
                  ),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                maxLength: 6,  // Only allows 6 digits
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: 20),

              // Futuristic Radio Button Selection
              Text(
                'Account Type',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio<String>(
                    value: 'user',
                    groupValue: _accountType,
                    onChanged: (value) {
                      setState(() {
                        _accountType = value!;
                      });
                    },
                    activeColor: myColors.gold,
                  ),
                  Text(
                    'User',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(width: 30),
                  Radio<String>(
                    value: 'admin',
                    groupValue: _accountType,
                    onChanged: (value) {
                      setState(() {
                        _accountType = value!;
                      });
                    },
                    activeColor: myColors.gold,
                  ),
                  Text(
                    'Admin',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              // If Admin is selected, show input fields for smartlock ID and secret code
              if (_accountType == 'admin') ...[
                SizedBox(height: 15),

                TextField(
                  controller: _secretCodeController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter Secret Code',
                    hintStyle: TextStyle(color: Colors.white70),
                    labelText: 'Secret Code',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(35),
                      borderSide: BorderSide(color: myColors.gold),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(35),
                      borderSide: BorderSide(color: myColors.gold, width: 2),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ],
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: myColors.gold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 22),
                ),
                child: Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
