import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import connectivity_plus
import 'package:smartlocks/myColors.dart';
import 'LockControlPage.dart';
import 'LoginPage.dart';
import 'services/theft_notification_service.dart'; // Import your service

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check for internet connectivity
  var connectivityResult = await (Connectivity().checkConnectivity());

  if (connectivityResult == ConnectivityResult.none) {
    // No internet connection, show an error message or handle accordingly
    runApp(ErrorApp());
  } else {
    // If there is an internet connection, initialize Firebase
    await Firebase.initializeApp();

    // Initialize theft notification service
    final TheftNotificationService theftService = TheftNotificationService();
    await theftService.initializeNotifications();
    theftService.startListening(); // Start listening for theft alerts

    runApp(MyApp());
  }
}

// Error app when no internet connection
class ErrorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: myColors.darkCarbon,
        body: Center(
          child: NoInternetScreen(),
        ),
      ),
    );
  }
}

class NoInternetScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        Icon(
          Icons.signal_wifi_off,
          size: 100,
          color: Colors.grey,
        ),
        SizedBox(height: 20),
        Text(
          'No Internet Connection',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Please check your network and try again.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          icon: Icon(
            Icons.refresh,
            color: myColors.darkCarbon,
          ),
          label: Text(
            'Retry',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:Color(0xfff3b317),
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            var connectivityResult = await (Connectivity().checkConnectivity());
            if (connectivityResult != ConnectivityResult.none) {
              // If there is an internet connection, reinitialize Firebase
              await Firebase.initializeApp();

              // Retry to start the app
              runApp(MyApp());
            }
          },
        ),
      ],
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Lock Controller',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InitialPage(), // Start with LoginPage
    );
  }
}

class InitialPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: FirebaseAuth.instance.authStateChanges().first,
      builder: (context, snapshot) {
        // If user is logged in, navigate to LockControlPage
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data != null) {
            return LockControlPage();
          } else {
            return LoginPage();
          }
        }

        // Show a loading spinner while checking auth status
        return Scaffold(
          backgroundColor: myColors.darkCarbon,
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
