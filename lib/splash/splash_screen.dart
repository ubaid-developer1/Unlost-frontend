import 'package:flutter/material.dart';
import 'package:unstop/core/color_constants.dart';
import 'package:unstop/screens/auth/login_screen.dart';
import 'dart:async';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Delay for 2 seconds then navigate to Login
    Timer(Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
           
          
            Image.asset(
              'assets/images/splash-icon.png',
              width: 100,
            ),

            SizedBox(height: 40),
            Text('UN LOST',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
              SizedBox(height: 70,),
            CircularProgressIndicator(color: ColorConstants.blue),
          ],
        ),
      ),
    );
  }
}
