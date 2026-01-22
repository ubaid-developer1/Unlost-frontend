import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unstop/core/color_constants.dart';
import 'package:unstop/notification/schedule_noti.dart';
import 'package:unstop/screens/homescreen.dart';
import 'package:unstop/widgets/customButton.dart';
import 'package:unstop/widgets/lent_borrow_button.dart';
import 'package:unstop/main.dart';

class EditItemScreen extends StatefulWidget {
  final String? selectedItemId;
  
  const EditItemScreen({super.key, this.selectedItemId});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController searchController = TextEditingController();
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController locationDetailsController =
      TextEditingController();
  final TextEditingController personNameController = TextEditingController();

  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> filteredItems = [];

  String? selectedItemId;
  String? selectedLocation;
  String? borrowType;
  String? reminderFrequency;
  TimeOfDay? reminderTime;
  List<String> firebaseLocations = [];

  @override
  void initState() {
    super.initState();
    fetchAllItems();
    fetchLocations();
    
    // ✅ Load selected item data if provided
    if (widget.selectedItemId != null) {
      loadSelectedItemData();
    }
  }

  // ✅ Load selected item data when coming from item list
  Future<void> loadSelectedItemData() async {
    if (widget.selectedItemId == null) return;
    
    selectedItemId = widget.selectedItemId;
    
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('items')
          .doc(selectedItemId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        
        // Load item data into controllers
        itemNameController.text = data['name'] ?? '';
        locationDetailsController.text = data['locationDetails'] ?? '';
        personNameController.text = data['person'] ?? '';
        
        // Load other fields
        selectedLocation = data['location'];
        borrowType = data['borrowType'];
        reminderFrequency = data['reminderFrequency'];
        
        // Parse reminder time
        final timeString = data['reminderTime'];
        if (timeString != null && timeString is String && timeString.contains(':')) {
          reminderTime = _parseTimeString(timeString);
        }
        
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading item data: $e');
    }
  }

  // 🔔 Handle notification toggle
  Future<void> _handleNotificationToggle(bool isEnabled) async {
    if (isEnabled) {
      await disableNotificationsForItem(selectedItemId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications disabled for this item'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      // Re-enable notifications by scheduling them again
      if (reminderFrequency != null && reminderTime != null) {
        String notificationBody = '';
        final itemName = itemNameController.text;
        final personName = personNameController.text;
        
        if (borrowType == 'Lent') {
          notificationBody = '$itemName was Lent to $personName';
        } else if (borrowType == 'Borrowed') {
          notificationBody = '$itemName was borrowed from $personName';
        }
        
        await scheduleNotification(
          itemId: selectedItemId!,
          title: 'Item Reminder 📦',
          body: notificationBody,
          time: reminderTime!,
          frequency: reminderFrequency!,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications enabled for this item'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set reminder time and frequency first'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    // Refresh the widget to update the toggle state
    setState(() {});
  }

  Future<void> fetchAllItems() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('items')
            .get();

    setState(() {
      allItems =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {'id': doc.id, ...data};
          }).toList();
    });
  }

  Future<void> fetchLocations() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('locations')
            .get();

    setState(() {
      firebaseLocations =
          snapshot.docs.map((doc) => doc['name'].toString()).toList();
    });
  }

  void onItemSelected(Map<String, dynamic> item) {
    selectedItemId = item['id'];
    itemNameController.text = item['name'] ?? '';
    locationDetailsController.text = item['locationDetails'] ?? '';
    selectedLocation = item['location'];

    // Only show borrow section if borrowType is non-empty and person or reminder is present
    final borrow = item['borrowType'];
    final person = item['person'];
    final frequency = item['reminderFrequency'];
    final time = item['reminderTime'];

    if (borrow != null &&
        borrow.toString().trim().isNotEmpty &&
        (person != null && person.toString().trim().isNotEmpty ||
            frequency != null && frequency.toString().trim().isNotEmpty ||
            time != null && time.toString().trim().isNotEmpty)) {
      borrowType = borrow;
      personNameController.text = person ?? '';
      reminderFrequency = frequency;
      if (time is String && time.contains(':')) {
        // ✅ FIXED: Properly parse time including AM/PM
        reminderTime = _parseTimeString(time);
      }
    } else {
      borrowType = null;
      personNameController.clear();
      reminderFrequency = null;
      reminderTime = null;
    }

    // Clear dropdown and input
    setState(() {
      searchController.clear();
      filteredItems = [];
    });

    FocusScope.of(context).unfocus();
  }

  // ✅ NEW: Proper time parsing method that handles AM/PM
  TimeOfDay? _parseTimeString(String timeString) {
    try {
      // Handle formats like "5:20 PM", "17:20", "5:20"
      final trimmed = timeString.trim();
      
      if (trimmed.contains(' ')) {
        // Format: "5:20 PM" or "5:20 AM"
        final parts = trimmed.split(' ');
        if (parts.length == 2) {
          final timePart = parts[0];
          final ampm = parts[1].toUpperCase();
          
          final timeComponents = timePart.split(':');
          if (timeComponents.length == 2) {
            int hour = int.tryParse(timeComponents[0]) ?? 0;
            int minute = int.tryParse(timeComponents[1]) ?? 0;
            
            // Convert to 24-hour format
            if (ampm == 'PM' && hour != 12) {
              hour += 12;
            } else if (ampm == 'AM' && hour == 12) {
              hour = 0;
            }
            
            return TimeOfDay(hour: hour, minute: minute);
          }
        }
      } else {
        // Format: "17:20" or "5:20" (24-hour or 12-hour without AM/PM)
        final timeComponents = trimmed.split(':');
        if (timeComponents.length == 2) {
          int hour = int.tryParse(timeComponents[0]) ?? 0;
          int minute = int.tryParse(timeComponents[1]) ?? 0;
          
          // If hour > 12, assume 24-hour format, otherwise assume 12-hour format
          if (hour > 12) {
            return TimeOfDay(hour: hour, minute: minute);
          } else {
            // For 12-hour format without AM/PM, we can't determine AM/PM
            // This is a fallback - ideally the time should always include AM/PM
            return TimeOfDay(hour: hour, minute: minute);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error parsing time string: $timeString - $e');
    }
    return null;
  }

  //  void onItemSelected(Map<String, dynamic> item) {
  //   selectedItemId = item['id'];
  //   itemNameController.text = item['name'] ?? '';
  //   locationDetailsController.text = item['locationDetails'] ?? '';
  //   personNameController.text = item['person'] ?? '';
  //   selectedLocation = item['location'];
  //   borrowType = item['borrowType'];
  //   reminderFrequency = item['reminderFrequency'];

  //   final timeString = item['reminderTime'];
  //   if (timeString != null && timeString is String && timeString.contains(':')) {
  //     final parts = timeString.split(":");
  //     reminderTime = TimeOfDay(
  //       hour: int.tryParse(parts[0]) ?? 0,
  //       minute: int.tryParse(parts[1].split(' ')[0]) ?? 0,
  //     );
  //   }

  //   // 👇 Close the dropdown
  //   setState(() {
  //     searchController.clear();        // clear the input
  //     filteredItems = [];              // clear the dropdown list
  //   });

  //   FocusScope.of(context).unfocus();  // dismiss the keyboard
  // }

  void clearBorrowType() {
    setState(() {
      borrowType = null;
      personNameController.clear();
      reminderFrequency = null;
      reminderTime = null;
    });
  }

  Future<void> updateItem() async {
    if (selectedItemId == null) return;

    final user = _auth.currentUser;
    final name = itemNameController.text.trim();
    final details = locationDetailsController.text.trim();
    final person = personNameController.text.trim();

    if (user == null || name.isEmpty || selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    // ✅ Validate borrowType dependencies
    if (borrowType != null && borrowType!.isNotEmpty) {
      final person = personNameController.text.trim();
      final freq = reminderFrequency;
      final time = reminderTime;

      if (person.isEmpty || freq == null || time == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please fill all Lent/Borrowed details or unselect it',
            ),
          ),
        );
        return;
      }
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('items')
        .doc(selectedItemId)
        .update({
          'name': name,
          'location': selectedLocation,
          'locationDetails': details,
          'borrowType': borrowType ?? '',
          'person': borrowType == null ? null : person,
          'reminderFrequency': borrowType == null ? null : reminderFrequency,
          'reminderTime':
              borrowType == null ? null : reminderTime?.format(context),
          'updatedAt': FieldValue.serverTimestamp(),
        });

    // ✅ Cancel existing notifications
    await flutterLocalNotificationsPlugin.cancel(selectedItemId.hashCode);

    // ✅ Only schedule new notifications if borrowType is set
    if (borrowType != null && borrowType!.isNotEmpty) {
      String notificationBody =
          borrowType == 'Lent'
              ? '$name was Lent to $person'
              : '$name was borrowed from $person';

      await scheduleNotification(
        itemId: selectedItemId!,
        title: 'Item Reminder 📦',
        body: notificationBody,
        time: reminderTime!,
        frequency: reminderFrequency!,
      );
    } else {
      // ✅ If borrowType is empty/null, disable notifications for this item
      await disableNotificationsForItem(selectedItemId!);
      debugPrint('🔕 Notifications disabled - no borrow type set');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item updated successfully! ✅')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> deleteItem() async {
    if (selectedItemId == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    // ✅ Cancel all notifications for this item (main + recurring)
    await disableNotificationsForItem(selectedItemId!);
    
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('items')
        .doc(selectedItemId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item deleted successfully! 🗑️')),
    );
    setState(() {
      selectedItemId = null;
      itemNameController.clear();
      locationDetailsController.clear();
      personNameController.clear();
      selectedLocation = null;
      borrowType = null;
      reminderFrequency = null;
      reminderTime = null;
    });
  }

  Widget buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Edit Item',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
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
                    'EDIT ITEM',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            buildTitle('SELECT ITEM'),
            const SizedBox(height: 8),
            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  filteredItems =
                      allItems
                          .where(
                            (item) => item['name']
                                .toString()
                                .toLowerCase()
                                .contains(value.toLowerCase()),
                          )
                          .toList();
                });
              },
              decoration: InputDecoration(
                hintText: 'Choose an item',
                suffixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                // focusedBorder: OutlineInputBorder(
                //   borderSide: BorderSide(color: Colors.grey),
                // ),
              ),
            ),
            if (searchController.text.isNotEmpty && filteredItems.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                // child: Center(child: CircularProgressIndicator()),
              ),
            if (searchController.text.isNotEmpty && filteredItems.isNotEmpty)
              ...filteredItems
                  .take(5)
                  .map(
                    (item) => Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ListTile(
                            title: Text(
                              item['name'] ?? '',
                              style: TextStyle(color: Colors.white),
                            ),
                            // subtitle: Text(item['location'] ?? ''),
                            onTap: () => onItemSelected(item),
                          ),
                        ),
                        SizedBox(height: 5),
                      ],
                    ),
                  ),
            const SizedBox(height: 16),
            buildTitle('RENAME ITEM'),
            const SizedBox(height: 8),
            buildTextField(itemNameController, 'Item Name'),
            const SizedBox(height: 12),
            buildTitle('EDIT LOCATION DETAILS'),
            const SizedBox(height: 8),
            buildTextField(locationDetailsController, 'Location Details'),
            const SizedBox(height: 12),
            buildTitle('MOVE TO ANOTHER LOCATION'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedLocation,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select Location',
                contentPadding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
              ),
              items:
                  firebaseLocations
                      .map(
                        (loc) => DropdownMenuItem(
                          value: loc,
                          child: Text(
                            loc,
                            style: TextStyle(
                              height: 0.1,
                              fontSize: 15,
                            ), // helps with vertical alignment
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => selectedLocation = value),
            ),

            const SizedBox(height: 12),
            buildTitle('ITEM BORROWED OR LENT'),
            const SizedBox(height: 8),
            Row(
              children:
                  ['Lent', 'Borrowed'].map((type) {
                    final isSelected = borrowType == type;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: customButtonLentBorrow(
                          label: type,
                          color: isSelected ? Colors.blue : Colors.grey,
                          onPressed: () {
                            setState(() {
                              borrowType = isSelected ? null : type;
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
            ),
            SizedBox(height: 20),
            if (borrowType != null) ...[
              TextField(
                controller: personNameController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Type name of person',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'SET A REMINDER',
                style: TextStyle(color: Colors.blueAccent),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: reminderFrequency,

                dropdownColor: Colors.white,
                iconEnabledColor: Colors.black,
                hint: const Text(
                  'Select Frequency',
                  style: TextStyle(color: Colors.black),
                ),
                style: const TextStyle(color: Colors.black),
                items:
                    ['Daily', 'Weekly', 'Monthly']
                        .map(
                          (freq) =>
                              DropdownMenuItem(value: freq, child: Text(freq)),
                        )
                        .toList(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Reminder Frequency',
                ),
                onChanged: (value) => setState(() => reminderFrequency = value),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() => reminderTime = picked);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    reminderTime != null
                        ? reminderTime!.format(context)
                        : 'Select Reminder Time',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // buildTextField(personNameController, 'Name of person'),
              // const SizedBox(height: 12),
              // DropdownButtonFormField<String>(
              // value: reminderFrequency,
              // items:
              //     ['Daily', 'Weekly', 'Monthly']
              //         .map(
              //           (freq) =>
              //               DropdownMenuItem(value: freq, child: Text(freq)),
              //         )
              //         .toList(),
              // onChanged: (val) => setState(() => reminderFrequency = val),
              // decoration: const InputDecoration(
              //   border: OutlineInputBorder(),
              //   hintText: 'Reminder Frequency',
              // ),
              // ),
              // const SizedBox(height: 12),
              // InkWell(
              //   onTap: () async {
              //     final picked = await showTimePicker(
              //       context: context,
              //       initialTime: TimeOfDay.now(),
              //     );
              //     if (picked != null) setState(() => reminderTime = picked);
              //   },
              //   child: Container(
              //     padding: const EdgeInsets.all(12),
              //     decoration: BoxDecoration(
              //       border: Border.all(color: Colors.grey),
              //       borderRadius: BorderRadius.circular(6),
              //     ),
              //     child: Text(reminderTime?.format(context) ?? 'Select Time'),
              //   ),
              // ),
            ],
            const SizedBox(height: 20),
            
            // 🔔 Notification Toggle Section - Only show when item is selected
            if (selectedItemId != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔔 Notification Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Toggle notifications for this item',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<bool>(
                      future: areNotificationsEnabledForItem(selectedItemId!),
                      builder: (context, snapshot) {
                        final isEnabled = snapshot.data ?? false;
                        return Row(
                          children: [
                            Expanded(
                              child: customButton(
                                label: isEnabled ? '🔕 Disable Notifications' : '🔔 Enable Notifications',
                                color: isEnabled ? Colors.orange : Colors.green,
                                icon: isEnabled ? Icons.notifications_off : Icons.notifications,
                                onPressed: () {
                                  _handleNotificationToggle(isEnabled);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: customButton(
                    label: 'Update',
                    color: Colors.green,
                    icon: Icons.update,
                    onPressed: updateItem,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: customButton(
                    label: 'Delete',
                    color: Colors.red,
                    icon: Icons.delete,
                    onPressed: deleteItem,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }

  Widget buildTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.blueAccent,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
