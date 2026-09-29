import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyLotsScreen extends StatelessWidget {
  const MyLotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String farmerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Crop Lots')),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('farmer_lots')
            .where('farmerId', isEqualTo: farmerId)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading lots:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.agriculture, size: 70, color: Colors.grey),
                  SizedBox(height: 15),
                  Text(
                    'No crop lots found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first crop lot to start selling.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final lots = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lots.length,
            itemBuilder: (context, index) {
              final lot = lots[index].data() as Map<String, dynamic>;

              final String crop = lot['crop'] ?? 'Unknown Crop';
              final String quantity =
                  '${lot['quantity'] ?? 0} ${lot['unit'] ?? 'kg'}';
              final String quality = lot['quality'] ?? 'Not specified';
              final String location = lot['location'] ?? 'Not specified';
              final String expectedPrice = '₹${lot['expectedPrice'] ?? 0}';
              final String status = lot['status'] ?? 'available';

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.agriculture,
                              color: Colors.green.shade700,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              crop,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'available'
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: status == 'available'
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 25),

                      _detailRow(Icons.scale, 'Quantity', quantity),

                      _detailRow(Icons.star, 'Quality', quality),

                      _detailRow(Icons.location_on, 'Location', location),

                      _detailRow(
                        Icons.currency_rupee,
                        'Expected Price',
                        expectedPrice,
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Offer management will be added later.
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('View Lot'),
                        ),
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

  static Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),

          const SizedBox(width: 10),

          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.w600)),

          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
