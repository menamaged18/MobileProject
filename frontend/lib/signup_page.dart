import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';
import 'package:hive/hive.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  SignupPageState createState() => SignupPageState();
}


// This class holds the logic and UI for the signup page.
class SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  // final TextEditingController studentIdController = TextEditingController();
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String? gender;
  String? selectedLevel;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNextUserID();
  }

  // we use this function to display the user id 
  Future<void> _loadNextUserID() async {
    try {
      final resp = await http.get(Uri.parse("http://localhost:3000/user/next-userid"));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          userIdController.text = data['data']['nextUserID'].toString();
        });
      } else {
        // to do later --> handle error 
        debugPrint("❌ could not fetch user id: ");
      }
    } catch (e) {
      // to do later --> handle network error
    }
  }

  // This method handles the signup process by sending user data to the server.
 Future<void> signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    const String apiUrl = "http://localhost:3000/auth/signup";

    // getting the values from the page
    Map<String, dynamic> requestBody = {
      // "userID": int.tryParse(userIdController.text), // no need now back-end will handle it and increament automatically 
      "name": nameController.text,
      "email": emailController.text,
      "password": passwordController.text,
      "confirmPassword": confirmPasswordController.text,
      if (gender != null) "gender": gender,
      if (selectedLevel != null) "level": selectedLevel,
    };

    // try to send request to the database
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final box = await Hive.openBox('authBox');
        
        // Add null checks and fallbacks
        if (data['data']?['token'] != null) {
          await box.put('token', data['data']['token']);
          print("Token saved");
        } else {
          print("No token in response");
          _showMessage("Signup successful but login required", Colors.orange);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
          return;
        }

        // Only navigate if token exists
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else if (response.statusCode == 409) {
        _showMessage("${data['message']}", Colors.red);
      } else {
        _showMessage("Signup Failed: ${data['details']?[0]?['message'] ?? 'Unknown error'}", Colors.red);
      }
    } catch (e) {
      _showMessage("Error: Could not connect to server", Colors.black);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: userIdController,
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Name is required" : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    const Text("Gender: "),
                    Expanded(
                      child: RadioListTile(
                        title: const Text("Male"),
                        value: "male",
                        groupValue: gender,
                        onChanged: (value) =>
                            setState(() => gender = value),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile(
                        title: const Text("Female"),
                        value: "female",
                        groupValue: gender,
                        onChanged: (value) =>
                            setState(() => gender = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    // hintText: 'studentID@stud.fci-cu.edu.eg',
                    hintText: 'user@example.com',
                    hintStyle:
                        TextStyle(color: Color.fromARGB(255, 141, 141, 141)),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return "Email is required";
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Level',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedLevel,
                  items: const [
                    DropdownMenuItem(value: null, child: Text("None")), 
                    DropdownMenuItem(value: '1', child: Text("Level 1")),
                    DropdownMenuItem(value: '2', child: Text("Level 2")),
                    DropdownMenuItem(value: '3', child: Text("Level 3")),
                    DropdownMenuItem(value: '4', child: Text("Level 4")),
                  ],
                  onChanged: (value) => setState(() => selectedLevel = value),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return "Password is required";
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return "Confirm Password is required";
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: signup,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 12),
                          backgroundColor: Colors.purple,
                        ),
                        child: const Text('Signup',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

