import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/room.dart';
import '../services/app_state.dart';

class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final _titleCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _contactCtl = TextEditingController();
  final List<String> _localImagePaths = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked.isEmpty) return;

    final appDir = await getApplicationDocumentsDirectory();
    for (final p in picked) {
      final filename = '${DateTime.now().millisecondsSinceEpoch}-${p.name}';
      final saved = await File(p.path).copy('${appDir.path}/$filename');
      _localImagePaths.add(saved.path);
    }
    setState(() {});
  }

  void _submit() {
    final t = _titleCtl.text.trim();
    final p = _priceCtl.text.trim();
    final c = _contactCtl.text.trim();
    if (t.isEmpty || p.isEmpty || c.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    AppState.instance.addRoom(
      Room(
        title: t,
        price: p,
        contact: c,
        creatorEmail: AppState.instance.currentUser.value!.email,
        images: _localImagePaths.isNotEmpty
            ? List.from(_localImagePaths)
            : null,
        description: _descCtl.text.trim().isEmpty ? null : _descCtl.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _priceCtl.dispose();
    _contactCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleCtl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtl,
              decoration: const InputDecoration(labelText: 'Price (LKR)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactCtl,
              decoration: const InputDecoration(labelText: 'Contact number'),
            ),
            const SizedBox(height: 12),
            if (_localImagePaths.isNotEmpty)
              SizedBox(
                height: 160,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _localImagePaths.length,
                  itemBuilder: (context, i) {
                    final p = _localImagePaths[i];
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Image.file(File(p), fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black45,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 16,
                              color: Colors.white,
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  setState(() => _localImagePaths.removeAt(i)),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Add Images'),
                ),
                const SizedBox(width: 12),
                if (_localImagePaths.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _localImagePaths.clear()),
                    child: const Text('Remove all'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: const Text('Post')),
          ],
        ),
      ),
    );
  }
}
