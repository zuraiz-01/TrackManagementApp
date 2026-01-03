import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/settings_controller.dart';

class ResultsDashboardScreen extends StatefulWidget {
  const ResultsDashboardScreen({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<ResultsDashboardScreen> createState() => _ResultsDashboardScreenState();
}

class _ResultsDashboardScreenState extends State<ResultsDashboardScreen> {
  final Map<int, int> _values = <int, int>{};

  String? _selectedGameId;
  String? _selectedClientId;

  DateTime _selectedDate = DateTime.now();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _resultSub;
  Timer? _persistDebounce;

  int get _jodiTotal {
    final s = widget.controller.settings;
    var sum = 0;
    for (var i = s.jodiStart; i <= s.jodiEnd; i++) {
      sum += _values[i] ?? 0;
    }
    return sum;
  }

  int get _figureTotal {
    final s = widget.controller.settings;
    if (!s.showFigureSection) return 0;
    var sum = 0;
    for (var i = s.figureStart; i <= s.figureEnd; i++) {
      sum += _values[i] ?? 0;
    }
    return sum;
  }

  int get _totalAmount => _jodiTotal + _figureTotal;

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String get _selectedDateKey => _dateKey(_selectedDate);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _selectedDate,
    );
    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
      _values.clear();
    });

    _listenToResultDoc();
  }

  DocumentReference<Map<String, dynamic>>? _resultDocRef() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final gameId = _selectedGameId;
    final clientId = _selectedClientId;
    if (gameId == null || clientId == null) return null;

    final docId =
        '${_selectedDateKey}__'
        '$gameId'
        '__'
        '$clientId';
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('results')
        .doc(docId);
  }

  void _listenToResultDoc() {
    _resultSub?.cancel();
    _resultSub = null;

    final ref = _resultDocRef();
    if (ref == null) {
      return;
    }

    _resultSub = ref.snapshots().listen((snap) {
      final data = snap.data();
      if (data == null || data['values'] is! Map) {
        if (mounted) {
          setState(() {
            _values.clear();
          });
        }
        return;
      }

      final raw = Map<String, dynamic>.from(data['values'] as Map);
      final next = <int, int>{};
      for (final entry in raw.entries) {
        final k = int.tryParse(entry.key);
        final v = entry.value is num ? (entry.value as num).toInt() : null;
        if (k != null && v != null) {
          next[k] = v;
        }
      }

      if (mounted) {
        setState(() {
          _values
            ..clear()
            ..addAll(next);
        });
      }
    });
  }

  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 350), () async {
      final ref = _resultDocRef();
      if (ref == null) return;

      final payload = <String, dynamic>{
        'dateKey': _selectedDateKey,
        'gameId': _selectedGameId,
        'clientId': _selectedClientId,
        'jodiTotal': _jodiTotal,
        'figureTotal': _figureTotal,
        'totalAmount': _totalAmount,
        'values': _values.map((k, v) => MapEntry(k.toString(), v)),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await ref.set(payload, SetOptions(merge: true));
    });
  }

  @override
  void dispose() {
    _persistDebounce?.cancel();
    _resultSub?.cancel();
    super.dispose();
  }

  Future<void> _editValue(int index) async {
    final controller = TextEditingController(
      text: (_values[index] ?? 0).toString(),
    );

    final result = await showDialog<int?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set value for ${index.toString().padLeft(2, '0')}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter amount'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                Navigator.of(context).pop(parsed);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      _values[index] = result;
    });

    _schedulePersist();
  }

  Future<void> _reset() async {
    final ref = _resultDocRef();
    setState(() {
      _values.clear();
      _selectedGameId = null;
      _selectedClientId = null;
    });
    _resultSub?.cancel();
    _resultSub = null;
    if (ref != null) {
      await ref.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.controller.settings;
    final size = MediaQuery.sizeOf(context);
    final columns = size.width >= 900
        ? 10
        : size.width >= 600
        ? 8
        : 6;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [settings.backgroundColor, const Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _dateRow(context),
                  const SizedBox(height: 12),
                  _gridSection(
                    context: context,
                    title: null,
                    columns: columns,
                    start: settings.jodiStart,
                    end: settings.jodiEnd,
                  ),
                  const SizedBox(height: 12),
                  _totalsSection(context),
                  if (settings.showFigureSection) ...[
                    const SizedBox(height: 16),
                    _gridSection(
                      context: context,
                      title: null,
                      columns: columns,
                      start: settings.figureStart,
                      end: settings.figureEnd,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _bottomControls(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateRow(BuildContext context) {
    final settings = widget.controller.settings;
    final base = Theme.of(context).textTheme.titleMedium?.fontSize ?? 16;
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: base * settings.fontScale,
    );

    return Card(
      color: const Color(0xFF0C0D12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: settings.borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: Text('Date: $_selectedDateKey', style: textStyle)),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: settings.borderColor,
              ),
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month),
              label: const Text('Pick'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridSection({
    required BuildContext context,
    required String? title,
    required int columns,
    required int start,
    required int end,
  }) {
    final items = <int>[];
    for (var i = start; i <= end; i++) {
      items.add(i);
    }

    final settings = widget.controller.settings;
    return Card(
      color: const Color(0xFF0C0D12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: settings.borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.05,
              ),
              itemCount: items.length,
              itemBuilder: (context, idx) {
                final n = items[idx];
                final display = n <= 99
                    ? n.toString().padLeft(2, '0')
                    : n.toString();
                final value = _values[n] ?? 0;
                return _Cell(
                  label: display,
                  value: value,
                  borderColor: settings.borderColor,
                  labelColor: settings.labelColor,
                  fontScale: settings.fontScale,
                  onTap: () => _editValue(n),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalsSection(BuildContext context) {
    final settings = widget.controller.settings;
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize:
          (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) *
          settings.fontScale,
    );

    final valueStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: settings.borderColor,
      fontWeight: FontWeight.w700,
      fontSize:
          (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) *
          settings.fontScale,
    );

    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Jodi Total: ', style: textStyle),
              Text('$_jodiTotal', style: valueStyle),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Figure Total: ', style: textStyle),
              Text('$_figureTotal', style: valueStyle),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Total Amount: ', style: textStyle),
              Text('$_totalAmount', style: valueStyle),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _reset(),
              child: const Text('Clear / Reset'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomControls(BuildContext context) {
    final settings = widget.controller.settings;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const SizedBox.shrink();
    }

    final gamesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('games')
        .orderBy('createdAt', descending: true)
        .snapshots();

    final clientsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('clients')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Card(
      color: const Color(0xFF0C0D12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: settings.borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: gamesStream,
          builder: (context, gamesSnap) {
            final gameDocs = gamesSnap.data?.docs ?? const [];
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: clientsStream,
              builder: (context, clientsSnap) {
                final clientDocs = clientsSnap.data?.docs ?? const [];

                final gameItems = gameDocs
                    .map(
                      (d) => DropdownMenuItem<String>(
                        value: d.id,
                        child: Text((d.data()['name'] as String?) ?? d.id),
                      ),
                    )
                    .toList();

                final clientItems = clientDocs
                    .map(
                      (d) => DropdownMenuItem<String>(
                        value: d.id,
                        child: Text((d.data()['name'] as String?) ?? d.id),
                      ),
                    )
                    .toList();

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 200,
                        maxWidth: 260,
                      ),
                      child: DropdownButtonFormField<String>(
                        key: ValueKey<String?>(_selectedGameId),
                        initialValue: _selectedGameId,
                        items: gameItems,
                        onChanged: (v) {
                          setState(() {
                            _selectedGameId = v;
                          });
                          _listenToResultDoc();
                        },
                        decoration: const InputDecoration(labelText: 'Game'),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 200,
                        maxWidth: 260,
                      ),
                      child: DropdownButtonFormField<String>(
                        key: ValueKey<String?>(_selectedClientId),
                        initialValue: _selectedClientId,
                        items: clientItems,
                        onChanged: (v) {
                          setState(() {
                            _selectedClientId = v;
                          });
                          _listenToResultDoc();
                        },
                        decoration: const InputDecoration(labelText: 'Client'),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 140),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: settings.borderColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedGameId = null;
                            _selectedClientId = null;
                            _values.clear();
                          });
                          _resultSub?.cancel();
                          _resultSub = null;
                        },
                        child: const Text('Unselect'),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.value,
    required this.onTap,
    required this.borderColor,
    required this.labelColor,
    required this.fontScale,
  });

  final String label;
  final int value;
  final VoidCallback onTap;
  final Color borderColor;
  final Color labelColor;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final baseLabel = Theme.of(context).textTheme.labelLarge?.fontSize ?? 12;
    final baseValue = Theme.of(context).textTheme.titleMedium?.fontSize ?? 16;

    return Material(
      color: const Color(0xFF0D0E14),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w700,
                  fontSize: baseLabel * fontScale,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  value.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: baseValue * fontScale,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
