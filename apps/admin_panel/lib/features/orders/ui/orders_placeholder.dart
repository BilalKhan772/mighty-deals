import 'package:flutter/material.dart';
import 'orders_screen.dart';

class OrdersPlaceholder extends StatelessWidget {
  static const route = OrdersScreen.route; // keep same route
  const OrdersPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const OrdersScreen();
  }
}
