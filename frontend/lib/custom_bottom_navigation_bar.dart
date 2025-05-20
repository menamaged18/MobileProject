// new custom bottoms after adding favourite store
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'product_search.dart';         
import 'favourite_stores.dart';
import 'profile_screen.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  State<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomePage(),
    const ProductSearchScreen(),      
    const FavoriteStoresPage(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home),      label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search),    label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.star),      label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.person),    label: 'Profile'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
