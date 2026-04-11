import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RejectReasonsPage extends StatefulWidget {
  const RejectReasonsPage({super.key});

  @override
  State<RejectReasonsPage> createState() => _RejectReasonsPageState();
}

class _RejectReasonsPageState extends State<RejectReasonsPage> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _showReasonEditor({String? docId, String? initialText}) async {
    _controller.text = initialText ?? '';
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null ? 'Add reject reason' : 'Edit reject reason'),
          content: TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Enter reject reason'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = _controller.text.trim();
                if (text.isEmpty) return;
                final collection = FirebaseFirestore.instance.collection('reject_reasons');
                if (docId == null) {
                  await collection.add({
                    'text': text,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                } else {
                  await collection.doc(docId).update({
                    'text': text,
                  });
                }
                if (!mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteReason(String docId) async {
    await FirebaseFirestore.instance.collection('reject_reasons').doc(docId).delete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reject Reasons')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('reject_reasons')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No reject reasons yet.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final text = doc.data()['text'] as String? ?? '';
              return ListTile(
                title: Text(text),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showReasonEditor(docId: doc.id, initialText: text),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteReason(doc.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReasonEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
