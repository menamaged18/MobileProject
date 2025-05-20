// store_details_page
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';

class StoreDetailsPage extends StatefulWidget {
  final dynamic store;

  const StoreDetailsPage({super.key, required this.store});

  @override
  State<StoreDetailsPage> createState() => _StoreDetailsPageState();
}

class _StoreDetailsPageState extends State<StoreDetailsPage> {
  double? distanceInKm;
  bool isFavorite = false;
  List products = [];
  bool loadingProducts = true;

  @override
  void initState() {
    super.initState();
    _calculateDistance();
    _checkIfFavorite();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final storeID = widget.store['storeID'];
    final url = Uri.parse('http://localhost:3000/inventories/store/$storeID/products');
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      setState(() {
        products = data['data']['products'] ?? [];
        loadingProducts = false;
      });
    } else {
      // error handling
      setState(() => loadingProducts = false);
      debugPrint('❌ failed to load products: ${resp.statusCode}');
    }
  }

  Future<void> _calculateDistance() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final coords = widget.store['location']['coordinates'];
      final storeLon = coords[0];
      final storeLat = coords[1];
      final meters = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, storeLat, storeLon
      );
      setState(() => distanceInKm = meters / 1000);
    } catch (e) {
      debugPrint("❌ Error getting distance: $e");
      setState(() => distanceInKm = null);
    }
  }

  Future<void> _checkIfFavorite() async {
    final box = await Hive.openBox('authBox');
    final token = box.get('token') as String?;
    if (token == null) return;
    final resp = await http.get(
      Uri.parse('http://localhost:3000/user/favorite-stores'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final favs = jsonDecode(resp.body)['data']['favoriteStores'] as List;
      setState(() {
        isFavorite = favs.any((s) => s['_id'] == widget.store['_id']);
      });
    }
  }

  Future<void> _toggleFavorite(BuildContext ctx) async {
    final box = await Hive.openBox('authBox');
    final token = box.get('token') as String?;
    if (token == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Please log in to manage favorites.'))
      );
      return;
    }
    final method = isFavorite ? 'DELETE' : 'POST';
    final url = Uri.parse('http://localhost:3000/user/favorite-stores/${widget.store['_id']}');
    final resp = await http.Request(method, url)
      ..headers['Authorization'] = 'Bearer $token';
    final streamed = await resp.send();
    if (streamed.statusCode == 200) {
      setState(() => isFavorite = !isFavorite);
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(isFavorite ? 'Added to favorites' : 'Removed from favorites'))
      );
    } else {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Failed to update favorites'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      appBar: AppBar(title: Text(store['name'] ?? 'Store Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                store['storeImage'] ?? '',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.store, size: 80, color: Colors.white70),
                    ),
              ),
            ),

            const SizedBox(height: 16),

            // Name / address / distance
            Text(store['name'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(store['address'] ?? '', style: const TextStyle(fontSize: 16)),
            if (distanceInKm != null) ...[
              const SizedBox(height: 4),
              Text("Distance: ${distanceInKm!.toStringAsFixed(2)} km", style: const TextStyle(color: Colors.grey)),
            ],

            const SizedBox(height: 16),

            // Favorite button
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _toggleFavorite(context),
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                label: Text(isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFavorite ? Colors.redAccent : Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Products list
            const Text('Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (loadingProducts)
              const Center(child: CircularProgressIndicator())
            else if (products.isEmpty)
              const Center(child: Text('No products found.'))
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: products.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (ctx, i) {
                  final p = products[i];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        p['image'] ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                      ),
                    ),
                    title: Text(p['name'] ?? ''),
                    subtitle: Text('Price: \$${p['price'].toStringAsFixed(2)}'),
                    // we may need to use this in the future
                    // onTap: () {
                    //   // maybe navigate to product detail
                    // },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
