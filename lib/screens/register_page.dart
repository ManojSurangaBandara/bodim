import 'package:flutter/material.dart';
import '../services/app_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _loading = false;

  void _register() {
    setState(() => _loading = true);
    final ok = AppState.instance.register(_emailCtl.text.trim(), _passCtl.text);
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pop(); // go back to login/home
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email already registered')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailCtl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
