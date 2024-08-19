import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart'; // Import your home.dart
import 'explore.dart'; // Import your explore.dart
import 'profile_page.dart'; // Import your profile_page.dart

class ReviewsPage extends StatefulWidget {
  final String roomId;

  ReviewsPage({required this.roomId});

  @override
  _ReviewsPageState createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final _formKey = GlobalKey<FormState>();
  String? _userEmail; // Store user email instead of name
  String? _reviewText;
  double _rating = 0;

  int _selectedIndex = 0; // Current selected tab index
  bool _hasBooking = false; // Store if the user has a booking

  @override
  void initState() {
    super.initState();
    _getUserEmail();
  }

  void _getUserEmail() async {
    // Get current user's email
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      _userEmail = user?.email;
      if (_userEmail != null) {
        _checkUserBooking();
      }
    });
  }

  void _checkUserBooking() async {
    // Check if the user has a booking for the room
    var bookingSnapshot = await FirebaseFirestore.instance
        .collection('room_booking')
        .where('user_email', isEqualTo: _userEmail)
        .where('room_id', isEqualTo: widget.roomId)
        .limit(1)
        .get();

    setState(() {
      _hasBooking = bookingSnapshot.docs.isNotEmpty;
    });
  }

  void _submitReview() async {
    // Ensure _userEmail is not null or empty
    if (_userEmail == null || _userEmail!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('User email not available. Please log in again.'),
      ));
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Retrieve user profile information based on email
      var userProfileSnapshot = await FirebaseFirestore.instance
          .collection('users_profile')
          .where('email', isEqualTo: _userEmail)
          .limit(1)
          .get();

      String userImage = ''; // Default value
      String userName = ''; // Default value

      if (userProfileSnapshot.docs.isNotEmpty) {
        var userProfile = userProfileSnapshot.docs.first;
        userName = userProfile['name'];
        userImage = userProfile['image'];
      }

      // Save review to Firestore
      await FirebaseFirestore.instance.collection('reviews').add({
        'room_id': widget.roomId,
        'user_email': _userEmail,
        'user_name': userName, // User name retrieved from user_profile
        'user_image': userImage, // User image URL retrieved from user_profile
        'review_text': _reviewText,
        'rating': _rating,
      });

      // Clear form fields
      _formKey.currentState!.reset();
      setState(() {
        _rating = 0;
      });

      // Show confirmation message
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Review submitted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews and Ratings'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reviews')
                    .where('room_id', isEqualTo: widget.roomId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var reviews = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      var review = reviews[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(review['user_image']),
                          ),
                          title: Text(review['user_name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(review['review_text']),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    Icons.star,
                                    color: starIndex < review['rating']
                                        ? Colors.amber
                                        : Colors.grey,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              Divider(),
              if (_hasBooking)
                Column(
                  children: [
                    Text(
                      'Submit a Review',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Review as $_userEmail', // Displaying the user's email
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Review'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your review';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _reviewText = value;
                            },
                          ),
                          SizedBox(height: 10),
                          Text('Rating: $_rating', style: TextStyle(fontSize: 18)),
                          Slider(
                            value: _rating,
                            onChanged: (newRating) {
                              setState(() {
                                _rating = newRating;
                              });
                            },
                            divisions: 5,
                            label: _rating.toString(),
                            min: 0,
                            max: 5,
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _submitReview,
                            child: Text('Submit Review'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (_selectedIndex) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  HomePage()), // Replace with your home.dart route
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ExplorePage()), // Replace with your explore.dart route
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ProfilePage()), // Replace with your profile_page.dart route
        );
        break;
    }
  }
}
