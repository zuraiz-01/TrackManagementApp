import 'download_stub.dart' if (dart.library.html) 'download_web.dart' as impl;

Future<void> downloadTextFile({
  required String filename,
  required String content,
  required String mimeType,
}) {
  return impl.downloadTextFile(
    filename: filename,
    content: content,
    mimeType: mimeType,
  );
}
