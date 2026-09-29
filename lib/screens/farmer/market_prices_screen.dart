import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  String selectedCrop = 'All Crops';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Market Prices')),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('market_prices')
            .snapshots(),

        builder: (context, snapshot) {
          // --------------------------------------------------
          // LOADING
          // --------------------------------------------------

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --------------------------------------------------
          // ERROR
          // --------------------------------------------------

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading market prices:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // --------------------------------------------------
          // NO DATA
          // --------------------------------------------------

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No market prices available.'));
          }

          final documents = snapshot.data!.docs;

          // --------------------------------------------------
          // GET UNIQUE COMMODITIES
          // --------------------------------------------------

          final Set<String> commoditySet = {};

          for (final document in documents) {
            final data = document.data() as Map<String, dynamic>;

            final commodity = data['commodity']?.toString().trim();

            if (commodity != null && commodity.isNotEmpty) {
              commoditySet.add(commodity);
            }
          }

          final List<String> commodities = commoditySet.toList();

          commodities.sort();

          // --------------------------------------------------
          // FILTER RECORDS
          // --------------------------------------------------

          final filteredDocuments = selectedCrop == 'All Crops'
              ? documents
              : documents.where((document) {
                  final data = document.data() as Map<String, dynamic>;

                  return data['commodity']?.toString().trim() == selectedCrop;
                }).toList();

          // --------------------------------------------------
          // UI
          // --------------------------------------------------

          return Column(
            children: [
              // ------------------------------------------------
              // CROP DROPDOWN
              // ------------------------------------------------

              Padding(
                padding: const EdgeInsets.all(16),

                child: DropdownButtonFormField<String>(
                  value: selectedCrop,

                  decoration: const InputDecoration(
                    labelText: 'Select Commodity',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.agriculture),
                  ),

                  items: [
                    const DropdownMenuItem<String>(
                      value: 'All Crops',
                      child: Text('All Crops'),
                    ),

                    ...commodities.map((commodity) {
                      return DropdownMenuItem<String>(
                        value: commodity,
                        child: Text(commodity),
                      );
                    }),
                  ],

                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCrop = value;
                      });
                    }
                  },
                ),
              ),

              // ------------------------------------------------
              // RESULT COUNT
              // ------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: Row(
                  children: [
                    Text(
                      '${filteredDocuments.length} market records',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    if (selectedCrop != 'All Crops')
                      Text(
                        selectedCrop,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ------------------------------------------------
              // MARKET LIST
              // ------------------------------------------------
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await FirebaseFirestore.instance
                        .collection('market_prices')
                        .get();
                  },

                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),

                    itemCount: filteredDocuments.length,

                    itemBuilder: (context, index) {
                      final data =
                          filteredDocuments[index].data()
                              as Map<String, dynamic>;

                      final commodity = data['commodity']?.toString() ?? '-';

                      final market =
                          data['market']?.toString() ?? 'Unknown Market';

                      final district =
                          data['district']?.toString() ?? 'Unknown District';

                      final state = data['state']?.toString() ?? '-';

                      final variety = data['variety']?.toString() ?? '-';

                      final grade = data['grade']?.toString() ?? '-';

                      final arrivalDate =
                          data['arrivalDate']?.toString() ?? '-';

                      final minPrice = data['minPrice'] ?? '-';

                      final maxPrice = data['maxPrice'] ?? '-';

                      final modalPrice = data['modalPrice'] ?? '-';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),

                        elevation: 3,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: Padding(
                          padding: const EdgeInsets.all(16),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              // --------------------------------
                              // COMMODITY + MARKET
                              // --------------------------------

                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),

                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),

                                    child: const Icon(
                                      Icons.store,
                                      color: Colors.green,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        Text(
                                          commodity,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          market,
                                          style: const TextStyle(fontSize: 15),
                                        ),

                                        const SizedBox(height: 3),

                                        Text(
                                          '$district, $state',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // --------------------------------
                              // MODAL PRICE
                              // --------------------------------
                              Container(
                                width: double.infinity,

                                padding: const EdgeInsets.all(14),

                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.08),

                                  borderRadius: BorderRadius.circular(12),
                                ),

                                child: Column(
                                  children: [
                                    const Text(
                                      'Modal Price',
                                      style: TextStyle(fontSize: 14),
                                    ),

                                    const SizedBox(height: 5),

                                    Text(
                                      '₹$modalPrice / Quintal',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              // --------------------------------
                              // MIN / MAX
                              // --------------------------------
                              Row(
                                children: [
                                  Expanded(
                                    child: _priceBox('Minimum', '₹$minPrice'),
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: _priceBox('Maximum', '₹$maxPrice'),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // --------------------------------
                              // INFORMATION
                              // --------------------------------
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,

                                children: [
                                  _infoChip(
                                    Icons.category,
                                    'Variety: $variety',
                                  ),

                                  _infoChip(Icons.verified, 'Grade: $grade'),

                                  _infoChip(Icons.calendar_today, arrivalDate),

                                  _infoChip(Icons.public, 'data.gov.in'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================
  // PRICE BOX
  // ==========================================================

  Widget _priceBox(String title, String price) {
    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),

        borderRadius: BorderRadius.circular(10),
      ),

      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600])),

          const SizedBox(height: 4),

          Text(
            price,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INFORMATION CHIP
  // ==========================================================

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icon, size: 15),

          const SizedBox(width: 5),

          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
