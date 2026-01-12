import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportLauncher {
  static const String supportUrl = 'https://mighty-deal-support.netlify.app/';

  static Future<void> open(BuildContext context) async {
    final uri = Uri.parse(supportUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open support page.')),
      );
    }
  }
}
