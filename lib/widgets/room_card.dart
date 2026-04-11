import 'dart:io';

import 'package:flutter/material.dart';
import '../models/room.dart';
import '../screens/room_detail_page.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final bool hideDetailsOnPendingRejected;

  const RoomCard({
    super.key,
    required this.room,
    this.hideDetailsOnPendingRejected = false,
  });

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroBase = '${room.title}-${room.createdAt?.millisecondsSinceEpoch ?? room.price}';

    Widget imageWidget;
    if (room.images != null && room.images!.isNotEmpty) {
      final first = room.images!.first;
      if (first.startsWith('http')) {
        imageWidget = Image.network(
          first,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.broken_image, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant);
          },
        );
      } else {
        final f = File(first);
        imageWidget = f.existsSync()
            ? Image.file(f, fit: BoxFit.cover)
            : Icon(Icons.home, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant);
      }
    } else {
      imageWidget = Icon(Icons.home, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant);
    }

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoomDetailPage(room: room))),
        child: SizedBox(
          height: 100,
          child: Row(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Hero(
                  tag: '$heroBase-0',
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: imageWidget,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (room.status != 'approved')
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: room.status == 'pending'
                                  ? Colors.orange.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              room.status.toUpperCase(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: room.status == 'pending'
                                        ? Colors.orange.shade900
                                        : Colors.red.shade900,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                      if (room.status == 'rejected' && room.rejectionReason != null && room.rejectionReason!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            room.rejectionReason!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
                          ),
                        ),
                      if (!hideDetailsOnPendingRejected && room.status != 'rejected') ...[
                        const SizedBox(height: 6),
                        if ((room.town != null && room.town!.isNotEmpty) || (room.district != null && room.district!.isNotEmpty))
                          Text(
                            '${room.town ?? ''}${(room.town != null && room.district != null) ? ', ' : ''}${room.district ?? ''}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        const Spacer(),
                        Row(
                          children: [
                            Text('රු. ${room.price}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            if (room.createdAt != null)
                              Text(_timeAgo(room.createdAt!), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            ],
          ),
        ),
      ),
    );
  }
}
