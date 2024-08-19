import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'booking_page.dart';
import 'review_page.dart';

class DetailsRoomPage extends StatefulWidget {
  final String roomId;
  final String collectionName;

  DetailsRoomPage({required this.roomId, required this.collectionName});

  @override
  _DetailsRoomPageState createState() => _DetailsRoomPageState();
}

class _DetailsRoomPageState extends State<DetailsRoomPage> {
  double averageRating = 0.0;
  Map<String, dynamic>? roomData;
  bool isInCart = false;
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _fetchRoomDetails();
    _calculateAverageRating();
    _checkIfInCart();
    _startImageSlideshow();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startImageSlideshow() {
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (_currentPage < roomData!['images'].length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 350),
        curve: Curves.easeIn,
      );
    });
  }

  Future<void> _fetchRoomDetails() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.roomId)
          .get();

      if (snapshot.exists) {
        setState(() {
          roomData = snapshot.data() as Map<String, dynamic>;
        });
      } else {
        setState(() {
          roomData = null;
        });
      }
    } catch (error) {
      print('Error fetching room details: $error');
      setState(() {
        roomData = null;
      });
    }
  }

  Future<void> _calculateAverageRating() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('room_id', isEqualTo: widget.roomId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        double totalRating = 0.0;
        int numberOfReviews = snapshot.docs.length;

        snapshot.docs.forEach((doc) {
          totalRating += doc['rating'];
        });

        setState(() {
          averageRating = totalRating / numberOfReviews;
        });
      } else {
        setState(() {
          averageRating = 0.0;
        });
      }
    } catch (error) {
      print('Error calculating average rating: $error');
    }
  }

  Future<void> _checkIfInCart() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user != null) {
        String? userEmail = user.email;

        final QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('cart')
            .where('room_id', isEqualTo: widget.roomId)
            .where('user_email', isEqualTo: userEmail)
            .get();

        setState(() {
          isInCart = snapshot.docs.isNotEmpty;
        });
      } else {
        setState(() {
          isInCart = false; // No user logged in, so not in cart
        });
      }
    } catch (error) {
      print('Error checking cart: $error');
    }
  }

  Future<void> _addToCart() async {
    if (isInCart) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Already in Cart'),
      ));
    } else if (roomData != null) {
      try {
        // Get currently logged-in user
        final FirebaseAuth auth = FirebaseAuth.instance;
        final User? user = auth.currentUser;

        if (user != null) {
          String? userEmail = user.email;

          // Add room to cart with user's email
          await FirebaseFirestore.instance.collection('cart').add({
            'room_id': widget.roomId,
            'name': roomData!['name'],
            'image': roomData!['images'][0],
            'price': roomData!['price'],
            'location': roomData!['location'],
            'user_email': userEmail,
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Room added to cart'),
          ));

          setState(() {
            isInCart = true;
          });
        } else {
          // No user logged in, handle this case
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('User not logged in'),
          ));
        }
      } catch (error) {
        print('Error adding to cart: $error');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to add room to cart'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Insights'),
      ),
      body: roomData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room Images Carousel
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: roomData!['images'].length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.network(
                            roomData!['images'][index],
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  // Room name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      roomData!['name'],
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 8),
                  // Location and Price section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Location: ${roomData!['location']}',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'BDT ${roomData!['price'].toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // Reviews and Ratings card
                  Card(
                    margin: EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListTile(
                      title: Text('Reviews and Ratings'),
                      subtitle: Row(
                        children: List.generate(5, (index) {
                          return Icon(Icons.star,
                              color: index < averageRating
                                  ? Colors.amber
                                  : Colors.grey);
                        }),
                      ),
                      trailing: FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('reviews')
                            .where('room_id', isEqualTo: widget.roomId)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return SizedBox();
                          }
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              4,
                              (index) {
                                if (index < snapshot.data!.docs.length) {
                                  return CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      snapshot.data!.docs[index]['user_image'],
                                    ),
                                    radius: 15,
                                  );
                                } else {
                                  return CircleAvatar(
                                    backgroundImage: AssetImage(
                                        'assets/user_placeholder.jpg'),
                                    radius: 15,
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ReviewsPage(roomId: widget.roomId)),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  // What We Offer section (example amenities)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('What We Offer',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: <Widget>[
                              _buildOfferIcon(Icons.bed, 'Twin Bed'),
                              _buildOfferIcon(Icons.local_parking, 'Parking'),
                              _buildOfferIcon(Icons.wifi, 'WiFi'),
                              _buildOfferIcon(Icons.pool, 'Pool'),
                              _buildOfferIcon(Icons.fastfood, 'Snack'),
                              _buildOfferIcon(
                                  Icons.free_breakfast, 'Breakfast'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // Description section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text(
                          roomData!['description'],
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _makePhoneCall('tel:+8801623094662');
                },
                icon: Icon(Icons.call),
                label: Text('Call Now'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            isInCart
                ? Expanded(
                    child: ElevatedButton(
                      onPressed: null,
                      child: Text('Already in Cart'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  )
                : Expanded(
                    child: ElevatedButton.icon(
                      onPressed: roomData == null
                          ? null
                          : () {
                              _addToCart();
                            },
                      icon: Icon(Icons.shopping_cart),
                      label: Text('Add to Cart'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
            roomData == null || roomData!['status'] == true
                ? Expanded(
                    child: ElevatedButton(
                      onPressed: null,
                      child: Text('Already Booked'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  )
                : Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BookingPage(roomId: widget.roomId),
                          ),
                        );
                      },
                      icon: Icon(Icons.book),
                      label: Text('Book Now'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildOfferIcon(IconData icon, String label) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 30, color: Colors.cyan),
          SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DetailsRoomPage(
      roomId: 'abc123', // Replace with actual room ID from your Firestore
      collectionName:
          'rooms', // Replace with actual collection name from your Firestore
    ),
  ));
}
