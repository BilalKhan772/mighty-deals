import 'package:flutter/material.dart';

class SpinsScreen extends StatelessWidget {
  const SpinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // ❌ const hata diya
      appBar: AppBar(title: const Text('Spins')),
      body: const Center(child: Text('Spins MVP later')),
    );
  }
}
