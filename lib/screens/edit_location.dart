
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unstop/core/color_constants.dart';
import 'package:unstop/screens/add_location.dart';
import 'package:unstop/widgets/customButton.dart';
import 'package:unstop/widgets/pop_up.dart';

class EditLocationScreen extends StatefulWidget {
  const EditLocationScreen({super.key});

  @override
  State<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  String? selectedRenameLocation;
  String? selectedDeleteLocation;
  final TextEditingController renameController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<String> locationList = [];
  bool isLoading = false;
  Map<String, String> locationMap = {}; // {locationName: docId}
  bool isLocationSubscribed = false;
  bool isLoadingSubscription = true;
  bool isActionLoading =
      false; // 🔥 for showing full-screen loader during rename/delete

  @override
  void initState() {
    super.initState();
    fetchLocations();
    fetchSubscriptionStatus();
  }

  Future<void> fetchLocations() async {
    setState(() => isLoading = true);

    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('locations')
            .get();

    final map = <String, String>{};
    for (var doc in snapshot.docs) {
      final name = doc['name'];
      map[name] = doc.id;
    }

    setState(() {
      locationMap = map;
      isLoading = false;
    });
  }

  Future<void> fetchSubscriptionStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      setState(() {
        isLocationSubscribed = doc.data()?['locationSubscribed'] ?? false;
        isLoadingSubscription = false;
      });
    }
  }

  final List<String> defaultLocations = [
    'Living Room',
    'Office',
    'Bedroom',
    'Garage',
    'Basement',
   
  ];
Future<void> renameLocation() async {
  final newName = renameController.text.trim();
  final oldName = selectedRenameLocation;

  if (oldName == null || newName.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a location and enter a new name'),
      ),
    );
    return;
  }

  final user = _auth.currentUser;
  if (user == null) return;

  final docId = locationMap[oldName];
  if (docId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not find selected location.')),
    );
    return;
  }

  setState(() => isActionLoading = true);

  try {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('locations')
        .doc(docId)
        .update({'name': newName});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location renamed successfully! ✅')),
    );

    renameController.clear();
    setState(() => selectedRenameLocation = null);

    await fetchLocations();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to rename location: $e')),
    );
  } finally {
    if (mounted) {
      setState(() => isActionLoading = false);
    }
  }
}


Future<void> deleteLocation() async {
  final selected = selectedDeleteLocation;

  if (selected == null || !locationMap.containsKey(selected)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a location to delete')),
    );
    return;
  }

  if (locationMap.length <= 5) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('At least 5 locations must be present')),
    );
    return;
  }

  final user = _auth.currentUser;
  if (user == null) return;

  final docId = locationMap[selected];

  setState(() => isActionLoading = true);

  try {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('locations')
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location deleted successfully! ❌')),
    );

    setState(() => selectedDeleteLocation = null);

    await fetchLocations();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete location: $e')),
    );
  } finally {
    if (mounted) {
      setState(() => isActionLoading = false);
    }
  }
}

  Widget _buildDropdown({
    required String? selectedValue,
    required Function(String?) onChanged,
    required String hint,
  }) {
    return isLoading
        ? const CircularProgressIndicator()
        : DropdownButtonFormField<String>(
          value:
              locationMap.keys.contains(selectedValue) ? selectedValue : null,
          isExpanded: true,
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
               
               
              color: Colors.white,
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            border: const OutlineInputBorder(),
          ),
          iconEnabledColor: Colors.black,
          style: const TextStyle(
            color: Colors.black,
             
             
          ),
          items:
              locationMap.keys
                  .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                  .toList(),
          onChanged: onChanged,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor:  Colors.grey[850],
            leading: const BackButton(color: Colors.white),
            title: const Text(
              'Edit Location',
              style: TextStyle(
                 
                 
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            // centerTitle: false,
          ),
          body:
               SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        customButton(
                          label: 'EDIT LOCATION',
                          color: ColorConstants.blue,
                          onPressed: () {},
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'SELECT TO RENAME',
                          style: TextStyle(
                             
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                             
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDropdown(
                          
                          selectedValue: selectedRenameLocation,
                          onChanged:
                              (val) => setState(() => selectedRenameLocation = val),
                          hint: 'Select a location...',
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'RENAME LOCATION',
                          style: TextStyle(
                             
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                             
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: renameController,
                          style: const TextStyle(
                            color: Colors.black,
                             
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter new name',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                               
                            ),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        customButton(
                          label: 'Rename Location',
                          color: Colors.green,
                          icon: Icons.save,
                          onPressed: renameLocation,
                        ),
                        const SizedBox(height: 15),
                        isLocationSubscribed
                            ? InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const AddLocationScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Add Custom Location',
                                  style: TextStyle(
                                    color: Colors.black,
                                     
                                     
                                  ),
                                ),
                              ),
                            )
                            :  Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                                          'Add More Locations',
                                                          style: TextStyle(
                                color: Colors.blueAccent,
                                 
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                 
                                                          ),
                                                        ),
                                                        InkWell(
                              onTap: () {
                                showUpgradeDialogLocation(
                                  context,
                                  // payButton: Platform.isIOS ? applePayButton : googlePayButton,
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Upgrade Now to Add 5 Custom Locations',
                                  style: TextStyle(
                                    color: Colors.black,
                                     
                                     
                                  ),
                                ),
                              ),
                            ),
                              ],
                            ),
        
                        const SizedBox(height: 32),
                        const Text(
                          'Delete Custom Location',
                          style: TextStyle(
                            color: Colors.blueAccent,
                             
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                             
                          ),
                        ),
                        const SizedBox(height: 8),
                       !isLocationSubscribed
                            ? InkWell(
                              onTap: () {
                                  showDialog(
    context: context,
    barrierDismissible: true,
    builder:
        (context) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'UN-LOST',
                  style: TextStyle(
                     
                     
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(height: 10),
                 Text(
                  'This option is available for custom Locations upgrade only',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                     
                    fontSize: 14,
                    color: ColorConstants.blue,
                    fontWeight: FontWeight.bold
                     
                  ),
                ),
               
               
                const SizedBox(height: 12),
                customButton(
                  label: 'Ok',
                  color: ColorConstants.blue,
                  // icon: Icons.add, // Optional, can be removed
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
  );

                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Select a location....',
                                  style: TextStyle(
                                    color: Colors.black,
                                     
                                     
                                  ),
                                ),
                              ),
                            )
        : _buildDropdown(
                          selectedValue: selectedDeleteLocation,
                          onChanged:
                              (val) => setState(() => selectedDeleteLocation = val),
                          hint: 'Select a location...',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          textAlign: TextAlign.center,
                          '⚠️ Warning: Move all items to another location before deleting this location to prevent loss of items',
                          style: TextStyle(
                            color: Colors.redAccent,
                             
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        customButton(
                          label: 'Delete',
                          color: Colors.red,
                          icon: Icons.delete,
                          onPressed: deleteLocation,
                        ),
                   const SizedBox(height: 35),

                      ],
                    ),
                  ),
        ),
  if (isActionLoading)
        Container(
          color: Colors.black.withOpacity(0.7),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
