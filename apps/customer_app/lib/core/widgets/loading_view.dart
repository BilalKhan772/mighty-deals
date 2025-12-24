// apps/customer_app/lib/core/widgets/loading_view.dart
import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  final String? label;

  const LoadingView({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          if (label != null) ...[
            const SizedBox(height: 10),
            Text(
              label!,
              style: TextStyle(color: Colors.white.withOpacity(0.75)),
            )
          ]
        ],
      ),
    );
  }
}
