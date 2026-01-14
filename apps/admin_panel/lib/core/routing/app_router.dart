import 'package:flutter/material.dart';

import '../../features/orders/ui/orders_screen.dart';
import '../../features/restaurants/ui/restaurants_screen.dart';
import '../../features/restaurants/ui/create_restaurant_placeholder.dart';
import '../../features/deals/ui/deals_screen.dart';
import '../../features/menu/ui/menu_screen.dart';
import '../../features/notifications/ui/notifications_screen.dart';
import '../../features/orders/ui/orders_placeholder.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case OrdersScreen.route:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());

      case OrdersPlaceholder.route:
        return MaterialPageRoute(builder: (_) => const OrdersPlaceholder());

      case NotificationsScreen.route:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case RestaurantsScreen.route:
        return MaterialPageRoute(builder: (_) => const RestaurantsScreen());

      case CreateRestaurantPlaceholder.route:
        return MaterialPageRoute(builder: (_) => const CreateRestaurantPlaceholder());

      case DealsAdminScreen.route:
        return MaterialPageRoute(builder: (_) => const DealsAdminScreen());

      case MenuAdminScreen.route:
        return MaterialPageRoute(builder: (_) => const MenuAdminScreen());

      default:
        return _notFound(settings.name ?? 'unknown');
    }
  }

  static MaterialPageRoute _notFound(String name) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: Center(child: Text('Route not found: $name')),
      ),
    );
  }
}
