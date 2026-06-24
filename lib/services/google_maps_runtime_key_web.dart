import 'dart:js_interop';

@JS('googleMapsApiKey')
external JSString? get _runtimeGoogleMapsApiKey;

String get runtimeGoogleMapsApiKey => _runtimeGoogleMapsApiKey?.toDart ?? '';
