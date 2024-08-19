import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_list_page.dart';
import 'cart.dart'; // Import the Cart page

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user
    String? uid = user?.uid; // Get the current user's UID

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // Sign out the user
              Navigator.pushReplacementNamed(
                  context, '/login'); // Navigate to login page
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users_profile')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('No profile data available'));
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;

            // Assuming 'image' field in userData contains Facebook profile image URL
            String facebookProfileImageUrl =
                userData['image'] ?? 'https://via.placeholder.com/150';

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 100,
                      backgroundImage: NetworkImage(facebookProfileImageUrl),
                    ),
                  ),
                  SizedBox(height: 20),
                  ProfileCard(
                    label: 'Name',
                    value: userData['name'] ?? 'No name available',
                    icon: Icons.person,
                  ),
                  SizedBox(height: 20),
                  ProfileCard(
                    label: 'Email',
                    value: userData['email'] ?? 'No email available',
                    icon: Icons.email,
                  ),
                  SizedBox(height: 20),
                  ProfileCard(
                    label: 'Phone',
                    value: userData['phone'] ?? 'No phone available',
                    icon: Icons.phone,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BookingListPage(userEmail: userData['email']),
                        ),
                      );
                    },
                    child: ProfileCard(
                      label: 'My Booking',
                      value: 'View your bookings',
                      icon: Icons.book_online,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartPage(),
                        ),
                      );
                    },
                    child: ProfileCard(
                      label: 'My Cart',
                      value: 'View your cart items',
                      icon: Icons.shopping_cart,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  ProfileCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.blue,
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700]),
                ),
                SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
