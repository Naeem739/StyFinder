import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:room/cart.dart';
import 'details_room_page.dart'; // Import the details page
import 'profile_page.dart'; // Import the profile page
import 'explore.dart'; // Import the explore page
import 'login_page.dart';
import 'cart.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedLocation = 'All';
  int _selectedIndex = 0; // Current index for the bottom navigation bar

  final List<String> locations = [
    'All',
    'Cox\'s Bazar',
    'Kuakata',
    'Sundarbans Mangrove Forest',
    'Saint Martins',
    'Paharpur',
    'Dhaka',
    'Barishal',
    'Bandarban',
    'Jaflong',
    'Bangladesh National Zoo',
    'Natore Rajbari',
    'Kantanagar Temple',
    'Puthia Rajbari',
    'Chittagong',
    'Rangamati',
    'Sylhet'
  ];

  final List<String> imageUrls = [
    'https://images.pexels.com/photos/271816/pexels-photo-271816.jpeg',
    'https://images.pexels.com/photos/1643383/pexels-photo-1643383.jpeg',
    'https://images.pexels.com/photos/276517/pexels-photo-276517.jpeg',
    'https://images.pexels.com/photos/265072/pexels-photo-265072.jpeg',
    'https://images.pexels.com/photos/271805/pexels-photo-271805.jpeg',
    'https://images.pexels.com/photos/1571472/pexels-photo-1571472.jpeg'
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 1:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExplorePage()),
          );
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
        title: Text(
          'StyFinder',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        backgroundColor: Color(0x7a065d9d), // Set the background color
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'StayFinder',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.explore),
              title: Text('Explore'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExplorePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 200,
                autoPlay: true,
                enlargeCenterPage: true,
              ),
              items: imageUrls.map((url) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                      ),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            // Horizontal list of locations
            Container(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: locations.map((location) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedLocation = location;
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      margin: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: selectedLocation == location
                            ? Colors.blue
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          location,
                          style: TextStyle(
                            color: selectedLocation == location
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 10),
            // Featured rooms list
            Text('Featured Rooms',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              height: 250,
              child: StreamBuilder(
                stream: selectedLocation == 'All'
                    ? FirebaseFirestore.instance
                        .collection('rooms')
                        .limit(3)
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('rooms')
                        .where('location', isEqualTo: selectedLocation)
                        .limit(4)
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
                    scrollDirection: Axis.horizontal,
                    children: snapshot.data!.docs.map((room) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsRoomPage(
                                roomId: room.id,
                                collectionName: 'rooms',
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: RoomCard(room: room),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            // Recommended rooms list
            Text('Available Rooms',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              height: 250,
              child: StreamBuilder(
                stream: selectedLocation == 'All'
                    ? FirebaseFirestore.instance.collection('rooms').snapshots()
                    : FirebaseFirestore.instance
                        .collection('rooms')
                        .where('location', isEqualTo: selectedLocation)
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
                    scrollDirection: Axis.horizontal,
                    children: snapshot.data!.docs.map((room) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsRoomPage(
                                roomId: room.id,
                                collectionName: 'rooms',
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: RoomCard(room: room),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType
            .fixed, // Add this line to fix the navigation bar
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
            icon: Icon(Icons.shopping_cart), // Add to Cart icon
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        backgroundColor: Colors.white, // Set the background color
        onTap:
            _onItemTapped, // Use the existing _onItemTapped method to handle navigation
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final QueryDocumentSnapshot room;

  RoomCard({required this.room});

  Stream<double> _streamAverageRating(String roomId) {
    return FirebaseFirestore.instance
        .collection('reviews')
        .where('room_id', isEqualTo: roomId)
        .snapshots()
        .map((snapshot) {
      double totalRating = 0;
      int numberOfRatings = snapshot.docs.length;

      for (var doc in snapshot.docs) {
        totalRating += doc['rating'];
      }

      return numberOfRatings > 0 ? totalRating / numberOfRatings : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> images = List<String>.from(room['images'] ?? []);
    String imageUrl =
        images.isNotEmpty ? images[0] : 'https://via.placeholder.com/150';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Container(
        width: 220,
        height: 180,
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.network(
                    imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: StreamBuilder<double>(
                      stream: _streamAverageRating(room.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          print('Error fetching rating: ${snapshot.error}');
                          return Text(
                            'N/A',
                            style: TextStyle(color: Colors.white),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data == null) {
                          print('No rating data available');
                          return Text(
                            'N/A',
                            style: TextStyle(color: Colors.white),
                          );
                        }

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              snapshot.data!.toStringAsFixed(1),
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Text(
                    'BDT ${room['price']}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              room['name'],
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              room['location'],
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
