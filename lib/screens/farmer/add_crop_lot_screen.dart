import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddCropLotScreen extends StatefulWidget {
  const AddCropLotScreen({super.key});

  @override
  State<AddCropLotScreen> createState() => _AddCropLotScreenState();
}

class _AddCropLotScreenState extends State<AddCropLotScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController quantityController = TextEditingController();

  final TextEditingController expectedPriceController = TextEditingController();

  final TextEditingController locationController = TextEditingController();

  final TextEditingController harvestDateController = TextEditingController();

  String? selectedCrop;
  String selectedUnit = 'Kg';
  String selectedQuality = 'Good';

  bool isLoading = false;

  final List<String> crops = [
    'Tomato',
    'Onion',
    'Potato',
    'Wheat',
    'Rice',
    'Sugarcane',
    'Maize',
    'Soybean',
    'Cotton',
    'Other',
  ];

  final List<String> qualities = ['Excellent', 'Good', 'Average'];

  final List<String> units = ['Kg', 'Quintal', 'Ton'];

  @override
  void dispose() {
    quantityController.dispose();
    expectedPriceController.dispose();
    locationController.dispose();
    harvestDateController.dispose();
    super.dispose();
  }

  Future<void> selectHarvestDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        harvestDateController.text =
            '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
      });
    }
  }

  Future<void> saveCropLot() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCrop == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a crop')));
      return;
    }

    if (harvestDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select harvest date')),
      );
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User is not logged in')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final DocumentReference lotRef = FirebaseFirestore.instance
          .collection('farmer_lots')
          .doc();

      await lotRef.set({
        'lotId': lotRef.id,
        'farmerId': user.uid,
        'crop': selectedCrop,
        'quantity': double.parse(quantityController.text.trim()),
        'unit': selectedUnit,
        'quality': selectedQuality,
        'location': locationController.text.trim(),
        'expectedPrice': double.parse(expectedPriceController.text.trim()),
        'harvestDate': harvestDateController.text.trim(),
        'imageUrl': null,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crop lot added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add crop lot: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Crop Lot'), centerTitle: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Column(
                  children: [
                    Icon(
                      Icons.agriculture,
                      size: 55,
                      color: Colors.green.shade700,
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'List Your Crop',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Add your crop details for buyers',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Crop
              DropdownButtonFormField<String>(
                initialValue: selectedCrop,
                decoration: inputDecoration(
                  label: 'Select Crop',
                  icon: Icons.grass,
                ),
                items: crops.map((crop) {
                  return DropdownMenuItem(value: crop, child: Text(crop));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCrop = value;
                  });
                },
              ),

              const SizedBox(height: 18),

              // Quantity
              TextFormField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: inputDecoration(
                  label: 'Quantity',
                  icon: Icons.scale,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }

                  if (double.tryParse(value.trim()) == null) {
                    return 'Enter a valid quantity';
                  }

                  if (double.parse(value.trim()) <= 0) {
                    return 'Quantity must be greater than 0';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Unit
              DropdownButtonFormField<String>(
                initialValue: selectedUnit,
                decoration: inputDecoration(
                  label: 'Unit',
                  icon: Icons.straighten,
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

              const SizedBox(height: 18),

              // Quality
              DropdownButtonFormField<String>(
                initialValue: selectedQuality,
                decoration: inputDecoration(
                  label: 'Crop Quality',
                  icon: Icons.star,
                ),
                items: qualities.map((quality) {
                  return DropdownMenuItem(value: quality, child: Text(quality));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedQuality = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 18),

              // Expected Price
              TextFormField(
                controller: expectedPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: inputDecoration(
                  label: 'Expected Price (₹)',
                  icon: Icons.currency_rupee,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter expected price';
                  }

                  if (double.tryParse(value.trim()) == null) {
                    return 'Enter a valid price';
                  }

                  if (double.parse(value.trim()) <= 0) {
                    return 'Price must be greater than 0';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Location
              TextFormField(
                controller: locationController,
                decoration: inputDecoration(
                  label: 'Crop Location',
                  icon: Icons.location_on,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter crop location';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Harvest Date
              TextFormField(
                controller: harvestDateController,
                readOnly: true,
                onTap: selectHarvestDate,
                decoration: inputDecoration(
                  label: 'Harvest Date',
                  icon: Icons.calendar_month,
                ),
              ),

              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : saveCropLot,

                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),

                  label: Text(
                    isLoading ? 'Saving...' : 'Save Crop Lot',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Center(
                child: Text(
                  'Your crop details will be visible to buyers.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}