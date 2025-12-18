import 'package:firebase_remote_config/firebase_remote_config.dart';

class AppConfig {
  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._();
  AppConfig._();

  late FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  // Default values (fallback only)
  static const String _defaultImageKitEndpoint = "https://upload.imagekit.io/api/v1/files/upload";
  
  // Products ImageKit defaults
  static const String _defaultProductsPublicKey = "";
  static const String _defaultProductsPrivateKey = "";
  static const String _defaultProductsEndpoint = "https://upload.imagekit.io/api/v1/files/upload";
  
  // Ads ImageKit defaults
  static const String _defaultAdsPublicKey = "";
  static const String _defaultAdsPrivateKey = "";
  static const String _defaultAdsEndpoint = "https://upload.imagekit.io/api/v1/files/upload";

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // Set config settings
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Set default values
      await _remoteConfig.setDefaults({
        // Products ImageKit config
        'products_imagekit_endpoint': _defaultProductsEndpoint,
        'products_imagekit_public_key': _defaultProductsPublicKey,
        'products_imagekit_private_key': _defaultProductsPrivateKey,
        
        // Ads ImageKit config
        'ads_imagekit_endpoint': _defaultAdsEndpoint,
        'ads_imagekit_public_key': _defaultAdsPublicKey,
        'ads_imagekit_private_key': _defaultAdsPrivateKey,
        
        // Legacy support (will be removed later)
        'imagekit_endpoint': _defaultImageKitEndpoint,
        'imagekit_public_key': _defaultProductsPublicKey,
        'imagekit_private_key': _defaultProductsPrivateKey,
      });

      // Fetch and activate
      await _remoteConfig.fetchAndActivate();
      _initialized = true;
      
      // Firebase Remote Config initialized successfully
    } catch (e) {
      // Error initializing Firebase Remote Config: $e
      // Continue with default values
      _initialized = true;
    }
  }

  // Products ImageKit configuration
  String get productsImageKitEndpoint {
    if (!_initialized) {
      // AppConfig not initialized, using default products endpoint
      return _defaultProductsEndpoint;
    }
    return _remoteConfig.getString('products_imagekit_endpoint');
  }

  String get productsImageKitPublicKey {
    if (!_initialized) {
      // AppConfig not initialized, using default products public key
      return _defaultProductsPublicKey;
    }
    return _remoteConfig.getString('products_imagekit_public_key');
  }

  String get productsImageKitPrivateKey {
    if (!_initialized) {
      // AppConfig not initialized, using default products private key
      return _defaultProductsPrivateKey;
    }
    return _remoteConfig.getString('products_imagekit_private_key');
  }

  // Ads ImageKit configuration  
  String get adsImageKitEndpoint {
    if (!_initialized) {
      // AppConfig not initialized, using default ads endpoint
      return _defaultAdsEndpoint;
    }
    return _remoteConfig.getString('ads_imagekit_endpoint');
  }

  String get adsImageKitPublicKey {
    if (!_initialized) {
      // AppConfig not initialized, using default ads public key
      return _defaultAdsPublicKey;
    }
    return _remoteConfig.getString('ads_imagekit_public_key');
  }

  String get adsImageKitPrivateKey {
    if (!_initialized) {
      // AppConfig not initialized, using default ads private key
      return _defaultAdsPrivateKey;
    }
    return _remoteConfig.getString('ads_imagekit_private_key');
  }

  // Legacy methods (for backward compatibility)
  String get imageKitEndpoint => productsImageKitEndpoint;
  String get imageKitPublicKey => productsImageKitPublicKey;
  String get imageKitPrivateKey => productsImageKitPrivateKey;

  // Refresh config manually if needed
  Future<void> refresh() async {
    if (!_initialized) return;
    
    try {
      await _remoteConfig.fetchAndActivate();
      // Remote config refreshed
    } catch (e) {
      // Error refreshing remote config: $e
    }
  }
}
