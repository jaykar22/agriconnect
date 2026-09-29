import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/location_service.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final villageController = TextEditingController();
  final districtController = TextEditingController();
  final stateController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isSaving = false;
  bool isGettingLocation = false;

  String farmerName = '';
  String phone = '';
  String language = 'Marathi';

  double? latitude;
  double? longitude;

  final List<String> availableCrops = [
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

  List<String> selectedCrops = [];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      final farmerDoc = await _firestore
          .collection('farmers')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();

        farmerName = userData?['name'] ?? '';
        phone = userData?['phone'] ?? '';
      }

      if (farmerDoc.exists) {
        final data = farmerDoc.data()!;

        villageController.text = data['village'] ?? '';
        districtController.text = data['district'] ?? '';
        stateController.text = data['state'] ?? '';

        language = data['language'] ?? 'Marathi';

        final crops = data['crops'];

        if (crops is List) {
          selectedCrops = List<String>.from(crops);
        }

        // Load saved GPS coordinates
        if (data['latitude'] != null) {
          latitude = (data['latitude'] as num).toDouble();
        }

        if (data['longitude'] != null) {
          longitude = (data['longitude'] as num).toDouble();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Get farmer's current GPS location
  Future<void> getCurrentLocation() async {
    setState(() {
      isGettingLocation = true;
    });

    try {
      final position = await LocationService.getCurrentLocation();

      if (!mounted) return;

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location captured successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Location error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isGettingLocation = false;
        });
      }
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCrops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one crop')),
      );
      return;
    }

    // GPS is required for our market recommendation system
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture your farm location before saving.'),
        ),
      );
      return;
    }

    final user = _auth.currentUser;

    if (user == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      await _firestore.collection('farmers').doc(user.uid).set({
        'userId': user.uid,
        'name': farmerName,
        'phone': phone,
        'village': villageController.text.trim(),
        'district': districtController.text.trim(),
        'state': stateController.text.trim(),
        'crops': selectedCrops,
        'language': language,

        // GPS location
        'latitude': latitude,
        'longitude': longitude,

        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    }

    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    villageController.dispose();
    districtController.dispose();
    stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Farmer Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 55),
                  ),
                ),

                const SizedBox(height: 15),

                Center(
                  child: Text(
                    farmerName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                Center(
                  child: Text(
                    phone,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'Farm Location',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: villageController,
                  decoration: const InputDecoration(
                    labelText: 'Village',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter village';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: districtController,
                  decoration: const InputDecoration(
                    labelText: 'District',
                    prefixIcon: Icon(Icons.map),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter district';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: stateController,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    prefixIcon: Icon(Icons.public),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter state';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 25),

                // GPS Location Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.gps_fixed, color: Colors.green),
                          SizedBox(width: 10),
                          Text(
                            'GPS Location',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Your location is used to calculate the real road distance to markets.',
                        style: TextStyle(fontSize: 13),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isGettingLocation
                              ? null
                              : getCurrentLocation,
                          icon: isGettingLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                          label: Text(
                            isGettingLocation
                                ? 'Getting Location...'
                                : 'Get Current Location',
                          ),
                        ),
                      ),

                      if (latitude != null && longitude != null) ...[
                        const SizedBox(height: 15),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.green.shade50,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'Location captured',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              Text('Latitude: ${latitude!.toStringAsFixed(6)}'),

                              Text(
                                'Longitude: ${longitude!.toStringAsFixed(6)}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'Crops You Grow',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableCrops.map((crop) {
                    final selected = selectedCrops.contains(crop);

                    return FilterChip(
                      label: Text(crop),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            selectedCrops.add(crop);
                          } else {
                            selectedCrops.remove(crop);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 30),

                const Text(
                  'Preferred Language',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  initialValue: language,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.language),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Marathi', child: Text('मराठी')),
                    DropdownMenuItem(value: 'Hindi', child: Text('हिंदी')),
                    DropdownMenuItem(value: 'English', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        language = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : saveProfile,
                    icon: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(isSaving ? 'Saving...' : 'Save Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
