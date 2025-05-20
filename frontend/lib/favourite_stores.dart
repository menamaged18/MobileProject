import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';

class FavoriteStoresPage extends StatefulWidget {
  const FavoriteStoresPage({super.key});

  @override
  State<FavoriteStoresPage> createState() => _FavoriteStoresPageState();
}

class _FavoriteStoresPageState extends State<FavoriteStoresPage> {
  List<Map<String, dynamic>> favoriteStoresWithDistance = []; // Stores with added distance data
  bool _isLoading = true; // To show loading indicator

  @override
  void initState() {
    super.initState();
    fetchFavoriteStores(); // Load favorite stores when page starts
  }

  // Fetch the user's favorite stores from the backend API
  Future<void> fetchFavoriteStores() async {
    var box = await Hive.openBox('authBox');
    String? token = box.get('token'); // Get saved auth token

    if (token == null) {
      // If user is not logged in
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not logged in.')),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      // Make HTTP GET request to fetch favorite stores
      final response = await http.get(
        Uri.parse('http://localhost:3000/user/favorite-stores'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // Parse the response
        final data = jsonDecode(response.body);
        final List stores = data['data']['favoriteStores'] ?? [];

        // Get the user's current location
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Add distance from current location to each store
        final updatedStores = stores.map<Map<String, dynamic>>((store) {
          final coords = store['location']['coordinates'];
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            coords[1], // latitude
            coords[0], // longitude
          ) / 1000; // Convert to kilometers
          return {
            ...store,
            'distanceInKm': distance,
          };
        }).toList();

        // Update UI
        if (mounted) {
          setState(() {
            favoriteStoresWithDistance = updatedStores;
            _isLoading = false;
          });
        }
      } else {
        // If request fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load favorite stores')),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      // Handle errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading favorite stores.')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // Remove a store from user's favorites
  Future<void> removeFromFavorites(String storeId) async {
    var box = await Hive.openBox('authBox');
    String? token = box.get('token');

    if (token == null) return;

    try {
      // Send DELETE request
      final response = await http.delete(
        Uri.parse('http://localhost:3000/user/favorite-stores/$storeId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          // Remove store from local list
          setState(() {
            favoriteStoresWithDistance.removeWhere((store) => store['_id'] == storeId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
        }
      } else {
        // If deletion failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove store')),
          );
        }
      }
    } catch (e) {
      // Catch unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error removing store')),
        );
      }
    }
  }

  // Assign color to store card based on first letter of name
  Color _getStoreColor(String name) {
    if (name.isEmpty) return Colors.grey.shade200;
    final char = name[0].toUpperCase();
    if ("ABC".contains(char)) return Colors.pink.shade100;
    if ("DEF".contains(char)) return Colors.green.shade100;
    if ("GHI".contains(char)) return Colors.orange.shade100;
    return Colors.blue.shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favorite Stores")),

      // Body content based on loading state
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loader
          : favoriteStoresWithDistance.isEmpty
              ? const Center(child: Text("No favorite stores added yet.")) // Empty state
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: favoriteStoresWithDistance.length,
                  itemBuilder: (context, index) {
                    final store = favoriteStoresWithDistance[index];
                    final bgColor = _getStoreColor(store['name'] ?? '');

                    return Card(
                      color: bgColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Store icon
                            const Icon(Icons.store, size: 40, color: Colors.black54),
                            const SizedBox(width: 12),

                            // Store details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store['name'] ?? 'Store Name',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(store['address'] ?? 'Address'),
                                  if (store['distanceInKm'] != null)
                                    Text("Distance: ${store['distanceInKm'].toStringAsFixed(2)} km"),
                                ],
                              ),
                            ),

                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                              onPressed: () => removeFromFavorites(store['_id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
