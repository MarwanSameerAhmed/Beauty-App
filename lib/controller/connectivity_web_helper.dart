/// فحص DNS lookup على الويب - غير مدعوم، نرجع true دائماً
/// لأن connectivity_plus كافي على الويب
Future<bool> platformDnsLookup(String host, int timeoutSeconds) async {
  // على الويب لا يوجد InternetAddress، نعتمد على connectivity_plus فقط
  return true;
}
