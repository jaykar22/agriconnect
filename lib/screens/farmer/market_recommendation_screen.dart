import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MarketRecommendationScreen extends StatefulWidget {
  const MarketRecommendationScreen({super.key});

  @override
  State<MarketRecommendationScreen> createState() =>
      _MarketRecommendationScreenState();
}

class _MarketRecommendationScreenState
    extends State<MarketRecommendationScreen> {
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController districtController = TextEditingController(
    text: "Satara",
  );

  String selectedCrop = "Tomato";
  String selectedUnit = "Kg";

  bool isLoading = false;

  Map<String, dynamic>? bestMarket;
  List<dynamic> markets = [];

  final List<String> crops = [
    "Tomato",
    "Onion",
    "Potato",
    "Ladies Finger",
    "Brinjal",
    "Cabbage",
    "Cauliflower",
  ];

  final List<String> units = ["Kg", "Quintal", "Ton"];

  @override
  void dispose() {
    quantityController.dispose();
    districtController.dispose();
    super.dispose();
  }

  Future<void> getRecommendation() async {
    if (quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please enter quantity")));
      return;
    }

    final quantity = double.tryParse(quantityController.text.trim());

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid quantity")),
      );
      return;
    }

    final district = districtController.text.trim();

    if (district.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter farmer district")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      bestMarket = null;
      markets = [];
    });

    try {
      final uri = Uri.parse(
        "http://127.0.0.1:8000/best-market-net-return"
        "?commodity=${Uri.encodeComponent(selectedCrop)}"
        "&state=Maharashtra"
        "&quantity=$quantity"
        "&unit=${Uri.encodeComponent(selectedUnit)}"
        "&farmer_district=${Uri.encodeComponent(district)}"
        "&transport_cost_per_km=15",
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          bestMarket = data["best_market"];
          markets = data["markets"] ?? [];
        });
      } else {
        final errorData = jsonDecode(response.body);

        throw Exception(errorData["detail"] ?? "Failed to get recommendation");
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String formatPrice(dynamic value) {
    if (value == null) return "₹0";

    final number = double.tryParse(value.toString()) ?? 0;

    return "₹${number.toStringAsFixed(2)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Best Market"), centerTitle: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "🌾 Find Best Market",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              "Find the market with the highest estimated net return.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 24),

            // CROP
            const Text(
              "Select Crop",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedCrop,

              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.grass),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              items: crops.map((crop) {
                return DropdownMenuItem(value: crop, child: Text(crop));
              }).toList(),

              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCrop = value;
                  });
                }
              },
            ),

            const SizedBox(height: 18),

            // QUANTITY
            const Text(
              "Quantity",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,

                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),

                    decoration: InputDecoration(
                      hintText: "Enter quantity",
                      prefixIcon: const Icon(Icons.scale),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                SizedBox(
                  width: 120,

                  child: DropdownButtonFormField<String>(
                    value: selectedUnit,

                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    items: units.map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
                    }).toList(),

                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedUnit = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // DISTRICT
            const Text(
              "Farmer District",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: districtController,

              decoration: InputDecoration(
                hintText: "Example: Satara",
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton.icon(
                onPressed: isLoading ? null : getRecommendation,

                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.analytics),

                label: Text(isLoading ? "Calculating..." : "Find Best Market"),

                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // BEST MARKET
            if (bestMarket != null) _buildBestMarketCard(),

            const SizedBox(height: 20),

            // OTHER MARKETS
            if (markets.isNotEmpty) _buildMarketsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBestMarketCard() {
    final market = bestMarket!;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: Colors.green, width: 2),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, size: 30),

              SizedBox(width: 10),

              Text(
                "Recommended Market",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            market["market"] ?? "Unknown Market",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          Text(
            "${market["district"] ?? ""}, Maharashtra",
            style: const TextStyle(color: Colors.grey),
          ),

          const Divider(height: 28),

          _infoRow("Modal Price", formatPrice(market["modal_price"])),

          _infoRow("Distance", "${market["distance_km"] ?? 0} km"),

          _infoRow("Transport Cost", formatPrice(market["transport_cost"])),

          _infoRow("Gross Sale Value", formatPrice(market["gross_value"])),

          const Divider(height: 24),

          _infoRow(
            "Estimated Net Return",
            formatPrice(market["net_return"]),
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMarketsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          "Other Markets",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        ...markets.skip(1).map((market) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),

            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.store)),

              title: Text(market["market"] ?? "Unknown Market"),

              subtitle: Text(
                "${market["district"] ?? ""} • "
                "${market["distance_km"] ?? 0} km",
              ),

              trailing: Text(
                formatPrice(market["net_return"]),

                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _infoRow(String title, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(
            title,

            style: TextStyle(
              fontSize: 15,

              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),

          Text(
            value,

            style: TextStyle(
              fontSize: highlight ? 19 : 15,

              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
