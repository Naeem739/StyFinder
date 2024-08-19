import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingListPage extends StatelessWidget {
  final String userEmail;

  BookingListPage({required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('room_booking')
            .where('user_email', isEqualTo: userEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No bookings found'));
          }

          var bookings = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var booking = bookings[index].data() as Map<String, dynamic>?;
              if (booking == null) {
                return ListTile(
                  title: Text('Invalid booking data'),
                );
              }
              var roomId = booking['room_id'] as String?;

              if (roomId == null) {
                return ListTile(
                  title: Text('Invalid room ID'),
                );
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(roomId)
                    .get(),
                builder: (context, roomSnapshot) {
                  if (roomSnapshot.connectionState == ConnectionState.waiting) {
                    return Card(
                      child: ListTile(
                        title: Text('Loading room details...'),
                        subtitle: Text('Please wait...'),
                      ),
                    );
                  }
                  if (roomSnapshot.hasError) {
                    return Card(
                      child: ListTile(
                        title: Text('Error loading room details'),
                        subtitle: Text('${roomSnapshot.error}'),
                      ),
                    );
                  }
                  if (!roomSnapshot.hasData || !roomSnapshot.data!.exists) {
                    return Card(
                      child: ListTile(
                        title: Text('Room not found'),
                        subtitle: Text('Room ID: $roomId'),
                      ),
                    );
                  }

                  var roomData =
                      roomSnapshot.data!.data() as Map<String, dynamic>?;

                  if (roomData == null) {
                    return Card(
                      child: ListTile(
                        title: Text('Room data is null'),
                      ),
                    );
                  }

                  List<dynamic>? images = roomData['images'];
                  var imageUrl = images != null && images.isNotEmpty
                      ? images[0] as String
                      : 'https://via.placeholder.com/150';
                  var price = roomData['price']?.toString() ?? 'N/A';
                  var location = roomData['location']?.toString() ?? 'N/A';

                  return Card(
                    margin: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Price: $price',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Location: $location',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
