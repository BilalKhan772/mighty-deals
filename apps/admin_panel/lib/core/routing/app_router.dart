import 'package:flutter/material.dart';
import '../../features/orders/ui/orders_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case OrdersScreen.route:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
    }
  }
}
