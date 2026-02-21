import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapIconHelper {
  static BitmapDescriptor? _mototaxiIcon;

  /// Carga el icono de moto taxi personalizado
  static Future<BitmapDescriptor> getMototaxiIcon() async {
    if (_mototaxiIcon != null) {
      return _mototaxiIcon!;
    }

    // Cargar la imagen desde assets
    final ByteData data = await rootBundle.load('assets/icons/mototaxi.png');
    final Uint8List bytes = data.buffer.asUint8List();

    // Decodificar la imagen
    final ui.Codec codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 120, // Tamaño del icono en el mapa
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteData = await frameInfo.image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      // Fallback al icono por defecto si falla
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }

    final Uint8List resizedBytes = byteData.buffer.asUint8List();
    _mototaxiIcon = BitmapDescriptor.fromBytes(resizedBytes);

    return _mototaxiIcon!;
  }

  /// Limpia el cache del icono (útil para hot reload)
  static void clearCache() {
    _mototaxiIcon = null;
  }
}
