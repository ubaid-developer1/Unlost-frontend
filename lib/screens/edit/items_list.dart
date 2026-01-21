// item_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unstop/screens/edit/edit_screen.dart';
import 'package:unstop/notification/schedule_noti.dart';

class ItemListScreen extends StatelessWidget {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Item List',
          style: TextStyle(
             
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
             
          ),
        ),
        leading: const BackButton(color: Colors.white),
        // centerTitle: false,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').doc(user?.uid).collection('items').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs;

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No items saved yet',
                style: TextStyle(color: Colors.black, fontSize: 16,fontWeight: FontWeight.w600),
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index].data() as Map<String, dynamic>;
              final docId = items[index].id;

              return Card(
                color: Colors.grey,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    item['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    item['location'] ?? 'No location',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔔 Notification Status Indicator
                      // FutureBuilder<bool>(
                      //   future: areNotificationsEnabledForItem(docId),
                      //   builder: (context, snapshot) {
                      //     final isEnabled = snapshot.data ?? false;
                      //     return Icon(
                      //       isEnabled ? Icons.notifications_active : Icons.notifications_off,
                      //       color: isEnabled ? Colors.green : Colors.red,
                      //       size: 20,
                      //     );
                      //   },
                      // ),
                      // const SizedBox(width: 8),
                      // Edit Button
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditItemScreen(selectedItemId: docId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, color: Colors.white),
                        tooltip: 'Edit Item',
                      ),
                      // Delete Button
                      IconButton(
                        onPressed: () async {
                          // Show confirmation dialog
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Item'),
                              content: Text('Are you sure you want to delete "${item['name']}"? This will also disable all notifications for this item.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed == true) {
                            // ✅ Automatically disable notifications when deleting
                            await disableNotificationsForItem(docId);
                            
                            // Delete from Firestore
                            await _firestore
                                .collection('users')
                                .doc(_auth.currentUser?.uid)
                                .collection('items')
                                .doc(docId)
                                .delete();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Item deleted and notifications disabled'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Item',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}