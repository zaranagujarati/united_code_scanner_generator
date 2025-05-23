
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:united_code_scanner_generator/Generator.dart';
import 'package:united_code_scanner_generator/Scanner.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _cIndex = 0;
  final pages = [Generator(), Scanner()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_cIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _cIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code,color: Colors.blueGrey), label: 'Generate',),
          BottomNavigationBarItem(icon: Icon(Icons.scanner,color: Colors.blueGrey), label: 'Scan'),
        ],
        onTap: (index) => setState(() => _cIndex = index),
      ),
    );
  }
}

