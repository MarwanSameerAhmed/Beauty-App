/// على الويب لا يوجد dart:io File
/// نرجع null لأن الويب يستخدم bytes مباشرة
dynamic createPlatformFile(String path) {
  return null;
}
