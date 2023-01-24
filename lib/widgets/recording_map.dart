import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';


class RecordingMap extends StatefulWidget {
  const RecordingMap({
    Key? key,
    required this.pointList,
  }) : super(key: key);

  final List<LatLng> pointList;

  @override
  State<RecordingMap> createState() => _RecordingMapState();
}

class _RecordingMapState extends State<RecordingMap> {
  late MapController _mapController;
  bool _shouldApplyBounds = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(RecordingMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // yeah this won't get triggered when the orientation changes.
    // too bad...
    if (_shouldApplyBounds && oldWidget.pointList != widget.pointList) {
      _updateBounds();
    }
  }

  void _updateBounds() {
    _mapController.fitBounds(
      _getBoundsFromPoints(widget.pointList),
      options: const FitBoundsOptions(padding: EdgeInsets.all(80.0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            bounds: _getBoundsFromPoints(widget.pointList),
            boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(80.0)),
          ),
          nonRotatedChildren: const [_MapAttribution()],
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: const ["a", "b", "c"],
              userAgentPackageName: "solutions.tlm.stasi",
              tileBuilder: darkModeTileBuilder,
              backgroundColor: Colors.black54,
            ),
            PolylineLayer(
              polylines: [Polyline(
                points: widget.pointList,
                strokeWidth: 10,
              )],
            ),
          ],
        ),
        Positioned(
          top: 3,
          right: 3,
          child: ToggleButtons(
            isSelected: [_shouldApplyBounds, false],
            color: Colors.white,
            onPressed: (index) {
              switch (index) {
                case 0:  // lock
                  setState(() {
                    _shouldApplyBounds = !_shouldApplyBounds;
                  });

                  if (_shouldApplyBounds) _updateBounds();
                  break;

                case 1:  // center
                  _updateBounds();
                  break;
              }
            },
            children: const [
              Icon(Icons.lock),
              Icon(Icons.center_focus_strong),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => AttributionWidget(
    attributionBuilder: (context) => ColoredBox(
      color: Colors.black.withOpacity(0.5),
      child: GestureDetector(
        onTap: () async {
          /*
           * This is bad practice.
           * We will have to change this with the next stable release of flutter
           * to "if(context.mounted)".
           * https://github.com/flutter/flutter/issues/110694
           */
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          const osmLink = "https://www.openstreetmap.org/copyright";

          final osmUri = Uri.parse(osmLink);
          if (await canLaunchUrl(osmUri)) {
            await launchUrl(osmUri, mode: LaunchMode.externalApplication);
            return;
          }
          await Clipboard.setData(const ClipboardData(text: osmLink));

          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text(
              "Couldn't open browser! Copied link to clipboard.",
            )),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text("flutter_map | © "),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  "OpenStreetMap",
                  style: TextStyle(
                    color: Color(0xFF0000EE),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(" contributors"),
            ],
          ),
        ),
      ),
    ),
  );
}

LatLngBounds _getBoundsFromPoints(List<LatLng> points) {
  final bounds = LatLngBounds.fromPoints(points);

  /*
    When all the points are the same the southWest and northEast
    become the same too. This leads to an error in flutter map.
    (Unsupported operation: Infinity or NaN toInt)
    This normally only happens during debugging.
  */

  if (bounds.southWest!.latitude == bounds.northEast!.latitude) {
    bounds.southWest!.latitude += 0.0005;
    bounds.northEast!.latitude -= 0.0005;
  }

  if (bounds.southWest!.longitude == bounds.northEast!.longitude) {
    bounds.southWest!.longitude -= 0.0005;
    bounds.northEast!.longitude += 0.0005;
  }

  return bounds;
}
