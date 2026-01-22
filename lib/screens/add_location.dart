import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unstop/core/color_constants.dart';
import 'package:unstop/screens/homescreen.dart';
import 'package:unstop/widgets/customButton.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final TextEditingController _locationController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool isSaving = false;
Future<void> saveLocation() async {
  final locationName = _locationController.text.trim();
  final user = _auth.currentUser;

  if (locationName.isEmpty || user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a location name')),
    );
    return;
  }

  setState(() => isSaving = true);

  try {
    // 🔥 Fetch current number of locations
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('locations')
        .get();

    final locationCount = snapshot.docs.length;

    // 🚫 Check limit (15)
    if (locationCount >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only save up to 5 Custom locations!')),
      );
      setState(() => isSaving = false);
      return;
    }

    // ✅ Save new location
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('locations')
        .add({
      'name': locationName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _locationController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location added successfully ✅')),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (Route<dynamic> route) => false,
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error adding location: $e')),
    );
  } finally {
    setState(() => isSaving = false);
  }
}

//   Future<void> saveLocation() async {
//     final locationName = _locationController.text.trim();
//     final user = _auth.currentUser;

//     if (locationName.isEmpty || user == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter a location name')),
//       );
//       return;
//     }

//     setState(() => isSaving = true);

//     try {
//       await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('locations')
//           .add({
//         'name': locationName,
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       _locationController.clear();

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Location added successfully ✅')),
//       );
//         Navigator.of(context).pushAndRemoveUntil(
//   MaterialPageRoute(
//     builder: (context) => HomeScreen(),
//   ),
//   (Route<dynamic> route) => false,
// );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error adding location: $e')),
//       );
//     } finally {
//       setState(() => isSaving = false);
//     }
//   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor:  Colors.grey[850],
        title: const Text(
          'Add Location',
          style: TextStyle(
            color: Colors.white,
             
            fontWeight: FontWeight.bold,
             
          ),
        ),
        centerTitle: false,
        leading: const BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LOCATION NAME',
              style: TextStyle(
                color: Colors.blueAccent,
                 
                fontWeight: FontWeight.bold,
                fontSize: 16
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              style: const TextStyle(
                color: Colors.black,
                 
              ),
              decoration: const InputDecoration(
                hintText: 'Enter location name',
                hintStyle: TextStyle(
                  color: Colors.grey,
                   
                ),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 20),
            customButton(
              icon: Icons.save,
              label: isSaving ? 'Saving...' : 'Save Location',
              color: Colors.green,
              onPressed: isSaving ? (){} : saveLocation,
            ),
          ],
        ),
      ),
    );
  }
}
