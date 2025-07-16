// main.dart
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:string_similarity/string_similarity.dart';
import 'dart:async';


import 'downvsflap.dart';
import 'newimgtotext.dart';
import 'textvstex.dart';


@JS('Tesseract')
external TesseractJS get tesseract;

@JS()
@anonymous
class TesseractJS {
  external dynamic recognize(String image, String lang, dynamic options);
}

void main() => runApp(const MaterialApp(home: MainApp(), debugShowCheckedModeBanner: false));

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    ManualTextCompare(),
      DownVsFlap(), 
      ImageTextExtractor(),
  ];

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
  body: IndexedStack(index: selectedIndex, children: pages),
  bottomNavigationBar: Theme(
  data: Theme.of(context).copyWith(
    canvasColor: Colors.blueGrey.shade900,
    primaryColor: Colors.amberAccent,
    textTheme: Theme.of(context).textTheme.copyWith(
      labelSmall: const TextStyle(color: Colors.white70),
    ),
  ),
  child: BottomNavigationBar(
    currentIndex: selectedIndex,
    onTap: (index) => setState(() => selectedIndex = index),
    type: BottomNavigationBarType.fixed,
    selectedItemColor: Colors.amberAccent,
    unselectedItemColor: Colors.white70,
    selectedLabelStyle: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
    ),
    unselectedLabelStyle: const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 13,
    ),
    showUnselectedLabels: true,
    items: const [
      BottomNavigationBarItem(
       // icon: Icon(Icons.add, size: 30),
        icon: Icon(Icons.text_fields, size: 30, color: Colors.white),
        activeIcon: Icon(Icons.text_fields, size: 30, color: Colors.amberAccent),
        label: 'مقارنة نصوص',
      ),
      BottomNavigationBarItem(
       // icon: Icon(Icons.add, size: 30),
       icon: Icon(Icons.warning, size: 30, color: Colors.white),
        activeIcon: Icon(Icons.warning, size: 30, color: Colors.amberAccent),
        label: 'Down vs Flap',
      ),
      BottomNavigationBarItem(
        //icon: Icon(Icons.add, size: 30),
        icon: Icon(Icons.image, size: 30, color: Colors.white),
        activeIcon: Icon(Icons.image, size: 30, color: Colors.amberAccent),
        label: 'تحليل صور',
      ),
    ],
  ),
),
);
  }
}

