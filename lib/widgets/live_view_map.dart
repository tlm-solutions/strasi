import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:stasi/util/api_client.dart';
import 'package:stasi/widgets/map_attribution.dart';

import 'cached_tile_provider.dart';


class _VehicleType {
  _VehicleType(this.type, this.name);
  
  final String type;
  final String name;
}

class _TypeMappingContainer {
  static Map<int, _VehicleType>? _typeMapping;

  static Future<Map<int, _VehicleType>> getTypeMapping() async {
    if (_typeMapping == null) {
      final Map<String, dynamic> jsonData = jsonDecode(await rootBundle.loadString("assets/0.json"));
      final Map<int, _VehicleType> parsedData = jsonData
          .map((key, value) => MapEntry(int.parse(key), _VehicleType(value["type"] as String, value["name"] as String)));

      _typeMapping = parsedData;
    }

    return _typeMapping!;
  }

}


class LiveViewMap extends StatefulWidget {
  const LiveViewMap({
    super.key,
    required this.vehicleList,
  });

  final List<VehiclePosition> vehicleList;

  @override
  State<StatefulWidget> createState() => _LiveViewMapState();
}


final _busEarly = SvgPicture.asset("assets/bus00.svg");
final _busOnTime = SvgPicture.asset("assets/bus07.svg");
final _busLate = SvgPicture.asset("assets/bus10.svg");
final _busVeryLate = SvgPicture.asset("assets/bus14.svg");
final _tramEarly = SvgPicture.asset("assets/tram00.svg");
final _tramOnTime = SvgPicture.asset("assets/tram07.svg");
final _tramLate = SvgPicture.asset("assets/tram10.svg");
final _tramVeryLate = SvgPicture.asset("assets/tram14.svg");
final _unknown = SvgPicture.asset("assets/unknown.svg");


Future<SvgPicture> _getImageFromTypeAndDelay(VehiclePosition vehicle) async {
  final typeMapping = await _TypeMappingContainer.getTypeMapping();
  final vehicleType = typeMapping[vehicle.line];
  if (vehicleType == null) return _unknown;

  if (vehicleType.type == "tram") {
    if (vehicle.delayed == null || vehicle.delayed! == 0) {
      return _tramOnTime;
    } else if (vehicle.delayed! < 0) {
      return _tramEarly;
    } else if (vehicle.delayed! > 0 && vehicle.delayed! < 7 * 60) {
      return _tramLate;
    } else {
      return _tramVeryLate;
    }
  }

  if (vehicleType.type == "bus") {
    if (vehicle.delayed == null || vehicle.delayed! == 0) {
      return _busOnTime;
    } else if (vehicle.delayed! < 0) {
      return _busEarly;
    } else if (vehicle.delayed! > 0 && vehicle.delayed! < 7 * 60) {
      return _busLate;
    } else {
      return _busVeryLate;
    }
  }

  return _unknown;
}

class _VehicleImageName {
  _VehicleImageName(this.name, this.image);

  final String name;
  final SvgPicture image;

  static Future<_VehicleImageName> fromVehiclePosition(VehiclePosition vehicle) async {
    final image = await _getImageFromTypeAndDelay(vehicle);
    final typeMapping = await _TypeMappingContainer.getTypeMapping();
    final vehicleType = typeMapping[vehicle.line];

    var vehicleName = "${vehicle.line}";
    if (vehicleType != null) {
      vehicleName = vehicleType.name;
    }

    return _VehicleImageName(vehicleName, image);
  }
}


class _LiveViewMapState extends State<LiveViewMap> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate
        ),
        initialCenter: LatLng(51.0489, 13.7456),
        initialZoom: 13.0,
        backgroundColor: Colors.black45,
      ),
      mapController: _mapController,
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: "solutions.tlm.stasi",
          tileProvider: CachedTileProvider(),
          tileBuilder: darkModeTileBuilder,
        ),
        MarkerLayer(
          markers: [
            for (final vehiclePosition in widget.vehicleList)
              Marker(
                point: LatLng(vehiclePosition.latitude, vehiclePosition.longitude),
                child: FutureBuilder(
                  future: _VehicleImageName.fromVehiclePosition(vehiclePosition),
                  builder: (context, AsyncSnapshot<_VehicleImageName> snapshot) {
                    if (snapshot.hasError) throw snapshot.error!;
                    if (!snapshot.hasData) return const Offstage();

                    final vehicleImageName = snapshot.data!;

                    return Stack(
                      children: [
                        vehicleImageName.image,
                        Center(
                          child: Text(
                            vehicleImageName.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black),
                          ),
                        )
                      ],
                    );
                  },
                )
              ),
          ],
        ),
        const MapAttribution(),
      ],
    );
  }
}
