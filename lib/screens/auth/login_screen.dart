import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unstop/bloc/auth_bloc.dart';
import 'package:unstop/bloc/auth_event.dart';
import 'package:unstop/screens/auth/forget_pass.dart';
import 'package:unstop/screens/auth/sign_up_screen.dart';
import 'package:unstop/screens/homescreen.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 👈 Import FCM

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseMessaging _messaging = FirebaseMessaging.instance; // 👈 Initialize FCM
Future<void> loginUser() async {
  try {
    setState(() => isLoading = true);
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Email and Password are required');
      return;
    }

    await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = _auth.currentUser;

    if (user != null) {
      context.read<AuthBloc>().add(LoggedIn(user.uid, user.email!));

      // ✅ Request notification permission (iOS only)
      // if (Platform.isIOS) {
      //   NotificationSettings settings = await _messaging.requestPermission(
      //     alert: true,
      //     badge: true,
      //     sound: true,
      //   );

      //   if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      //     debugPrint('🚫 Push permission not granted.');
      //   }

      //   // ✅ Wait for APNS token to be set (iOS-specific)
      //   int retry = 0;
      //   String? apnsToken;
      //   while (retry < 5 && (apnsToken = await _messaging.getAPNSToken()) == null) {
      //     await Future.delayed(const Duration(seconds: 1));
      //     retry++;
      //   }
      //   log('APNS token: $apnsToken');

      // }
      // ✅ Get FCM token after permission and APNS setup
      // final fcmToken = await _messaging.getToken();
      // if (fcmToken != null) {
      //   await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      //     'fcmToken': fcmToken,
      //   });
      //   debugPrint('✅ FCM token saved: $fcmToken');
      // } else {
      //   debugPrint('⚠️ FCM token is null');
      // }
    }

    showMessage('Login Successful! ✅');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (Route<dynamic> route) => false,
    );
  } on FirebaseAuthException catch (e) {
    showMessage(e.message ?? 'Login failed');
  } finally {
    setState(() => isLoading = false);
  }
}

  // Future<void> loginUser() async {
  //   try {
  //     setState(() => isLoading = true);
  //     final email = emailController.text.trim();
  //     final password = passwordController.text.trim();

  //     if (email.isEmpty || password.isEmpty) {
  //       showMessage('Email and Password are required');
  //       return;
  //     }

  //     await _auth.signInWithEmailAndPassword(email: email, password: password);
  //     final user = _auth.currentUser;
  //     if (user != null) {
  //       context.read<AuthBloc>().add(LoggedIn(user.uid, user.email!));

  //       // ✅ Get FCM Token and save it to Firestore
  //       // final token = await _messaging.getToken();
  //       // if (token != null) {
  //       //   await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
  //       //     'fcmToken': token,
  //       //   });
  //       // }
  //     }

  //     showMessage('Login Successful! ✅');

  //     Navigator.of(context).pushAndRemoveUntil(
  //       MaterialPageRoute(
  //         builder: (context) => HomeScreen(),
  //       ),
  //       (Route<dynamic> route) => false,
  //     );
  //   } on FirebaseAuthException catch (e) {
  //     showMessage(e.message ?? 'Login failed');
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Title Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Un-Lost',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Keep track of all your items and never\nforget where they are again',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black),
                  ),
                  const SizedBox(height: 12),

                  // Image
                  Image.asset(
                    'assets/images/search.png',
                    height: 120,
                  ),
                  const SizedBox(height: 24),

                  // Email Input
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email),
                      hintText: 'Email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                      ),
                      hintText: 'Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Login',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Info is case sensitive',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          // Navigate to Register
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => RegisterScreen()));
                        },
                        child: const Text(
                          'Register Here',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
Navigator.of(context).push(MaterialPageRoute(builder: (context){
  return ForgotPasswordScreen();
}))                    ;},
                    child: const Text(
                      'Click Here for Lost Password',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
