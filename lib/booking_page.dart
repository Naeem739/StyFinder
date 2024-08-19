import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'home.dart';  // Import your home page

class BookingPage extends StatefulWidget {
  final String roomId;

  BookingPage({required this.roomId});

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _transactionIdController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_formKey.currentState!.validate()) {
      final userEmail = FirebaseAuth.instance.currentUser!.email;

      // Prepare room booking data
      final roomBooking = {
        'room_id': widget.roomId,
        'user_email': userEmail,
        'start_date': _startDate,
        'end_date': _endDate,
        'transaction_id': _transactionIdController.text,
      };

      // Add booking to 'room_booking' collection
      await FirebaseFirestore.instance.collection('room_booking').add(roomBooking);

      // Update room status to true immediately upon booking
      await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({'status': true});

      // Schedule to turn status back to false after the end date
      if (_endDate != null) {
        Duration delay = _endDate!.difference(DateTime.now());
        Future.delayed(delay, () async {
          await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({'status': false});
        });
      }

      // Show success message and navigate back to HomePage
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully Booked')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Room'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _startDateController,
                decoration: InputDecoration(
                  labelText: 'Start Date',
                  hintText: 'Select start date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, _startDateController, true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a start date';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _endDateController,
                decoration: InputDecoration(
                  labelText: 'End Date',
                  hintText: 'Select end date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, _endDateController, false),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an end date';
                  }
                  // Ensure end date is after start date
                  if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
                    return 'End date must be after start date';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _transactionIdController,
                decoration: InputDecoration(
                  labelText: 'Transaction ID',
                  hintText: 'Enter transaction ID',
                  prefixIcon: Icon(Icons.receipt),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a transaction ID';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: _submitBooking,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
