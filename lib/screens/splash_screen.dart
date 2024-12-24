import 'dart:async';
import 'package:flutter/material.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to HomeScreen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/home'); // Replace with your home route
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black, // Background color
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 7,
            child: Center(
              child: Text(
                'QuoteAPP', // App title
                style: TextStyle(
                  fontFamily: 'Cursive', // Use a cursive font
                  fontSize: 40, // Font size
                  color: Colors.white, // Font color
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange), // Loader color
                  strokeWidth: 3, // Loader thickness
                ),
                SizedBox(height: 10), // Spacing
                Text(
                  'Gathering the boxes of quotes', // Subtitle
                  style: TextStyle(
                    color: Colors.white, // Text color
                    fontSize: 14, // Text size
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
