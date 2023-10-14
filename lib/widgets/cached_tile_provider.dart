import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';

class CachedTileProvider extends TileProvider {

  @override
  ImageProvider<Object> getImage(TileCoordinates coordinates, TileLayer options) =>
      CachedNetworkImageProvider(
        getTileUrl(coordinates, options),
        // im not sure if it respects the cache-control headers
        // let's hope it does
        headers: headers,
      );

}
