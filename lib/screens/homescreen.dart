import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unstop/core/color_constants.dart';
import 'package:unstop/notification/schedule_noti.dart';
import 'package:unstop/screens/add_item.dart';
import 'package:unstop/screens/edit/edit_screen.dart';
import 'package:unstop/screens/edit/items_list.dart';
import 'package:unstop/screens/edit_location.dart';
import 'package:unstop/screens/item_details_screen.dart';
import 'package:unstop/widgets/pop_up.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;

  void onSearchChanged(String query) async {
    setState(() {
      isSearching = true;
      searchResults.clear();
    });

    if (query.isEmpty) {
      setState(() {
        isSearching = false;
      });
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final lowercaseQuery = query.toLowerCase();

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('items')
            .get(); // Fetch all to filter manually

    final results =
        snapshot.docs
            .where((doc) {
              final data = doc.data();
              final name = (data['name'] ?? '').toString().toLowerCase();
              return name.contains(lowercaseQuery);
            })
            .map((doc) {
              final data = doc.data();
              data['docId'] = doc.id;
              return data;
            })
            .toList();

    setState(() {
      searchResults = results;
      isSearching = false;
    });
  }

  void onSelectItem(Map<String, dynamic> item) {
    searchController.text = item['name'] ?? '';
    searchResults.clear();
    FocusScope.of(context).unfocus();
  }

  void onFindItemNow() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('items')
            .get();

    QueryDocumentSnapshot<Map<String, dynamic>>? matchedItem;

    for (final doc in snapshot.docs) {
      final name = (doc.data()['name'] ?? '').toString().toLowerCase();
      if (name == query.toLowerCase()) {
        matchedItem = doc;
        break;
      }
    }

    if (matchedItem != null) {
      final itemData = matchedItem.data();
      itemData['docId'] = matchedItem.id;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ItemDetailScreen(itemData: itemData),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item "$query" not found')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            InkWell(
              onTap: () => showProfileBottomSheet(context),
              child: Icon(Icons.account_circle, size: 30, color: Colors.black),
            ),
            SizedBox(width: 10),
            Text('Home', style: TextStyle(color: Colors.black, fontSize: 24)),
            Spacer(),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Data Safety'),
                    content: const Text(
                      'Your items are safely stored in the cloud. Even if you uninstall the app, your data will be preserved and available when you reinstall.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.info_outline, color: Colors.black),
              tooltip: 'Data Safety Info',
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'WHAT ARE YOU\nLOOKING FOR?',
                  style: TextStyle(
                    color: ColorConstants.blue,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
            Container(
  height: 50,
  child: TextField(
    controller: searchController,
    onChanged: onSearchChanged,
    cursorColor: Colors.black,
    style: const TextStyle(
      color: Colors.black,
      fontSize: 18, // keep font consistent
    ),
    decoration: InputDecoration(
      hintText: 'Search for Item Here',
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 18,
      ),
      prefixIcon: const Padding(
        padding: EdgeInsets.only(left: 14, right: 10),
        child: Icon(Icons.search, color: Colors.grey, size: 22),
      ),
      prefixIconConstraints: BoxConstraints(minHeight: 20, minWidth: 40),
      filled: true,
      fillColor: Colors.transparent,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: ColorConstants.blue),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: ColorConstants.blue),
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),
)
,  SizedBox(height: 5),
              if (isSearching)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (searchResults.isNotEmpty)
                //  if (searchResults.isNotEmpty)
                ListView.builder(
                  
                  shrinkWrap: true,
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final item = searchResults[index];
                    return Column(
                      children: [
                        Container(
                          //  height: 60,
                          decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                          child: ListTile(
                            title: Text(
                              item['name'] ?? '',
                              style: TextStyle(color: Colors.white),
                            ),
                            // subtitle: Text(
                            //   item['location'] ?? '',
                            //   style: TextStyle(color: Colors.white70),
                            // ),
                            onTap: () => onSelectItem(item),
                          ),
                        ),
                           SizedBox(height: 5), 
                      ],
                    );
                  },
                ),
              const SizedBox(height: 10),
              _buildButton(
                context,
                label: 'Find Item Now',
                color: ColorConstants.green,
                icon: Icons.search,
                onPressed: onFindItemNow, // ✅ Now calls your logic
              ),
// Divider(thickness: 2,),
              const SizedBox(height: 50),
              _buildButton(
                context,
                label: 'Add a New Item',
                color: ColorConstants.blue,
                icon: Icons.add_circle_outline,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return AddNewItemScreen();
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 25),
              _buildButton(
                context,
                label: 'Edit Items',
                color: ColorConstants.blue,
                icon: Icons.edit_note,
                onPressed: () {
                  // testImmediateNotification();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return EditItemScreen();
                        //  ItemListScreen();
                      },
                    ),
                  );
                },
              ), const SizedBox(height: 25),

              _buildButton(
                context,
                label: 'Edit Locations',
                color: ColorConstants.blue,
                icon: Icons.location_on_outlined,
                onPressed: () async {
                  Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return EditLocationScreen();
                        },
                      ),
                    );

                  // final user = FirebaseAuth.instance.currentUser;
                  // if (user == null) return;

                  // final userDoc =
                  //     await FirebaseFirestore.instance
                  //         .collection('users')
                  //         .doc(user.uid)
                  //         .get();
                  // final isLocationSubscribed =
                  //     userDoc.data()?['locationSubscribed'] ?? false;
                  // if (!isLocationSubscribed) {
                  //   showUpgradeDialogLocation(context);
                  // } else {
                  //   Navigator.of(context).push(
                  //     MaterialPageRoute(
                  //       builder: (context) {
                  //         return EditLocationScreen();
                  //       },
                  //     ),
                  //   );
                  // }
                },
              ),
               const SizedBox(height: 25),
               _buildButton(
                context,
                label: 'Saved Items',
                color: ColorConstants.blue,
                icon: Icons.save,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return ItemListScreen();
                      },
                    ),
                  );
                },
              ),
              
              // // 🧪 TESTING BUTTONS
              // const SizedBox(height: 25),
              // _buildButton(
              //   context,
              //   label: '🧪 Test Notification (1 min)',
              //   color: Colors.orange,
              //   icon: Icons.science,
              //   onPressed: () async {
              //     await scheduleTestNotification();
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(content: Text('Test notification scheduled for 1 minute from now')),
              //     );
              //   },
              // ),
              
              // const SizedBox(height: 15),
              // _buildButton(
              //   context,
              //   label: '🧪 Check Scheduled Notifications',
              //   color: Colors.purple,
              //   icon: Icons.list_alt,
              //   onPressed: () async {
              //     await testScheduledNotifications();
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(content: Text('Check console/debug output for notification details')),
              //     );
              //   },
              // ),
              
              // const SizedBox(height: 15),
              // _buildButton(
              //   context,
              //   label: '🔧 Fix Notification Permissions',
              //   color: Colors.red,
              //   icon: Icons.settings,
              //   onPressed: () async {
              //     await showExactAlarmsPermissionGuide();
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(
              //         content: Text('Check console for permission setup guide'),
              //         duration: Duration(seconds: 5),
              //       ),
              //     );
              //   },
              // ),
              
              // const SizedBox(height: 15),
              // _buildButton(
              //   context,
              //   label: '🔕 Disable All Notifications',
              //   color: Colors.grey,
              //   icon: Icons.notifications_off,
              //   onPressed: () async {
              //     await disableAllNotifications();
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(
              //         content: Text('All notifications have been disabled'),
              //         backgroundColor: Colors.red,
              //       ),
              //     );
              //   },
              // ),
              
              //  const SizedBox(height: 35),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color,
        ),
        width: double.infinity,
        height: 62,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
