import 'dart:convert';

import 'package:http/http.dart' as http;

const googleMapsApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: '',
);

class GoogleMapsAddressService {
  const GoogleMapsAddressService();

  bool get isConfigured => googleMapsApiKey.trim().isNotEmpty;

  Future<List<GooglePlaceSuggestion>> autocomplete(String query) async {
    _ensureConfigured();
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': trimmed,
      'key': googleMapsApiKey,
      'language': 'id',
      'components': 'country:id',
    });

    final response = await http.get(uri);
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    _ensureGoogleOk(payload);

    final predictions = payload['predictions'] is List
        ? payload['predictions'] as List
        : const [];

    return predictions
        .map<GooglePlaceSuggestion?>((item) {
          final row = item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item as Map);
          final placeId = (row['place_id'] ?? '').toString();
          final description = (row['description'] ?? '').toString();
          if (placeId.isEmpty || description.isEmpty) return null;
          return GooglePlaceSuggestion(
            placeId: placeId,
            description: description,
            mainText: _extractText(row['structured_formatting'], 'main_text') ?? description,
            secondaryText: _extractText(row['structured_formatting'], 'secondary_text'),
          );
        })
        .whereType<GooglePlaceSuggestion>()
        .toList(growable: false);
  }

  Future<GoogleAddressDetails> getPlaceDetails(String placeId) async {
    _ensureConfigured();
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId,
      'key': googleMapsApiKey,
      'language': 'id',
      'fields':
          'formatted_address,geometry,address_component,name,place_id',
    });

    final response = await http.get(uri);
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    _ensureGoogleOk(payload);

    final result = payload['result'] is Map<String, dynamic>
        ? payload['result'] as Map<String, dynamic>
        : Map<String, dynamic>.from(payload['result'] as Map);

    return _detailsFromMap(result);
  }

  Future<GoogleAddressDetails> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    _ensureConfigured();
    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '$latitude,$longitude',
      'key': googleMapsApiKey,
      'language': 'id',
    });

    final response = await http.get(uri);
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    _ensureGoogleOk(payload);

    final results = payload['results'] is List ? payload['results'] as List : const [];
    if (results.isEmpty) {
      throw const GoogleMapsAddressException('Alamat tidak ditemukan dari titik peta.');
    }

    final first = results.first is Map<String, dynamic>
        ? results.first as Map<String, dynamic>
        : Map<String, dynamic>.from(results.first as Map);

    return _detailsFromMap(
      {
        'place_id': first['place_id'],
        'formatted_address': first['formatted_address'],
        'address_components': first['address_components'],
        'geometry': {
          'location': {
            'lat': latitude,
            'lng': longitude,
          },
        },
      },
    );
  }

  GoogleAddressDetails _detailsFromMap(Map<String, dynamic> result) {
    final geometry = result['geometry'] is Map<String, dynamic>
        ? result['geometry'] as Map<String, dynamic>
        : Map<String, dynamic>.from(result['geometry'] as Map);
    final location = geometry['location'] is Map<String, dynamic>
        ? geometry['location'] as Map<String, dynamic>
        : Map<String, dynamic>.from(geometry['location'] as Map);

    final components = result['address_components'] is List
        ? (result['address_components'] as List)
            .map((item) => item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item as Map))
            .toList(growable: false)
        : const <Map<String, dynamic>>[];

    String? fromComponent(List<String> types) {
      for (final component in components) {
        final componentTypes = component['types'] is List
            ? (component['types'] as List).map((item) => item.toString()).toSet()
            : <String>{};
        if (types.any(componentTypes.contains)) {
          return (component['long_name'] ?? '').toString();
        }
      }
      return null;
    }

    return GoogleAddressDetails(
      placeId: (result['place_id'] ?? '').toString(),
      formattedAddress: (result['formatted_address'] ?? '').toString(),
      latitude: (location['lat'] as num?)?.toDouble() ?? 0,
      longitude: (location['lng'] as num?)?.toDouble() ?? 0,
      province: fromComponent(const ['administrative_area_level_1']) ?? '',
      city: fromComponent(const ['administrative_area_level_2', 'locality']) ?? '',
      district: fromComponent(const ['administrative_area_level_3', 'sublocality_level_1']) ?? '',
      postalCode: fromComponent(const ['postal_code']) ?? '',
    );
  }

  String? _extractText(Object? value, String key) {
    if (value is! Map<String, dynamic>) return null;
    final field = (value[key] ?? '').toString().trim();
    return field.isEmpty ? null : field;
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw const GoogleMapsAddressException(
        'GOOGLE_MAPS_API_KEY belum diisi. Tambahkan API key Google Maps terlebih dahulu.',
      );
    }
  }

  void _ensureGoogleOk(Map<String, dynamic> payload) {
    final status = (payload['status'] ?? '').toString();
    if (status == 'OK' || status == 'ZERO_RESULTS') return;
    final errorMessage = (payload['error_message'] ?? '').toString().trim();
    throw GoogleMapsAddressException(
      errorMessage.isEmpty ? 'Google Maps API mengembalikan status $status.' : errorMessage,
    );
  }
}

class GooglePlaceSuggestion {
  const GooglePlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    this.secondaryText,
  });

  final String placeId;
  final String description;
  final String mainText;
  final String? secondaryText;
}

class GoogleAddressDetails {
  const GoogleAddressDetails({
    required this.placeId,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.province,
    required this.city,
    required this.district,
    required this.postalCode,
  });

  final String placeId;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String province;
  final String city;
  final String district;
  final String postalCode;
}

class GoogleMapsAddressException implements Exception {
  const GoogleMapsAddressException(this.message);

  final String message;

  @override
  String toString() => message;
}
