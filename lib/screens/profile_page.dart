import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../widgets/pressable_scale.dart';

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

  Future<void> _saveProfile() async {
    final name = _nameCtl.text.trim().isEmpty ? null : _nameCtl.text.trim();
    final phone = _phoneCtl.text.trim().isEmpty ? null : _phoneCtl.text.trim();
    await AppState.instance.updateProfile(name: name, phone: phone);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordCtl.text.trim();
    final newP = _newPasswordCtl.text.trim();
    final confirm = _confirmPasswordCtl.text.trim();

    if (current.isEmpty || newP.isEmpty || confirm.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields required')));
      return;
    }

    if (newP != confirm) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    final ok = await AppState.instance.changePassword(current, newP);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current password incorrect or cannot update')),
      );
      return;
    }

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            CircleAvatar(
              radius: 36,
              child: Text(user.email.substring(0, 1).toUpperCase()),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: AppState.instance.themeMode,
              builder: (context, mode, _) {
                final safeMode = mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
                return DropdownButtonFormField<ThemeMode>(
                  value: safeMode,
                  decoration: const InputDecoration(labelText: 'Theme'),
                  items: const [
                    DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                  ],
                  onChanged: (m) {
                    if (m != null) AppState.instance.setThemeMode(m);
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: PressableScale(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save Profile'),
                ),
              ),
            ),
            const SizedBox(height: 32),
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
            SizedBox(
              width: double.infinity,
              child: PressableScale(
                child: ElevatedButton(
                  onPressed: _changePassword,
                  child: const Text('Change Password'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
