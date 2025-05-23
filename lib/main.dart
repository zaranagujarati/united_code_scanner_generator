import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:united_code_scanner_generator/Home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  runApp(MaterialApp(home: Splash(),debugShowCheckedModeBanner: false,));
}

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    Timer(const Duration(seconds: 5), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    });
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.camera,
    ].request();

    if (statuses[Permission.storage]!.isGranted &&
        statuses[Permission.camera]!.isGranted) {
      // If all permissions are granted, navigate to Home
      Timer(const Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: () {
        SystemNavigator.pop();  
        return Future.value();
      },
      child: Scaffold(
        backgroundColor: Colors.blueGrey.shade50,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "United Tech & Solutions",
              style: TextStyle(
                  fontFamily: "f1",
                  fontSize: h / 35,
                  fontWeight: FontWeight.bold),
            ),
            Center(
              child: Container(
                  height: 500,
                  child: Lottie.asset("assets/images/animation.json")
              ),
            ),
          ],
        ),
      ),
    );
  }
}
