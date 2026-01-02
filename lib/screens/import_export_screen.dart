import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/download_helper.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final _controller = TextEditingController();

  bool _busy = false;
  String? _status;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _busy = true;
      _error = null;
      _status = 'Exporting...';
    });

    try {
      final base = FirebaseFirestore.instance.collection('users').doc(uid);

      final gamesSnap = await base.collection('games').get();
      final clientsSnap = await base.collection('clients').get();
      final resultsSnap = await base.collection('results').get();

      final exportJson = <String, dynamic>{
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'games': gamesSnap.docs.map(_docToJson).toList(),
        'clients': clientsSnap.docs.map(_docToJson).toList(),
        'results': resultsSnap.docs.map(_docToJson).toList(),
      };

      final text = const JsonEncoder.withIndent('  ').convert(exportJson);

      setState(() {
        _controller.text = text;
        _status = 'Export complete.';
      });

      if (kIsWeb) {
        final fileName =
            'track_management_export_${DateTime.now().toIso8601String()}.json'
                .replaceAll(':', '-');
        await downloadTextFile(
          filename: fileName,
          content: text,
          mimeType: 'application/json',
        );
        if (mounted) {
          setState(() => _status = 'Export complete. Download started.');
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Map<String, dynamic> _docToJson(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return <String, dynamic>{'id': doc.id, 'data': _encodeFirestore(data)};
  }

  Object? _encodeFirestore(Object? value) {
    if (value is Timestamp) {
      return <String, dynamic>{
        '__type': 'timestamp',
        'millis': value.millisecondsSinceEpoch,
      };
    }

    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _encodeFirestore(v)));
    }

    if (value is List) {
      return value.map(_encodeFirestore).toList();
    }

    return value;
  }

  Object? _decodeFirestore(Object? value) {
    if (value is Map) {
      final m = Map<String, dynamic>.from(value);
      if (m['__type'] == 'timestamp' && m['millis'] is num) {
        final ms = (m['millis'] as num).toInt();
        return Timestamp.fromMillisecondsSinceEpoch(ms);
      }
      return m.map((k, v) => MapEntry(k, _decodeFirestore(v)));
    }

    if (value is List) {
      return value.map(_decodeFirestore).toList();
    }

    return value;
  }

  Future<void> _import() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _busy = true;
      _error = null;
      _status = 'Importing...';
    });

    try {
      final raw = _controller.text.trim();
      if (raw.isEmpty) {
        setState(() => _error = 'Paste JSON to import.');
        return;
      }

      final parsed = jsonDecode(raw);
      if (parsed is! Map) {
        setState(() => _error = 'Invalid JSON root. Expected an object.');
        return;
      }

      final root = Map<String, dynamic>.from(parsed);
      final games = (root['games'] as List?) ?? const [];
      final clients = (root['clients'] as List?) ?? const [];
      final results = (root['results'] as List?) ?? const [];

      final base = FirebaseFirestore.instance.collection('users').doc(uid);

      final writes =
          <({String collection, String id, Map<String, dynamic> data})>[];

      void addWrite(String collection, Map<String, dynamic> item) {
        final id = item['id']?.toString();
        final data = item['data'];
        if (id == null || id.isEmpty || data is! Map) return;
        final decoded = _decodeFirestore(data);
        if (decoded is! Map) return;
        writes.add((
          collection: collection,
          id: id,
          data: Map<String, dynamic>.from(decoded),
        ));
      }

      for (final item in games) {
        if (item is Map) addWrite('games', Map<String, dynamic>.from(item));
      }
      for (final item in clients) {
        if (item is Map) addWrite('clients', Map<String, dynamic>.from(item));
      }
      for (final item in results) {
        if (item is Map) addWrite('results', Map<String, dynamic>.from(item));
      }

      if (writes.isEmpty) {
        setState(() => _error = 'Nothing to import (no valid records found).');
        return;
      }

      const chunkSize = 400;
      var imported = 0;
      for (var i = 0; i < writes.length; i += chunkSize) {
        final end = (i + chunkSize) > writes.length
            ? writes.length
            : (i + chunkSize);
        final batch = FirebaseFirestore.instance.batch();
        for (final w in writes.sublist(i, end)) {
          batch.set(
            base.collection(w.collection).doc(w.id),
            w.data,
            SetOptions(merge: true),
          );
        }
        await batch.commit();
        imported += (end - i);
        if (mounted) {
          setState(() => _status = 'Importing... $imported/${writes.length}');
        }
      }

      setState(() {
        _status = 'Import complete. Imported/updated $imported documents.';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not authenticated'));
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _export,
                icon: const Icon(Icons.download),
                label: const Text('Export JSON'),
              ),
              if (kIsWeb)
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final text = _controller.text.trim();
                          if (text.isEmpty) {
                            setState(
                              () =>
                                  _error = 'Nothing to download. Export first.',
                            );
                            return;
                          }
                          final fileName =
                              'track_management_export_${DateTime.now().toIso8601String()}.json'
                                  .replaceAll(':', '-');
                          await downloadTextFile(
                            filename: fileName,
                            content: text,
                            mimeType: 'application/json',
                          );
                        },
                  icon: const Icon(Icons.file_download),
                  label: const Text('Download file'),
                ),
              FilledButton.icon(
                onPressed: _busy ? null : _import,
                icon: const Icon(Icons.upload),
                label: const Text('Import JSON'),
              ),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () {
                        setState(() {
                          _controller.clear();
                          _status = null;
                          _error = null;
                        });
                      },
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_status != null) ...[
            Text(_status!, style: const TextStyle(color: Colors.green)),
            const SizedBox(height: 8),
          ],
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: TextField(
              controller: _controller,
              expands: true,
              maxLines: null,
              minLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText:
                    'Export will appear here. Or paste JSON here to import.',
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: Import merges by document id. If you export from one account and import to another, IDs will be preserved.',
          ),
        ],
      ),
    );
  }
}
