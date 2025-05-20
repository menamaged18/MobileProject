import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'Custom_Bottom_Navigation_Bar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  // Controllers to get input from the email and password fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // State variable to show loading indicator
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus(); // Check if user already logged in before
  }

  // If there's already a token saved in Hive, skip login and go to Home
  Future<void> checkLoginStatus() async {
    var box = await Hive.openBox('authBox');
    String? token = box.get('token');

    if (token != null) {
      debugPrint("🟢 Token found: $token");

      // Fetch profile info using the token
      await getUserProfile(token);

      // Navigate to HomePage (or bottom nav)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  // Handles login logic
  Future<void> login() async {
    setState(() => isLoading = true); // Show loading spinner

    const String apiUrl = "http://localhost:3000/auth/login";

    try {
      // Send email and password to backend
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text,
          "password": passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        var box = await Hive.openBox('authBox');
        await box.put('token', data['data']); // Save token
        String token = data['data'];

        // Fetch and save user profile
        await getUserProfile(token);

        _showMessage("Login Successful!", Colors.green);

        // Navigate to Bottom Navigation Bar
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomBottomNavigationBar()),
        );
      } else {
        _showMessage("Login Failed: ${data['message'] ?? 'Unknown error'}", Colors.red);
      }
    } catch (e) {
      _showMessage("Error: Could not connect to server", Colors.black);
    } finally {
      setState(() => isLoading = false); // Hide loading spinner
    }
  }

  // Get user profile info using token and save it to Hive
  Future<void> getUserProfile(String token) async {
    const String profileUrl = "http://localhost:3000/user/profile";

    try {
      final response = await http.get(
        Uri.parse(profileUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // Attach token for auth
        },
      );

      if (response.statusCode == 200) {
        final profileData = jsonDecode(response.body);
        // debugPrint("🟢 Profile Data Fetched: $profileData");

        var box = await Hive.openBox('authBox');
        await box.put('user', profileData['data']); // Save profile in Hive

        var storedData = box.get('user');
        // debugPrint("🟢 Stored User Data in Hive: $storedData");

        if (storedData != null) {
          _showMessage("Profile data saved successfully!", Colors.green);
        } else {
          _showMessage("⚠️ Failed to save profile data in Hive!", Colors.red);
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showMessage("❌ Failed to get profile: ${errorData['message']}", Colors.red);
      }
    } catch (e) {
      _showMessage("❌ Error fetching profile: $e", Colors.black);
    }
  }

  // Helper to show snackbars with messages
  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // Navigate to Signup Page
  void navigateToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, size: 100, color: Colors.blueAccent),
            const SizedBox(height: 16),
            // Email Text Field
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email, size: 25, color: Colors.blueGrey),
                labelText: 'Email',
                // hintText: 'studentID@stud.fci-cu.edu.eg',
                hintText: 'example@gmail.com',
                hintStyle: TextStyle(color: Color.fromARGB(255, 141, 141, 141)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Password Text Field
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.lock, size: 25, color: Colors.blueGrey),
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // Login Button or Loading Spinner
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
            const SizedBox(height: 10),
            // Link to Signup
            TextButton(
              onPressed: navigateToSignup,
              child: const Text('Dont have an account? Sign Up', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }
}
