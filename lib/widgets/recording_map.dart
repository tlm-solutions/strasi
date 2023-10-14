import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'cached_tile_provider.dart';
import 'map_attribution.dart';


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
    _mapController.fitCamera(CameraFit.bounds(
      bounds: _getBoundsFromPoints(widget.pointList),
      padding: const EdgeInsets.all(80.0),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate
            ),
            initialCameraFit: CameraFit.bounds(
              bounds: _getBoundsFromPoints(widget.pointList),
              padding: const EdgeInsets.all(80.0),
            ),
            backgroundColor: Colors.black54,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: "solutions.tlm.stasi",
              tileProvider: CachedTileProvider(),
              tileBuilder: darkModeTileBuilder,
            ),
            PolylineLayer(
              polylines: [Polyline(
                points: widget.pointList,
                strokeWidth: 10,
              )],
            ),
            const MapAttribution(),
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


LatLngBounds _getBoundsFromPoints(List<LatLng> points) {
  var bounds = LatLngBounds.fromPoints(points);

  /*
    When all the points are the same the southWest and northEast
    become the same too. This leads to an error in flutter map.
    (Unsupported operation: Infinity or NaN toInt)
    This normally only happens during debugging.
  */

  if (bounds.southWest.latitude == bounds.northEast.latitude) {
    bounds = LatLngBounds(
      LatLng(bounds.southWest.latitude + 0.0005, bounds.southWest.longitude),
      LatLng(bounds.northEast.latitude - 0.0005, bounds.northEast.longitude),
    );
  }

  if (bounds.southWest.longitude == bounds.northEast.longitude) {
    bounds = LatLngBounds(
      LatLng(bounds.southWest.latitude, bounds.southWest.longitude - 0.0005),
      LatLng(bounds.northEast.latitude, bounds.northEast.longitude + 0.005),
    );
  }

  return bounds;
}
