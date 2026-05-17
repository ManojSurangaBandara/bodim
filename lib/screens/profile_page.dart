import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/localization.dart';
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

  Future<void> _saveProfile(String t(String k)) async {
    final name = _nameCtl.text.trim().isEmpty ? null : _nameCtl.text.trim();
    final phone = _phoneCtl.text.trim().isEmpty ? null : _phoneCtl.text.trim();
    await AppState.instance.updateProfile(name: name, phone: phone);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t('profileUpdated'))));
  }

  Future<void> _changePassword(String t(String k)) async {
    final current = _currentPasswordCtl.text.trim();
    final newP = _newPasswordCtl.text.trim();
    final confirm = _confirmPasswordCtl.text.trim();

    if (current.isEmpty || newP.isEmpty || confirm.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('allFieldsRequired'))));
      return;
    }

    if (newP != confirm) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('passwordsDoNotMatch'))));
      return;
    }

    final ok = await AppState.instance.changePassword(current, newP);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('incorrectPassword'))));
      return;
    }

    _currentPasswordCtl.clear();
    _newPasswordCtl.clear();
    _confirmPasswordCtl.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t('passwordChanged'))));
  }

  @override
  Widget build(BuildContext context) {
    final user = AppState.instance.currentUser.value!;
    return ValueListenableBuilder<String>(
      valueListenable: AppState.instance.languageCode,
      builder: (context, languageCode, __) {
        String t(String key) => AppLocalizations.translate(languageCode, key);

        return Scaffold(
          appBar: AppBar(
            title: Text(t('profile')),
            elevation: 0,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.background.withOpacity(0.0),
            surfaceTintColor: Theme.of(
              context,
            ).colorScheme.background.withOpacity(0.0),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.06),
                  Theme.of(context).colorScheme.background,
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: Text(
                                user.email.isNotEmpty
                                    ? user.email[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              user.email,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              user.name ?? t('noNameSet'),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            t('accountDetails'),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameCtl,
                            decoration: InputDecoration(
                              labelText: t('name'),
                              prefixIcon: const Icon(Icons.person),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneCtl,
                            decoration: InputDecoration(
                              labelText: t('phone'),
                              prefixIcon: const Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: PressableScale(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () => _saveProfile(t),
                                child: Text(
                                  t('saveProfile'),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Divider(),
                          const SizedBox(height: 20),
                          Text(
                            t('security'),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _currentPasswordCtl,
                            decoration: InputDecoration(
                              labelText: t('currentPassword'),
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _newPasswordCtl,
                            decoration: InputDecoration(
                              labelText: t('newPassword'),
                              prefixIcon: const Icon(Icons.lock),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPasswordCtl,
                            decoration: InputDecoration(
                              labelText: t('confirmNewPassword'),
                              prefixIcon: const Icon(Icons.lock),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: PressableScale(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () => _changePassword(t),
                                child: Text(
                                  t('changePassword'),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
