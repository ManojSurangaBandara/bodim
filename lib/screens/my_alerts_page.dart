import 'package:flutter/material.dart';
import '../models/saved_alert.dart';
import '../services/app_state.dart';
import '../services/localization.dart';

class MyAlertsPage extends StatelessWidget {
  final void Function(SavedAlert)? onApplyAlert;

  const MyAlertsPage({super.key, this.onApplyAlert});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.instance.languageCode,
      builder: (context, lang, _) {
        String t(String key) => AppLocalizations.translate(lang, key);
        return Scaffold(
          appBar: AppBar(
            title: Text(t('myAlerts')),
          ),
          body: ValueListenableBuilder<List<SavedAlert>>(
            valueListenable: AppState.instance.savedAlerts,
            builder: (context, alerts, _) {
              if (alerts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t('noAlertsYet'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return _AlertCard(
                    alert: alert,
                    onDelete: () => _confirmDelete(context, alert, t),
                    onApply: onApplyAlert != null
                        ? () => onApplyAlert!(alert)
                        : null,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    SavedAlert alert,
    String Function(String) t,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('deleteAlert')),
        content: Text('${t('deleteAlertConfirm')}\n\n"${alert.name}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (alert.id != null) {
                await AppState.instance.deleteAlert(alert.id!);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t('confirmDelete')),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final SavedAlert alert;
  final VoidCallback onDelete;
  final VoidCallback? onApply;

  const _AlertCard({required this.alert, required this.onDelete, this.onApply});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chips = <String>[];
    if (alert.district != null) chips.add(alert.district!);
    if (alert.town != null) chips.add(alert.town!);
    if (alert.category != null) chips.add(alert.category!);
    if (alert.minPrice != null && alert.maxPrice != null) {
      chips.add('රු.${alert.minPrice}–${alert.maxPrice}');
    } else if (alert.minPrice != null) {
      chips.add('රු.≥${alert.minPrice}');
    } else if (alert.maxPrice != null) {
      chips.add('රු.≤${alert.maxPrice}');
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onApply,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.notifications_active,
                color: scheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: chips
                            .map(
                              (c) => Chip(
                                label: Text(
                                  c,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade400,
                tooltip: 'Delete',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
