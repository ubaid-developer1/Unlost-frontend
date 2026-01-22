import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unstop/bloc/auth_bloc.dart';
import 'package:unstop/bloc/auth_event.dart';
import 'package:unstop/screens/auth/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<void> registerUser() async {
    try {
      setState(() => isLoading = true);
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      final username = usernameController.text.trim();

      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        showMessage('Username, Email, and Password are required');
        return;
      }

      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _auth.currentUser;

      if (user != null) {
        // Save user basic info to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'username': username,
          'createdAt': FieldValue.serverTimestamp(),
          'itemSubscribed': false,
          'locationSubscribed': false,
        });

        // Insert Default Locations
        final defaultLocations = [
          'Living Room',
          'Office',
          'Bedroom',
          'Garage',
          'Basement',
        ];

        final locationsCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('locations');

        for (final loc in defaultLocations) {
          await locationsCollection.add({
            'name': loc,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // Save in SharedPreferences and Bloc
        context.read<AuthBloc>().add(LoggedIn(user.uid, user.email!));
      }

      showMessage('Registration Successful! 🎉 Please login ! ');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );

      // Optionally navigate
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'An error occurred');
    } finally {
      setState(() => isLoading = false);
    }
  }

  //   Future<void> registerUser() async {
  //     try {
  //       setState(() => isLoading = true);
  //       final email = emailController.text.trim();
  //       final password = passwordController.text.trim();

  //       if (email.isEmpty || password.isEmpty) {
  //         showMessage('Email and Password are required');
  //         return;
  //       }

  //      await _auth.createUserWithEmailAndPassword(email: email, password: password);
  // final user = _auth.currentUser;

  // if (user != null) {
  //   // Save user to Firestore
  //   await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
  //     'uid': user.uid,
  //     'email': user.email,
  //     'username': usernameController.text.trim(),
  //     'createdAt': FieldValue.serverTimestamp(),
  //   });

  //   // Save in SharedPreferences and Bloc
  //   context.read<AuthBloc>().add(LoggedIn(user.uid, user.email!));
  // }

  //       showMessage('Registration Successful! 🎉');
  //       // Navigate or clear fields
  //     } on FirebaseAuthException catch (e) {
  //       showMessage(e.message ?? 'An error occurred');
  //     } finally {
  //       setState(() => isLoading = false);
  //     }
  //   }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text(
                    "Let’s Get Started",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      hintText: 'Username',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed:
                            () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                          isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Register',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          // Navigate to login
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) {
                                return const LoginScreen();
                              },
                            ),
                          );
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
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
