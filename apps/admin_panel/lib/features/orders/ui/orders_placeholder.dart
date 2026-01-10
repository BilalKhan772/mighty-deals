import 'package:flutter/material.dart';

class OrdersPlaceholder extends StatelessWidget {
  static const route = '/orders';
  const OrdersPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: const Center(
        child: Text(
          'Orders screen (Coming soon)',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
