// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'store_details_page.dart'; // Import the store details page to show detailed info when a store is tapped

// // Define the HomePage widget as a stateful widget
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// // The state class for HomePage
// class _HomePageState extends State<HomePage> {
//   // List to hold store data fetched from the API
//   List stores = [];

//   // Function to fetch stores from the backend API
//   Future<void> fetchStores() async {
//     final response = await http.get(Uri.parse('http://localhost:3000/stores'));

//     if (response.statusCode == 200) {
//       // If the request is successful, decode the response and update the state
//       setState(() {
//         stores = jsonDecode(response.body)['data']['stores'];
//         // debugPrint("🟢 store Data Fetched: $stores"); // Print the fetched data for debugging
//       });
//     } else {
//       // If there's an error, throw an exception
//       throw Exception('Failed to load stores');
//     }
//   }

//   // Called when the widget is inserted into the widget tree
//   @override
//   void initState() {
//     super.initState();
//     fetchStores(); // Fetch stores immediately when the page loads
//   }

//   // The UI of the HomePage
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // Top app bar with a title and background color
//       appBar: AppBar(
//         title: const Text("Home Page"),
//         backgroundColor: Colors.purple,
//       ),
//       // Main content area
//       body: stores.isEmpty
//           // If the stores list is empty, show a loading spinner
//           ? const Center(child: CircularProgressIndicator())
//           // Otherwise, show a scrollable list of stores
//           : ListView.builder(
//               itemCount: stores.length, // Number of store items
//               itemBuilder: (context, index) {
//                 return ListTile(
//                   // Display the store's name and address
//                   title: Text(stores[index]['name']),
//                   subtitle: Text(stores[index]['address']),
//                   // When tapped, navigate to the StoreDetailsPage and pass the store data
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => StoreDetailsPage(store: stores[index]),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//       // Optional: you can uncomment this if you want to use a bottom navigation bar
//       // bottomNavigationBar: const CustomBottomNavigationBar(),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'store_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List stores = [];

  Future<void> fetchStores() async {
    final response = await http.get(Uri.parse('http://localhost:3000/stores'));
    if (response.statusCode == 200) {
      setState(() {
        stores = jsonDecode(response.body)['data']['stores'];
      });
    } else {
      throw Exception('Failed to load stores');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchStores();
  }

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Home Page"),
          backgroundColor: Colors.purple,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final topStores = stores.take(2).toList();
    final otherStores = stores.length > 2 ? stores.sublist(2) : <dynamic>[];

    // constants for sizing
    const itemWidth = 160.0;
    const itemSpacing = 12.0;
    final screenWidth = MediaQuery.of(context).size.width;
    // compute padding so that items + spacing are centered
    final totalItemsWidth = itemWidth * topStores.length + itemSpacing * (topStores.length - 1);
    final horizontalPadding = (screenWidth - totalItemsWidth) / 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page"),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Centered horizontal strip
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding > 0 ? horizontalPadding : 8,
                vertical: 16,
              ),
              itemCount: topStores.length,
              itemBuilder: (context, idx) {
                final store = topStores[idx];
                return Container(
                  width: itemWidth,
                  margin: EdgeInsets.only(right: idx == topStores.length - 1 ? 0 : itemSpacing),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreDetailsPage(store: store),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              store['storeImage'] ?? '',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.store, size: 48),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          store['name'] ?? 'No name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView.builder(
              itemCount: otherStores.length,
              itemBuilder: (context, index) {
                final store = otherStores[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      store['storeImage'] ?? '',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.store, size: 32),
                    ),
                  ),
                  title: Text(store['name'] ?? 'No name'),
                  subtitle: Text(store['address'] ?? ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoreDetailsPage(store: store),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

