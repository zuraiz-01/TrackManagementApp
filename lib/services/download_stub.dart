Future<void> downloadTextFile({
  required String filename,
  required String content,
  required String mimeType,
}) async {
  throw UnsupportedError('File download is only supported on Web.');
}
