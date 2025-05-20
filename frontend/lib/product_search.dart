import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:sourcecode/store_details_page.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({Key? key}) : super(key: key); // Added key parameter

  @override
  ProductSearchScreenState createState() => ProductSearchScreenState(); // State class is now public
}

class ProductSearchScreenState extends State<ProductSearchScreen> {
  final String baseUrl = 'http://localhost:3000';
  List<Product> _products = [];
  Product? _selectedProduct;

  List<Store> _stores = [];
  bool _loading = false;
  bool _mapView = false;
  final Set<Marker> _markers = {}; 

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final resp = await http.get(Uri.parse('$baseUrl/products'));
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body)['data']['products'] as List;
      setState(() {
        _products = data.map((e) => Product.fromJson(e)).toList();
      });
    } else {
      // TODO: error handling
    }
  }

  Future<void> _onProductSelected(Product? p) async {
    setState(() {
      _selectedProduct = p;
      _stores = [];
      _markers.clear();
      _loading = true;
    });
    if (p != null) {
      final resp = await http.get(
        Uri.parse('$baseUrl/inventories/product/${p.productID}/stores'),
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body)['data']['stores'] as List;
        final stores = data.map((e) => Store.fromJson(e)).toList();
        setState(() {
          _stores = stores;
          for (var s in stores) {
            _markers.add(Marker(
              markerId: MarkerId(s.storeID.toString()),
              position: LatLng(
                s.location.coordinates[1],
                s.location.coordinates[0],
              ),
              infoWindow: InfoWindow(
                title: s.name,
                snippet: '\$${s.price}',
              ),
            ));
          }
        });
      } else {
        // TODO: error handling
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search by Product'),
        actions: [
          if (_stores.isNotEmpty)
            IconButton(
              icon: Icon(_mapView ? Icons.list : Icons.map),
              onPressed: () => setState(() => _mapView = !_mapView),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<Product>(
              isExpanded: true,
              hint: const Text('Select a product'),
              value: _selectedProduct,
              items: _products.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p.name),
                );
              }).toList(),
              onChanged: _onProductSelected,
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_stores.isEmpty && _selectedProduct != null)
            const Expanded(
              child: Center(child: Text('No stores found.')),
            )
          else if (_mapView)
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _stores.isNotEmpty
                      ? LatLng(
                          _stores.first.location.coordinates[1],
                          _stores.first.location.coordinates[0],
                        )
                      : const LatLng(0, 0),
                  zoom: 12,
                ),
                markers: _markers,
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _stores.length,
                itemBuilder: (_, i) {
                  final s = _stores[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: s.storeImage != null
                          ? Image.network(s.storeImage!, width: 50, fit: BoxFit.cover)
                          : null,
                      title: Text(s.name),
                      subtitle: Text('${s.address}\nPrice: \$${s.price}'),
                      isThreeLine: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoreDetailsPage(store: {
                              'storeID': s.storeID,
                              'name': s.name,
                              'address': s.address,
                              'storeImage': s.storeImage,
                              'location': {
                                'coordinates': s.location.coordinates,
                              },
                            }),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// Data models (unchanged):

class Product {
  final int productID;
  final String name;

  Product({required this.productID, required this.name});

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        productID: j['productID'],
        name: j['name'],
      );
}

class Store {
  final int storeID;
  final String name;
  final String address;
  final Location location;
  final String? storeImage;
  final double price;

  Store({
    required this.storeID,
    required this.name,
    required this.address,
    required this.location,
    this.storeImage,
    required this.price,
  });

  factory Store.fromJson(Map<String, dynamic> j) => Store(
        storeID: j['storeID'],
        name: j['name'],
        address: j['address'],
        storeImage: j['storeImage'],
        price: (j['price'] as num).toDouble(),
        location: Location.fromJson(j['location']),
      );
}

class Location {
  final List<double> coordinates;

  Location({required this.coordinates});

  factory Location.fromJson(Map<String, dynamic> j) => Location(
        coordinates: List<double>.from(j['coordinates']),
      );
}