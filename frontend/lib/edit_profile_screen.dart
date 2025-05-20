import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import 'profile_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _studentIDController;

  String? _selectedGender;
  String? _selectedLevel;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _studentIDController = TextEditingController(text: widget.userData['studentID'].toString());

    _selectedGender = widget.userData['gender'] ?? 'Male';
    _selectedLevel = widget.userData['level']?.toString();
  }

  // void _saveChanges() {
  //   if (_formKey.currentState!.validate()) {
  //     Navigator.pop(context, {
  //       'name': _nameController.text,
  //       // 'gender': _selectedGender,
  //       'email': _emailController.text,
  //       'level': _selectedLevel,
  //     });
  //   }
  // }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      var box = await Hive.openBox('authBox');
      String? token = box.get('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not logged in. Please log in again.')),
        );
        return;
      }

      final url = Uri.parse('http://localhost:3000/user/update/${widget.userData['_id']}');

      final body = jsonEncode({
        'name': _nameController.text,
        'gender': _selectedGender,
        'email': _emailController.text,
        'studentID': _studentIDController.text,
        'level': _selectedLevel != null ? int.tryParse(_selectedLevel!) : null,
      });

      try {
        final response = await http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body,
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          final profileData = jsonDecode(response.body);
          var box = await Hive.openBox('authBox');
          await box.put('user', profileData['data']);

          Navigator.pushReplacement(
            context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        } else {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: ${data['message']}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile"), backgroundColor: Colors.purple),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
              const SizedBox(height: 16),
              const Text("Gender", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Male'),
                        value: 'Male',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Female'),
                        value: 'Female',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Level',
                  border: OutlineInputBorder(),
                ),
                value: _selectedLevel,
                items: const [
                  DropdownMenuItem(value: null, child: Text("None")),
                  DropdownMenuItem(value: '1', child: Text("Level 1")),
                  DropdownMenuItem(value: '2', child: Text("Level 2")),
                  DropdownMenuItem(value: '3', child: Text("Level 3")),
                  DropdownMenuItem(value: '4', child: Text("Level 4")),
                ],
                onChanged: (value) => setState(() => _selectedLevel = value),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _updateUser, child: const Text("Save Changes")),
            ],
          ),
        ),
      ),
    );
  }
}
