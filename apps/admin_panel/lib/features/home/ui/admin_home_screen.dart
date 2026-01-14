import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../notifications/ui/notifications_screen.dart';
import '../../orders/ui/orders_placeholder.dart';

// ✅ NEW imports
import '../../restaurants/ui/restaurants_screen.dart';
import '../../deals/ui/deals_screen.dart';
import '../../menu/ui/menu_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Widget _menuItem({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.85)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              Color(0xFF0F2B55), // top glow
              Color(0xFF071425), // mid
              Color(0xFF050B16), // bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Menu Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.16)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ✅ IMPORTANT CHANGE:
                          // Create Restaurant Account -> Restaurants screen (list + create button inside)
                          _menuItem(
                            context: context,
                            title: 'Restaurants',
                            icon: Icons.storefront,
                            onTap: () => Navigator.pushNamed(
                              context,
                              RestaurantsScreen.route,
                            ),
                          ),

                          Divider(height: 1, color: Colors.white.withOpacity(0.12)),

                          // ✅ Deals admin
                          _menuItem(
                            context: context,
                            title: 'Deals',
                            icon: Icons.local_offer,
                            onTap: () => Navigator.pushNamed(
                              context,
                              DealsAdminScreen.route,
                            ),
                          ),

                          Divider(height: 1, color: Colors.white.withOpacity(0.12)),

                          // ✅ Menu admin
                          _menuItem(
                            context: context,
                            title: 'Menu Items',
                            icon: Icons.restaurant_menu,
                            onTap: () => Navigator.pushNamed(
                              context,
                              MenuAdminScreen.route,
                            ),
                          ),

                          Divider(height: 1, color: Colors.white.withOpacity(0.12)),

                          _menuItem(
                            context: context,
                            title: 'Notifications',
                            icon: Icons.notifications_active,
                            onTap: () => Navigator.pushNamed(
                              context,
                              NotificationsScreen.route,
                            ),
                          ),

                          Divider(height: 1, color: Colors.white.withOpacity(0.12)),

                          _menuItem(
                            context: context,
                            title: 'Orders',
                            icon: Icons.receipt_long,
                            onTap: () => Navigator.pushNamed(
                              context,
                              OrdersPlaceholder.route,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 180,
                        height: 44,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.14),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();
                          },
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Log out'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
