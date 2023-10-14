import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stasi/util/api_client.dart';
import 'package:stasi/widgets/live_view_map.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


class VehicleTime {
  VehicleTime(
    this.vehiclePosition,
    this.added,
  );

  final VehiclePosition vehiclePosition;
  final DateTime added;
}


class LiveView extends StatefulWidget {
  const LiveView({super.key});

  @override
  State<StatefulWidget> createState() => _LiveViewState();

}

class _LiveViewState extends State<StatefulWidget> {
  late WebSocketChannel channel;

  @override
  void initState() {
    super.initState();

    channel = WebSocketChannel.connect(Uri(
      scheme: "wss",
      host: "socket.tlm.solutions",
    ));
    channel.sink.add('{"regions": [0]}');
  }

  @override
  void dispose() {
    channel.sink.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: LizardApiClient.getVehiclesPostionsInitial(0),
        builder: (context, AsyncSnapshot<List<VehiclePosition>> snapshot) {
          if (snapshot.hasError) {
            throw snapshot.error!;
          }
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }

          final vehicleList = snapshot.data!.map(
                (vehicle) => VehicleTime(vehicle, DateTime.now()),
          ).toList();

          return StreamBuilder(
              stream: channel.stream,
              builder: (context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.hasData) {
                  final updatedVehicle = VehiclePosition.fromMap(jsonDecode(snapshot.data! as String));
                  vehicleList.removeWhere(
                        (element) => updatedVehicle == element.vehiclePosition
                            || element.added.difference(DateTime.now()).inMinutes >= 3,
                  );
                  vehicleList.add(VehicleTime(updatedVehicle, DateTime.now()));
                }
                return LiveViewMap(vehicleList: vehicleList.map((e) => e.vehiclePosition).toList());
              }
          );
        }
    );
  }

}
