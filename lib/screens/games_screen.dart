import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  CollectionReference<Map<String, dynamic>> _gamesRef(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('games');
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not authenticated'));
    }

    final gamesRef = _gamesRef(uid);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _openUpsertDialog(context: context, gamesRef: gamesRef),
        icon: const Icon(Icons.add),
        label: const Text('Add Game'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: gamesRef.orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No games yet. Tap Add Game.'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1100
                  ? 4
                  : width >= 850
                  ? 3
                  : width >= 600
                  ? 2
                  : 1;

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final name = (data['name'] as String?) ?? '';
                  final date = (data['date'] as Timestamp?)?.toDate();
                  final amount = (data['amount'] as num?)?.toDouble();

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Edit',
                                onPressed: () => _openUpsertDialog(
                                  context: context,
                                  gamesRef: gamesRef,
                                  docId: doc.id,
                                  initialName: name,
                                  initialDate: date,
                                  initialAmount: amount,
                                ),
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: () => _confirmDelete(
                                  context: context,
                                  onDelete: () => gamesRef.doc(doc.id).delete(),
                                ),
                                icon: const Icon(Icons.delete),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            date == null
                                ? 'Date: -'
                                : 'Date: ${_formatDate(date)}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            amount == null
                                ? 'Amount: -'
                                : 'Amount: ${amount.toStringAsFixed(0)}',
                          ),
                          const Spacer(),
                          Text(
                            'ID: ${doc.id}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.white54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static Future<void> _confirmDelete({
    required BuildContext context,
    required Future<void> Function() onDelete,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete?'),
          content: const Text('This will permanently delete the record.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await onDelete();
    }
  }

  static Future<void> _openUpsertDialog({
    required BuildContext context,
    required CollectionReference<Map<String, dynamic>> gamesRef,
    String? docId,
    String? initialName,
    DateTime? initialDate,
    double? initialAmount,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: initialName ?? '');
    final amountController = TextEditingController(
      text: initialAmount == null ? '' : initialAmount.toStringAsFixed(0),
    );

    var selectedDate = initialDate ?? DateTime.now();
    var hasDate = initialDate != null;
    String? error;
    var isBusy = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setState(() {
                isBusy = true;
                error = null;
              });

              try {
                final amount = amountController.text.trim().isEmpty
                    ? null
                    : double.tryParse(amountController.text.trim());

                final payload = <String, dynamic>{
                  'name': nameController.text.trim(),
                  'date': hasDate ? Timestamp.fromDate(selectedDate) : null,
                  'amount': amount,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                if (docId == null) {
                  payload['createdAt'] = FieldValue.serverTimestamp();
                  await gamesRef.add(payload);
                } else {
                  await gamesRef
                      .doc(docId)
                      .set(payload, SetOptions(merge: true));
                }

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                setState(() => error = e.toString());
              } finally {
                setState(() => isBusy = false);
              }
            }

            return AlertDialog(
              title: Text(docId == null ? 'Add Game' : 'Edit Game'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Game name',
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) {
                            return 'Game name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              hasDate
                                  ? 'Date: ${_formatDate(selectedDate)}'
                                  : 'Date: -',
                            ),
                          ),
                          TextButton(
                            onPressed: isBusy
                                ? null
                                : () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                      initialDate: selectedDate,
                                    );
                                    if (picked == null) return;
                                    setState(() {
                                      selectedDate = picked;
                                      hasDate = true;
                                    });
                                  },
                            child: const Text('Pick'),
                          ),
                          TextButton(
                            onPressed: isBusy
                                ? null
                                : () => setState(() {
                                    hasDate = false;
                                  }),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount (optional)',
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isBusy ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isBusy ? null : submit,
                  child: isBusy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
