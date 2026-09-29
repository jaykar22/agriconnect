import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'market_prices_screen.dart';
import 'my_lots_screen.dart';
import 'add_crop_lot_screen.dart';
import '../../services/auth_service.dart';
import 'farmer_profile_screen.dart';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  String farmerName = 'Farmer';

  @override
  void initState() {
    super.initState();
    loadFarmerName();
  }

  Future<void> loadFarmerName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final document = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;

    if (document.exists) {
      setState(() {
        farmerName = document.data()?['name'] ?? 'Farmer';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriConnect AI'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FarmerProfileScreen()),
              );

              loadFarmerName();
            },
            icon: const Icon(Icons.person),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadFarmerName,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $farmerName 👋',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Make better selling decisions with AgriConnect AI',
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 20),

              // AI recommendation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.smart_toy, color: Colors.green),
                        SizedBox(width: 10),
                        Text(
                          'AI Recommendation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 15),

                    Text(
                      'Your personalized market recommendation will appear here.',
                    ),

                    SizedBox(height: 10),

                    Text(
                      '🤖 AI prediction coming soon',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Today\'s Market Prices',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _priceCard(
                      'Tomato',
                      '₹2,400',
                      Icons.local_grocery_store,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _priceCard('Onion', '₹2,100', Icons.agriculture),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _actionCard(
                    icon: Icons.sell,
                    title: 'Sell Crop',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddCropLotScreen(),
                        ),
                      );
                    },
                  ),
                  _actionCard(
                    icon: Icons.currency_rupee,
                    title: 'Market Prices',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MarketPricesScreen(),
                        ),
                      );
                    },
                  ),
                  _actionCard(
                    icon: Icons.inventory_2,
                    title: 'My Lots',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyLotsScreen(),
                        ),
                      );
                    },
                  ),
                  _actionCard(
                    icon: Icons.local_offer,
                    title: 'Buyer Offers',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.blue.shade50,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on, size: 35),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Best Market',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'AI will find the market giving you the best realistic return.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceCard(String crop, String price, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 10),
          Text(crop, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(
            price,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text('/ quintal', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
