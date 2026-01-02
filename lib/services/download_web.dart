import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<void> downloadTextFile({
  required String filename,
  required String content,
  required String mimeType,
}) async {
  final parts = <JSAny>[content.toJS].toJS;
  final blob = web.Blob(parts, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
