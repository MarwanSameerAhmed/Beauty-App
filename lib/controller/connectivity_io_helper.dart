import 'dart:io';

/// فحص DNS lookup على الموبايل فقط (dart:io متاح)
Future<bool> platformDnsLookup(String host, int timeoutSeconds) async {
  try {
    final result = await InternetAddress.lookup(host)
        .timeout(Duration(seconds: timeoutSeconds));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    return false;
  } catch (_) {
    return false;
  }
}
