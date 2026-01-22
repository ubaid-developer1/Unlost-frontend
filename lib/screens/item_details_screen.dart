import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unstop/core/color_constants.dart';

class ItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> itemData;

  const ItemDetailScreen({super.key, required this.itemData});

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('MM/dd/yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');

    final Timestamp? createdAt = itemData['createdAt'];
    final Timestamp? updatedAt = itemData['updatedAt'];

    final createdDate = createdAt?.toDate();
    final updatedDate = updatedAt?.toDate();

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Item Information',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: const BackButton(color: Colors.white),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ColorConstants.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    (itemData['location'] ?? 'NO LOCATION')
                        .toString()
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,

                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoText('ITEM:', itemData['name']),
                      _infoText('DESCRIPTION:', itemData['locationDetails']),
                      _infoText(
                        'LENT / BORROWED:',
                        itemData['person'] == null ||
                                itemData['person'].toString().trim().isEmpty
                            ? 'No item exchanged'
                            : itemData['person'],
                      ),
                      const SizedBox(height: 16),
                      _timestampBlock(
                        label: 'Item Last Updated',
                        date: updatedDate ?? createdDate,
                        color: ColorConstants.blue,
                      ),
                      const SizedBox(height: 16),
                      _timestampBlock(
                        label: 'Original File Date',
                        date: createdDate,
                        color: ColorConstants.blue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoText(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12,),
      child: RichText(
        text: TextSpan(
          text: '$label\n',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: ColorConstants.blue,

            fontSize: 21,
          ),
          children: [
            TextSpan(
              text: value ?? '-',
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.black,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timestampBlock({
    required String label,
    required DateTime? date,
    required Color color,
  }) {
    final formattedDate =
        date != null ? DateFormat('MM/dd/yyyy').format(date) : '-';
    final formattedTime =
        date != null ? DateFormat('h:mm a').format(date) : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '$formattedDate     $formattedTime',
            style: const TextStyle(color: Colors.black, fontSize: 19),
          ),
        ),
      ],
    );
  }
}
