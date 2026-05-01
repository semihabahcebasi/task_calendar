import 'package:flutter/material.dart';

class AnalizScreen extends StatefulWidget {
  const AnalizScreen({super.key});

  @override
  State<AnalizScreen> createState() => _AnalizScreenState();
}

class _AnalizScreenState extends State<AnalizScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analiz'),
        backgroundColor: const Color.fromARGB(255, 138, 52, 96),
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Analiz sayfası yakında!')),
    );
  }
}
