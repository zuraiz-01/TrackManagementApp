import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  CollectionReference<Map<String, dynamic>> _clientsRef(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('clients');
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not authenticated'));
    }

    final clientsRef = _clientsRef(uid);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _openUpsertDialog(context: context, clientsRef: clientsRef),
        icon: const Icon(Icons.add),
        label: const Text('Add Client'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: clientsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No clients yet. Tap Add Client.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final name = (data['name'] as String?) ?? '';
              final contact = (data['contact'] as String?) ?? '';
              final commission = (data['commission'] as num?)?.toDouble();

              return Card(
                child: ListTile(
                  title: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (contact.isNotEmpty) Text('Contact: $contact'),
                      Text(
                        commission == null
                            ? 'Commission: -'
                            : 'Commission: ${commission.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _openUpsertDialog(
                          context: context,
                          clientsRef: clientsRef,
                          docId: doc.id,
                          initialName: name,
                          initialContact: contact,
                          initialCommission: commission,
                        ),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(
                          context: context,
                          onDelete: () => clientsRef.doc(doc.id).delete(),
                        ),
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
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
    required CollectionReference<Map<String, dynamic>> clientsRef,
    String? docId,
    String? initialName,
    String? initialContact,
    double? initialCommission,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: initialName ?? '');
    final contactController = TextEditingController(text: initialContact ?? '');
    final commissionController = TextEditingController(
      text: initialCommission == null ? '' : initialCommission.toString(),
    );

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
                final commission = commissionController.text.trim().isEmpty
                    ? null
                    : double.tryParse(commissionController.text.trim());

                final payload = <String, dynamic>{
                  'name': nameController.text.trim(),
                  'contact': contactController.text.trim(),
                  'commission': commission,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                if (docId == null) {
                  payload['createdAt'] = FieldValue.serverTimestamp();
                  await clientsRef.add(payload);
                } else {
                  await clientsRef
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
              title: Text(docId == null ? 'Add Client' : 'Edit Client'),
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
                          labelText: 'Client name',
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) {
                            return 'Client name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contactController,
                        decoration: const InputDecoration(
                          labelText: 'Contact (optional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: commissionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Commission (optional)',
                          hintText: 'e.g. 0.05',
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
