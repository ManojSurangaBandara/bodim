import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_state.dart';
import '../services/localization.dart';
import '../theme.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: 'info@bodim.lk');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) _copyToClipboard(context, 'info@bodim.lk');
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: '+94773604108');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) _copyToClipboard(context, '0773604108');
    }
  }

  Future<void> _launchSms(BuildContext context) async {
    final uri = Uri(scheme: 'sms', path: '+94773604108');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) _copyToClipboard(context, '0773604108');
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$text copied'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.instance.languageCode,
      builder: (context, languageCode, __) {
        String t(String key) =>
            AppLocalizations.translate(languageCode, key);
        final grad = Theme.of(context).extension<AppGradients>()!;
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: Text(t('contactUs')),
            backgroundColor: grad.barBackground,
            foregroundColor: Colors.white,
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.primary.withOpacity(0.06),
                  scheme.background,
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      // logo / icon
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(
                          Icons.home_work,
                          size: 48,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'බෝඩිම්.lk',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: scheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t('contactUsSubtitle'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email card
                      _ContactCard(
                        icon: Icons.email_outlined,
                        label: t('emailUs'),
                        value: 'info@bodim.lk',
                        actions: [
                          _ContactAction(
                            icon: Icons.open_in_new,
                            tooltip: t('openEmail'),
                            onTap: () => _launchEmail(context),
                          ),
                          _ContactAction(
                            icon: Icons.copy,
                            tooltip: t('copy'),
                            onTap: () =>
                                _copyToClipboard(context, 'info@bodim.lk'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Phone card
                      _ContactCard(
                        icon: Icons.phone_outlined,
                        label: t('callUs'),
                        value: '077 360 4108',
                        actions: [
                          _ContactAction(
                            icon: Icons.call,
                            tooltip: t('callAction'),
                            onTap: () => _launchPhone(context),
                          ),
                          _ContactAction(
                            icon: Icons.sms,
                            tooltip: 'SMS',
                            onTap: () => _launchSms(context),
                          ),
                          _ContactAction(
                            icon: Icons.copy,
                            tooltip: t('copy'),
                            onTap: () =>
                                _copyToClipboard(context, '0773604108'),
                          ),
                        ],
                      ),
                    ],
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

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<_ContactAction> actions;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: scheme.primaryContainer,
              child: Icon(icon, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            ...actions.map(
              (a) => IconButton(
                icon: Icon(a.icon),
                tooltip: a.tooltip,
                color: scheme.primary,
                onPressed: a.onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _ContactAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
}
