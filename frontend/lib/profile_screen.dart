import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _imageUrl;
  Map<String, dynamic>? userData;
  String? _token;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  // Set the base API URL depending on platform (web, Android emulator, etc.)
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  @override
  void initState() {
    super.initState();
    _initializeProfile(); // Load token and profile data on startup
  }

  Future<void> _initializeProfile() async {
    await _loadAuthToken(); // Load stored token from Hive
    await _fetchProfileData(); // Get user profile info
    setState(() => _isLoading = false);
  }

  // Load auth token from local Hive storage
  Future<void> _loadAuthToken() async {
    try {
      final authBox = await Hive.openBox('authBox');
      _token = authBox.get('token') as String?;
    } catch (e) {
      debugPrint('Error loading token: $e');
    }
  }

  // Get the user profile either from cache or fresh from the server
  Future<void> _fetchProfileData() async {
    if (_token == null) return;

    try {
      final authBox = await Hive.openBox('authBox');

      // Load cached user data
      final cached = authBox.get('user') as Map?;
      if (cached != null) {
        setState(() {
          userData = (cached['user'] as Map).cast<String, dynamic>();
          _imageUrl = userData?['imageProfile'] as String?;
        });
      }

      // Fetch the latest data from the server
      final resp = await http.get(
        Uri.parse("$_baseUrl/user/profile"),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body)['data'] as Map<String, dynamic>;
        setState(() {
          userData = (data['user'] as Map).cast<String, dynamic>();
          _imageUrl = userData?['imageProfile'] as String?;
        });
        await authBox.put('user', data); // Update cache
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  // Upload profile image from gallery
  Future<void> _handleImageUpload() async {
    if (_token == null) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse("$_baseUrl/user/upload-image");
      final req = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $_token';

      if (kIsWeb) {
        // For web: read file as bytes
        final bytes = await picked.readAsBytes();
        final mime = lookupMimeType(picked.name) ?? 'image/png';
        req.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: picked.name,
          contentType: MediaType.parse(mime),
        ));
      } else {
        // For mobile: use file path
        req.files.add(await http.MultipartFile.fromPath(
          'image',
          picked.path,
        ));
      }

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      final jsonResp = jsonDecode(body) as Map<String, dynamic>;

      if (streamed.statusCode == 200) {
        final newUrl = (jsonResp['data'] as Map)['imageUrl'] as String;
        setState(() => _imageUrl = newUrl);

        // Update local cache with new image
        final authBox = await Hive.openBox('authBox');
        final updated = {...?userData, 'imageProfile': newUrl};
        await authBox.put('user', {'user': updated});
        setState(() => userData = updated);
      } else {
        _showErrorSnackbar(jsonResp['message'] ?? 'Upload failed');
      }
    } catch (e) {
      _showErrorSnackbar('Image upload failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Navigate to Edit Profile screen
  Future<void> _navigateToEditProfile() async {
    if (userData == null) return;
    final updated = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(userData: userData!),
      ),
    );
    if (updated != null) {
      setState(() => userData = updated);
      final authBox = await Hive.openBox('authBox');
      await authBox.put('user', {'user': updated});
    }
  }

  // Show a red error snackbar
  void _showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.purple,
      ),
      body: _isLoading || userData == null
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileContent(),
    );
  }

  // Build the main profile content UI
  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfilePictureSection(),
          const SizedBox(height: 24),
          _buildUserInfoCard(),
          const SizedBox(height: 24),
          _buildEditProfileButton(),
        ],
      ),
    );
  }

  // Profile image + camera icon button
  Widget _buildProfilePictureSection() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 72,
          backgroundColor: Colors.grey.shade200,
          backgroundImage:
              _imageUrl != null ? NetworkImage(_imageUrl!) : null,
          child: _imageUrl == null
              ? const Icon(Icons.person, size: 72, color: Colors.white)
              : null,
        ),
        FloatingActionButton.small(
          backgroundColor: Colors.purple,
          onPressed: _handleImageUpload,
          child: const Icon(Icons.camera_alt, color: Colors.white),
        ),
      ],
    );
  }

  // Card to display user details
  Widget _buildUserInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // _buildInfoRow('Student ID', userData!['studentID']),
            // const Divider(height: 24),
            _buildInfoRow('Name', userData!['name']),
            const Divider(height: 24),
            _buildInfoRow('Gender', userData!['gender'] ?? 'Not specified'),
            const Divider(height: 24),
            _buildInfoRow('Email', userData!['email']),
            const Divider(height: 24),
            _buildInfoRow('Level', userData!['level']?.toString() ?? 'Not specified'),
          ],
        ),
      ),
    );
  }

  // Row for each piece of info
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Button to edit the profile
  Widget _buildEditProfileButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _navigateToEditProfile,
        child: const Text('Edit Profile',
            style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}


// nomral email format:
// m@gmail.com
// Pass12345@