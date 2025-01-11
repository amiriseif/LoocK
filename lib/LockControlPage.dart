import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'LockHistoryPage.dart';
import 'RequestListPage.dart';
import 'SettingsPage.dart';
import 'myColors.dart';

class LockControlPage extends StatefulWidget {
  @override
  _LockControlPageState createState() => _LockControlPageState();
}

class _LockControlPageState extends State<LockControlPage> with SingleTickerProviderStateMixin {
  bool _isLocked = true; // Initially locked
  bool _hasDisplayedMessage = false; // Track if message has been displayed
  late AnimationController _animationController;
  bool _isAdmin = false;
  String lockName = "-------";
  String accountStatus = "pending";
  String lockStatus = "locked";

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _checkUserRole();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
      lowerBound: 0.9,
      upperBound: 1.1,
    );
    _fetchLockData();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  Future<void> _checkUserRole() async {
    final User? user = _auth.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        if (userDoc['type'] == 'admin') {
          setState(() {
            _isAdmin = true;
          });
        }
      } else {
        print("User document does not exist");
      }
    } else {
      print("No user is logged in");
    }
  }

  Future<void> _fetchLockData() async {
    final User? user = _auth.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          lockName = userDoc['lockName'] ?? "-------";
          accountStatus = userDoc['status'] ?? "pending";
        });
      }
    }
  }

  Future<void> _fetchLockStatus() async {
    final User? user = _auth.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        String smartlockId = userDoc['smartlockId'].toString();
        final DatabaseReference lockRef = FirebaseDatabase.instance.ref().child(smartlockId);

        // Fetch current lock status
        lockRef.onValue.listen((event) {
          if (event.snapshot.exists) {
            setState(() {
              lockStatus = event.snapshot.child('status').value.toString();
              _isLocked = lockStatus == 'locked';
            });
          }
        });
      }
    }
  }

  bool _isToggleInProgress = false;

  void _unlockDoor() async {
    if (_isToggleInProgress) {
      print("Unlock is already in progress. Please wait.");
      return;
    }

    if (accountStatus != "active") {
      print("Account status is not active. Unlock is disabled.");
      return;
    }

    if (!_isLocked) {
      print("Door is already unlocked.");
      setState(() {
        _hasDisplayedMessage = true; // Show the message only once
      });
      return; // Prevent unlocking if already unlocked
    }

    _isToggleInProgress = true;

    setState(() {
      _isLocked = false; // Set the status to unlocked
      lockStatus = "unlocked";
    });

    final User? user = _auth.currentUser;

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user!.uid).get();

    try {
      final DatabaseReference lockRef = FirebaseDatabase.instance.ref().child(userDoc["smartlockId"].toString());
      await lockRef.set({
        'status': lockStatus,
      });

      await FirebaseFirestore.instance.collection('lockHistory').add({
        'lockName': lockName,
        'status': lockStatus,
        'email': user.email ?? 'unknown',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _animationController.forward(from: 0.9).then((_) {
        _animationController.reverse();
      });

      // After unlocking, fetch the lock status again
      _fetchLockStatus();
    } catch (e) {
      print('Error saving lock status: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save lock status: $e')));
    } finally {
      _isToggleInProgress = false;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.darkCarbon,
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: accountStatus == 'active' ? Colors.green : Colors.yellow,
                ),
                SizedBox(width: 10),
                Text(
                  lockName,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xfff4f4f4)),
                ),
              ],
            ),
            Text(
              accountStatus == 'active' ? 'Active' : 'Pending',
              style: TextStyle(fontSize: 16, color: Color(0xfff4f4f4)),
            ),
          ],
        ),
        backgroundColor: myColors.darkCarbon,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _unlockDoor, // Only unlock door
              child: ScaleTransition(
                scale: _animationController,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: accountStatus != "active" ? Colors.grey : myColors.carbon,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        spreadRadius: 7,
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: Image.asset(
                        _isLocked ? 'assets/icons/lock.png' : 'assets/icons/unlock.png',
                        key: ValueKey<bool>(_isLocked),
                        width: 85,
                        height: 85,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            Text(
              _isLocked ? 'Locked' : 'Unlocked',
              style: TextStyle(fontSize: 20, color: Color(0xfff4f4f4)),
            ),
            if (!_isLocked ) // Show message only once
              Text(
                'Door is already unlocked',
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Color(0xfff3b317),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Image.asset('assets/icons/history.png', width: 34, height: 34),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LockHistoryPage(userLockname: lockName)),
                  );
                },
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LockControlPage()),
                  );
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(Icons.lock, color: Color(0xfff3b317), size: 35),
                ),
              ),
              if (_isAdmin)
                IconButton(
                  icon: Icon(Icons.manage_accounts, color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RequestListPage()),
                    );
                  },
                ),
              IconButton(
                icon: Icon(Icons.settings, color: Colors.white, size: 30),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
