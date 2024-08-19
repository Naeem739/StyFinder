import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'details_room_page.dart'; // Import the details page
import 'cart.dart';
import 'profile_page.dart'; // Import the profile page
import 'login_page.dart';

class ExplorePage extends StatefulWidget {
  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String searchLocation = ''; // To store user's search location

  // Function to format search location
  String formatSearchLocation(String location) {
    if (location.isEmpty) return '';
    return location.substring(0, 1).toUpperCase() +
        location.substring(1).toLowerCase();
  }

  int _selectedIndex = 1; // Current index for the bottom navigation bar

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          Navigator.pop(context);
          break;
        case 2:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CartPage()),
          );
          break;
        case 3:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage()),
          );
          break;
      }
    });
  }

  void _handleLogout() {
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => LoginPage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inspect Rooms'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Enter location...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    // Format and set search location
                    setState(() {});
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchLocation = value.trim();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collectionGroup('rooms')
                  .where('status',
                      isEqualTo: false) // Fetch rooms where status is false
                  .where('location',
                      isEqualTo: formatSearchLocation(
                          searchLocation)) // Filter by searchLocation
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No rooms available'));
                }

                return ListView(
                  children: snapshot.data!.docs.map((room) {
                    List<String> images =
                        List<String>.from(room['images'] ?? []);
                    String imageUrl = images.isNotEmpty
                        ? images[0]
                        : ''; // Use the first image as the list tile image

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsRoomPage(
                              roomId: room.id,
                              collectionName: room.reference.parent!.id,
                              // Assuming room reference contains collection name
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        title: Text(room['name']),
                        subtitle: Text(room['location']),
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(imageUrl),
                        ),
                        trailing: Text('BDT ${room['price']}'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}
