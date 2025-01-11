import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'myColors.dart';

class LockHistoryPage extends StatelessWidget {
  final String userLockname; // The lockname of the user

  LockHistoryPage({required this.userLockname});

  final CollectionReference lockHistoryRef =
  FirebaseFirestore.instance.collection('lockHistory');

  String formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lock History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: myColors.carbon,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: myColors.darkCarbon,
        child: FutureBuilder<QuerySnapshot>(
          future: lockHistoryRef.where('lockName', isEqualTo: userLockname).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: myColors.yellowAccent),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No lock history available yet...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              );
            }

            // Retrieve and sort the lock history
            final lockHistory = snapshot.data!.docs;
            lockHistory.sort((a, b) {
              final timestampA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
              final timestampB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
              return timestampB.compareTo(timestampA); // Sort in descending order
            });

            return ListView.builder(
              itemCount: lockHistory.length,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemBuilder: (context, index) {
                final data = lockHistory[index].data() as Map<String, dynamic>;
                final timestamp = data['timestamp'] as Timestamp;
                final time = formatTimestamp(timestamp);
                final email = data['email'] ?? 'Unknown User';
                final action = data['status'] ?? 'Unknown Action';
                final lockname = data['lockName'] ?? 'Unknown Lock';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [myColors.carbon, myColors.darkCarbon],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: myColors.yellowAccent,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: Icon(
                        action == 'unlocked' ? Icons.lock_open : Icons.lock,
                        color: action == 'unlocked'
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        size: 30,
                      ),
                      title: Text(
                        '$lockname - ${action.toUpperCase()}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time: $time',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'User: $email',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
