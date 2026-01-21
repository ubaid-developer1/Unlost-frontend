
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unstop/core/color_constants.dart';
import 'package:unstop/notification/schedule_noti.dart';
import 'package:unstop/screens/add_location.dart';
import 'package:unstop/screens/edit_location.dart';
import 'package:unstop/widgets/customButton.dart';
import 'package:unstop/widgets/lent_borrow_button.dart';
import 'package:unstop/widgets/pop_up.dart';

class AddNewItemScreen extends StatefulWidget {
  const AddNewItemScreen({super.key});

  @override
  State<AddNewItemScreen> createState() => _AddNewItemScreenState();
}

class _AddNewItemScreenState extends State<AddNewItemScreen> {
  String? selectedLocation;
  String? borrowType;
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController locationDetailsController = TextEditingController();
  final TextEditingController personNameController = TextEditingController();
  String? reminderFrequency;
  TimeOfDay? reminderTime;
  List<String> firebaseLocations = [];
  bool isFetchingLocations = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  int itemCount = 0;
  int itemLimit =25;
  int itemUpgrades = 0;
  bool isLocationSubscribed = false;

  @override
  void initState() {
    super.initState();
    fetchItemCount();
    fetchUserData();
    fetchLocationsFromFirebase();
  }

  Future<void> fetchLocationsFromFirebase() async {
    setState(() => isFetchingLocations = true);
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore.collection('users').doc(user.uid).collection('locations').get();
    setState(() {
      firebaseLocations = snapshot.docs.map((doc) => doc['name'].toString()).toList();
      isFetchingLocations = false;
    });
  }

  Future<void> fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final snapshot = await _firestore.collection('users').doc(user.uid).collection('items').get();
      setState(() {
        itemLimit = userDoc.data()?['itemLimit'] ?? 25;
        itemUpgrades = userDoc.data()?['itemUpgrades'] ?? 0;
        itemCount = snapshot.docs.length;
        isLocationSubscribed = userDoc.data()?['locationSubscribed'] ?? false;
      });
    }
  }

  Future<void> fetchItemCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user for fetchItemCount');
        return;
      }

      debugPrint('🔍 Fetching item count for user: ${user.uid}');
      
      final snapshot = await _firestore.collection('users').doc(user.uid).collection('items').get();
      
      debugPrint('📊 Found ${snapshot.docs.length} items in Firebase');
      
      setState(() {
        itemCount = snapshot.docs.length;
      });
      
      debugPrint('✅ Item count updated to: $itemCount');
    } catch (e) {
      debugPrint('❌ Error fetching item count: $e');
    }
  }

  Future<void> saveItem() async {
    try {
      final name = itemNameController.text.trim();
      final location = selectedLocation;
      final details = locationDetailsController.text.trim();
      final person = personNameController.text.trim();
      final reminder = reminderFrequency;
      final user = _auth.currentUser;

      debugPrint('🔍 Save Item Debug:');
      debugPrint('  User: ${user?.uid}');
      debugPrint('  Name: $name');
      debugPrint('  Location: $location');
      debugPrint('  Details: $details');
      debugPrint('  Borrow Type: $borrowType');
      debugPrint('  Person: $person');
      debugPrint('  Reminder Frequency: $reminder');
      debugPrint('  Reminder Time: ${reminderTime?.format(context)}');

      if (user == null) {
        debugPrint('❌ No authenticated user found');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication error. Please log in again.')),
        );
        return;
      }

      if (name.isEmpty || location == null || location.isEmpty || location == 'custom' || location == 'more' || details.isEmpty) {
        debugPrint('❌ Validation failed - missing required fields');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields properly')),
        );
        return;
      }

      if (borrowType != null && borrowType!.isNotEmpty) {
        if (person.isEmpty) {
          debugPrint('❌ Validation failed - person name required for borrowed/lent items');
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter person name')),
            );
          return;
        }
        if (reminderFrequency == null) {
           debugPrint('❌ Validation failed - reminder frequency required for borrowed/lent items');
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select reminder frequency')),
            );
          return;
        }
        if (reminderTime == null) {
          debugPrint('❌ Validation failed - reminder time required for borrowed/lent items');
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select reminder time')),
            );
          return;
        }
      }

      if (itemCount >= itemLimit) {
        debugPrint('❌ Item limit reached: $itemCount/$itemLimit');
        showUpgradeDialog(context);
        return;
      }

      debugPrint('✅ Validation passed, saving to Firebase...');

      final itemData = {
        'name': name,
        'location': location,
        'locationDetails': details,
        'borrowType': borrowType ?? '',
        'person': person,
        'reminderFrequency': reminder,
        'reminderTime': reminderTime?.format(context),
        'createdAt': FieldValue.serverTimestamp(),
      };

      debugPrint('📝 Item data to save: $itemData');

      final docRef = await _firestore.collection('users').doc(user.uid).collection('items').add(itemData);

      final itemId = docRef.id;
      debugPrint('✅ Item saved successfully with ID: $itemId');

      if (borrowType != null && borrowType!.isNotEmpty) {
        String notificationBody = '';
        if (borrowType == 'Lent') {
          notificationBody = '$name was Lent to $person';
        } else if (borrowType == 'Borrowed') {
          notificationBody = '$name was borrowed from $person';
        }
        
        debugPrint('🔔 Scheduling notification: $notificationBody');
        await scheduleNotification(
          itemId: itemId,
          title: 'Item Reminder 📦',
          body: notificationBody,
          time: reminderTime!,
          frequency: reminderFrequency!,
        );
      }

      setState(() {
        itemNameController.clear();
        locationDetailsController.clear();
        selectedLocation = null;
        borrowType = null;
        personNameController.clear();
        reminderFrequency = null;
        reminderTime = null;
      });

      await fetchItemCount();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully! ✅')),
      );
      
      debugPrint('✅ Save item process completed successfully');
    } catch (e) {
      debugPrint('❌ Error saving item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving item: ${e.toString()}')),
      );
    }
  }

  void clearBorrowType() {
    setState(() {
      borrowType = null;
      personNameController.clear();
      reminderFrequency = null;
      reminderTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Save Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {},
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: ColorConstants.blue,
                ),
                child: const Center(
                  child: Text(
                    'ADD A NEW ITEM',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('CHOOSE WHERE TO SAVE', style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedLocation,
              isExpanded: true,
              dropdownColor: Colors.white,
              decoration: const InputDecoration(border: InputBorder.none),
              hint: const Text('Select Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              iconEnabledColor: Colors.black,
              style: const TextStyle(color: Colors.black),
              items: [
                // DropdownMenuItem(
                //   value: 'custom',
                //   child: Row(
                //     children: [
                //       const Text('Add Custom Location'),
                //       const SizedBox(width: 6),
                //       const Text('👑'),
                //     ],
                //   ),
                // ),
                ...firebaseLocations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))),
                if (!isLocationSubscribed)
                  DropdownMenuItem(
                    value: 'custom_location',
                    child: Row(
                      children: [
                        const Text('Add Custom Location', style: TextStyle(color: Colors.black)),
                        const SizedBox(width: 6),
                        const Text('👑'),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == 'custom_location') {
                  setState(() => selectedLocation = null);
Navigator.push(context, MaterialPageRoute(builder: (_) => const EditLocationScreen()));
                  // isLocationSubscribed
                  //     ? Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLocationScreen()))
                  //     : showUpgradeDialogLocation(context);
                } else if (value == 'Add Custom Location') {
                  setState(() => selectedLocation = null);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EditLocationScreen()));

                  // isLocationSubscribed
                  //     ? Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLocationScreen()))
                  //     : showUpgradeDialogLocation(context);
                } else {
                  setState(() => selectedLocation = value);
                }
              },
            ),
            const SizedBox(height: 20),
            const Text('NAME OF THE ITEM', style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: itemNameController,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: 'Enter item name',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('EXACT LOCATION DETAILS', style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: locationDetailsController,
              style: const TextStyle(color: Colors.black),
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Description',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SELECT IF BORROWED OR LENT', style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                // IconButton(
                //   onPressed: clearBorrowType,
                //   icon: const Icon(Icons.clear, color: Colors.redAccent),
                //   tooltip: 'Clear Lent/Borrowed',
                // ),
              ],
            ),
            const SizedBox(height: 8),
            // Row(
            //   children: ['Lent', 'Borrowed'].map((type) {
            //     return Expanded(
            //       child: Padding(
            //         padding: const EdgeInsets.symmetric(horizontal: 4),
            //         child: customButtonLentBorrow(
            //           label: type,
            //           color: borrowType == type ? Colors.blue : Colors.grey,
            //           onPressed: () => setState(() => borrowType = type),
            //         ),
            //       ),
            //     );
            //   }).toList(),
            // ),
            Row(
  children: ['Lent', 'Borrowed'].map((type) {
    final isSelected = borrowType?.contains(type) ?? false;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: customButtonLentBorrow(
          label: type,
          color: isSelected ? Colors.blue : Colors.grey,
          onPressed: () {
            setState(() {
              if (borrowType == null) {
                borrowType = type;
              } else if (borrowType == type) {
                // toggle off
                borrowType = null;
              } else {
                // toggle new value
                borrowType = type;
              }
            });
          },
        ),
      ),
    );
  }).toList(),
),

            if (borrowType != null) ...[
              const SizedBox(height: 20),
              TextField(
                controller: personNameController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Type name of person',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('SET A REMINDER', style: TextStyle(color: Colors.blueAccent)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: reminderFrequency,
                decoration: const InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
                dropdownColor: Colors.white,
                iconEnabledColor: Colors.black,
                hint: const Text('Select Frequency', style: TextStyle(color: Colors.black)),
                style: const TextStyle(color: Colors.black),
                items: ['Daily', 'Weekly', 'Monthly'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                onChanged: (value) => setState(() => reminderFrequency = value),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (picked != null) {
                    setState(() => reminderTime = picked);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    reminderTime != null ? reminderTime!.format(context) : 'Select Reminder Time',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            customButton(
              label: 'Save',
              color: Colors.green,
              onPressed: saveItem,
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    '$itemCount of $itemLimit Items Saved',
                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      showUpgradeDialog(context);
                    },
                    child: const Text(
                      'Upgrade to Add More',
                      style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }
}
