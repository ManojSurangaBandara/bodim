import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../models/user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _currentPasswordCtl = TextEditingController();
  final _newPasswordCtl = TextEditingController();
  final _confirmPasswordCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = AppState.instance.currentUser.value!;
    _nameCtl.text = user.name ?? '';
    _phoneCtl.text = user.phone ?? '';
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _currentPasswordCtl.dispose();
    _newPasswordCtl.dispose();
    _confirmPasswordCtl.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final user = AppState.instance.currentUser.value!;
    user.name = _nameCtl.text.trim().isEmpty ? null : _nameCtl.text.trim();
    user.phone = _phoneCtl.text.trim().isEmpty ? null : _phoneCtl.text.trim();
    user.save(); // save to Hive
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  void _changePassword() {
    final current = _currentPasswordCtl.text.trim();
    final newP = _newPasswordCtl.text.trim();
    final confirm = _confirmPasswordCtl.text.trim();

    if (current.isEmpty || newP.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields required')));
      return;
    }

    final user = AppState.instance.currentUser.value!;
    if (user.password != current) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current password incorrect')),
      );
      return;
    }

    if (newP != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    user.password = newP;
    user.save();
    _currentPasswordCtl.clear();
    _newPasswordCtl.clear();
    _confirmPasswordCtl.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Password changed')));
  }

  @override
  Widget build(BuildContext context) {
    final user = AppState.instance.currentUser.value!;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Email: ${user.email}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtl,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Profile'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Change Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _currentPasswordCtl,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordCtl,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordCtl,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changePassword,
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}
