import 'package:flutter/material.dart';
import 'manage_database_page.dart';
// Assuming you have a LoginPage widget in login_page.dart
import 'login_page.dart';

class ManageDatabase extends StatelessWidget {
  final List<Map<String, dynamic>> sections = [
    {
      'title': 'Insert Rooms',
      'collection': 'rooms',
      'fields': [
        'name',
        'location',
        'price',
        'description',
        'images',
        'status'
      ],
      'color': Colors.blueAccent,
    },
    {
      'title': 'User List',
      'collection': 'users_profile',
      'fields': ['name', 'email', 'phone', 'image'],
      'color': Color.fromARGB(255, 167, 20, 212),
    },
    {
      'title': 'Room Booking',
      'collection': 'room_booking',
      'fields': [
        'start_date',
        'end_date',
        'transaction_id',
        'user_email',
        'room_id'
      ],
      'color': Colors.green,
    },
    {
      'title': 'Reviews',
      'collection': 'reviews',
      'fields': ['room_id', 'review_text', 'user_email', 'rating'],
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Database'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Add your logout functionality here
              // For example, FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: sections.length,
          itemBuilder: (context, index) {
            var section = sections[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageDatabasePage(
                        title: section['title'],
                        collection: section['collection'],
                        fields: section['fields'],
                        defaultValues: section['collection'] == 'rooms'
                            ? {'status': false}
                            : null,
                      ),
                    ),
                  );
                },
                child: Card(
                  color: section['color'],
                  child: Container(
                    width: 200,
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          section['title'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
