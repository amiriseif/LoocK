import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class RequestListPage extends StatefulWidget {
  @override
  _RequestListPageState createState() => _RequestListPageState();
}

class _RequestListPageState extends State<RequestListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? adminSmartlockId = ""; // Default value


  @override
  void initState() {
    super.initState();
    _getAdminSmartlockId();
  }

  Future<void> _getAdminSmartlockId() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        var userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          setState(() {
            adminSmartlockId = userDoc['smartlockId'].toString();
          });
        }
      }
    } catch (e) {
      print("Error fetching admin's smartlockId: $e");
    }
  }

  Stream<QuerySnapshot> _getLockRequests() {
    if (adminSmartlockId != null) {
      return _firestore
          .collection('lockRequests')
          .where('lockId', isEqualTo: adminSmartlockId)
          .snapshots();
    } else {
      return Stream.empty();
    }
  }

  Future<void> _acceptRequest(String requestId, String userEmail) async {
    try {
      await _firestore.collection('lockRequests').doc(requestId).update({
        'status': 'accepted',
      });
      var userDoc2 = await _firestore.collection('lockRequests').doc(requestId).get();

      var userDoc = await _firestore.collection('users').where('email', isEqualTo: userEmail).get();
      if (userDoc.docs.isNotEmpty) {
        var userRef = userDoc.docs.first.reference;
        await userRef.update({
          'status': 'active',
          'lockName': userDoc2['lockName'],

        });
      }

      await _firestore.collection('lockRequests').doc(requestId).delete();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request Accepted and Deleted'),
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      print('Error accepting request: $e');
    }
  }

  Future<void> _refuseRequest(String requestId, String userEmail) async {
    try {
      await _firestore.collection('lockRequests').doc(requestId).update({
        'status': 'refused',
      });

      var userDoc = await _firestore.collection('users').where('email', isEqualTo: userEmail).get();
      if (userDoc.docs.isNotEmpty) {
        var userRef = userDoc.docs.first.reference;
        await userRef.update({
          'smartlockId': FieldValue.delete(),
          'status': FieldValue.delete(),
        });
      }

      await _firestore.collection('lockRequests').doc(requestId).delete();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request Refused and Deleted'),
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      print('Error refusing request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text(
          'Request List',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getLockRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xfff3b317)), // Gold color
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error fetching requests.'));
          }

          var requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return Center(
              child: Text(
                'No requests at the moment.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var request = requests[index];
              String requestId = request.id;
              String userEmail = request['email'];
              String status = request['status'];

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Slidable(
                  key: ValueKey(requestId),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 5,
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(20),
                      title: Text(
                        userEmail,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Status: $status',
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              await _acceptRequest(requestId, userEmail);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Accept',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () async {
                              await _refuseRequest(requestId, userEmail);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Refuse',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
