import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

class MapAttribution extends StatelessWidget {
  const MapAttribution({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => SimpleAttributionWidget(
      source: const Text("OpenStreetMap contributors"),
      backgroundColor: Colors.black.withOpacity(0.5),
      onTap: () async {
        const osmLink = "https://www.openstreetmap.org/copyright";
        final osmUri = Uri.parse(osmLink);

        if (await canLaunchUrl(osmUri)) {
          await launchUrl(osmUri, mode: LaunchMode.externalApplication);
          return;
        }

        await Clipboard.setData(const ClipboardData(text: osmLink));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(
              "Couldn't open browser! Copied link to clipboard.",
            )));
      }},
  );

}
