import 'package:flutter/material.dart';

class CreateRestaurantPlaceholder extends StatelessWidget {
  static const route = '/create-restaurant';
  const CreateRestaurantPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Restaurant')),
      body: const Center(
        child: Text(
          'Create Restaurant screen (Coming soon)',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
