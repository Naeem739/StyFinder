import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:room/login_page.dart';
import 'package:room/register_page.dart';
import 'package:room/home.dart';
import 'package:room/manage_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
apiKey: 'AIzaSyB6_Sy7EU9pWrUp3G4FtSJOTh1Km1y5QQA',
appId: '1:245121000642:web:35a79',
messagingSenderId: '245121000642',
projectId: 'hotel-35a79',
databaseURL: 'https://hotel-35a79.firebaseio.com',
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login', // Set the initial route
      routes: {
        '/register': (context) => RegistrationPage(),
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/manageDatabase': (context) => ManageDatabase(),
        
      },
    );
  }
}
