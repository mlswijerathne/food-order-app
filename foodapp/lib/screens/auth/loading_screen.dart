import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingScreen> {
  double _opacity = 0.0; // Initial opacity value

  @override
  void initState() {
    super.initState();
    // Start the animation after the page is built
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0; // Change opacity to 1.0 (fully visible)
      });
    });

    // Navigate to SignInScreen after animation completes (2.5 seconds delay)
    Future.delayed(Duration(seconds: 2, milliseconds: 500), () {
      Navigator.pushReplacementNamed(context, '/sign_in_page');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity, // Use the animated opacity value
          duration: Duration(seconds: 2), // Animation duration
          child: SizedBox(
            height: 350, // Set height
            width: 250, // Set width
            child: Image.asset(
              'assets/image/burger.jpg', // Replace with your image path
              fit: BoxFit.cover, // Ensure the image covers the container
            ),
          ),
        ),
      ),
    );
  }
}
