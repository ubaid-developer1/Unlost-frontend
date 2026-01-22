// import 'package:flutter/material.dart';

// class ForgotPasswordScreen extends StatefulWidget {
//   const ForgotPasswordScreen({super.key});

//   @override
//   State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
// }

// class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
//   final TextEditingController emailController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
      
//       appBar: AppBar(backgroundColor: Colors.white,),
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Center(
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   const Text(
//                     "Forgot Password?",
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 22,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   // Image
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: Image.asset(
//                       'assets/images/ForgetPass.jpeg', // <-- update this path
//                       height: 180,
//                       fit: BoxFit.contain,
//                     ),
//                   ),

//                   const SizedBox(height: 24),

//                   // Email Input
//                   TextFormField(
//                     controller: emailController,
//                     decoration: InputDecoration(
//                       hintText: 'Enter your email',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 24),

//                   // Send Code Button
//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         // Handle sending reset code
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: const Text(
//                         'Send Reset Code',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 28),

//                   // Step Indicator
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // Container(
//                       //   height: 8,
//                       //   width: 60,
//                       //   decoration: BoxDecoration(
//                       //     color: Colors.black,
//                       //     borderRadius: BorderRadius.circular(10),
//                       //   ),
//                       // ),
//                       // const SizedBox(width: 8),
//                       // Container(
//                       //   height: 8,
//                       //   width: 60,
//                       //   decoration: BoxDecoration(
//                       //     color: Colors.grey[300],
//                       //     borderRadius: BorderRadius.circular(10),
//                       //   ),
//                       // ),
//                       // const SizedBox(width: 8),
//                       // Container(
//                       //   height: 8,
//                       //   width: 60,
//                       //   decoration: BoxDecoration(
//                       //     color: Colors.grey[300],
//                       //     borderRadius: BorderRadius.circular(10),
//                       //   ),
//                       // ),
//                       // const SizedBox(width: 10),
//                       // const Text(
//                       //   '1 of 3',
//                       //   style: TextStyle(
//                       //     fontWeight: FontWeight.bold,
//                       //     color: Colors.black,
//                       //   ),
//                       // )
//                     ],
//                   )
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool isSending = false;

  Future<void> sendPasswordResetEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() => isSending = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset link sent! Check your email 📩')),
      );
      Navigator.pop(context); // Optional: Go back after sending
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Something went wrong. Try again.';

      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isSending = false);
    }
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
                    "Forgot Password?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/ForgetPass.jpeg',
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSending ? null : sendPasswordResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isSending ? 'Sending...' : 'Send Reset Link',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
