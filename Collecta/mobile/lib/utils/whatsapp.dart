import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens WhatsApp with the given text pre-filled. Tries the app scheme first,
/// then falls back to the universal wa.me web link. Returns false if neither
/// could be launched.
Future<bool> shareToWhatsApp(String text) async {
  final encoded = Uri.encodeComponent(text);
  final candidates = <Uri>[
    Uri.parse('whatsapp://send?text=$encoded'),
    Uri.parse('https://wa.me/?text=$encoded'),
    Uri.parse('https://api.whatsapp.com/send?text=$encoded'),
  ];
  for (final uri in candidates) {
    try {
      if (await canLaunchUrl(uri)) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return true;
      }
    } catch (_) {
      // try next candidate
    }
  }
  return false;
}

Future<void> copyToClipboard(String text) =>
    Clipboard.setData(ClipboardData(text: text));
