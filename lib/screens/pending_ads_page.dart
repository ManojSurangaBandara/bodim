import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/room.dart';
import '../services/app_state.dart';
import 'reject_reasons_page.dart';

class PendingAdsPage extends StatefulWidget {
  const PendingAdsPage({super.key});

  @override
  State<PendingAdsPage> createState() => _PendingAdsPageState();
}

class _PendingAdsPageState extends State<PendingAdsPage> {
  final Set<String> _processing = {};

  Future<void> _updateRoomStatus(
    BuildContext context,
    Room room,
    String status, {
    String? rejectionReason,
  }) async {
    if (room.id == null || _processing.contains(room.id)) return;

    setState(() {
      _processing.add(room.id!);
    });

    try {
      final data = <String, dynamic>{'status': status};
      if (status == 'approved') {
        data['rejectionReason'] = FieldValue.delete();
      } else if (rejectionReason != null) {
        data['rejectionReason'] = rejectionReason;
      } else {
        data['rejectionReason'] = null;
      }

      await FirebaseFirestore.instance.collection('rooms').doc(room.id).update(data);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'approved'
              ? 'Ad approved successfully.'
              : 'Ad rejected successfully.'),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update ad status: $e')),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() {
          _processing.remove(room.id);
        });
      }
    }
  }

  Future<void> _showRejectReasonDialog(Room room) async {
    if (room.id == null || _processing.contains(room.id)) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select reject reason'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('reject_reasons')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No reject reasons available. Add them in Reject Reasons.');
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final text = doc.data()['text'] as String? ?? '';
                    return ListTile(
                      title: Text(text),
                      onTap: () {
                        Navigator.of(context).pop();
                        _updateRoomStatus(
                          context,
                          room,
                          'rejected',
                          rejectionReason: text,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

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
    final currentUser = AppState.instance.currentUser.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Ads')),
      body: ValueListenableBuilder<List>(
        valueListenable: AppState.instance.rooms,
        builder: (context, rooms, child) {
          if (currentUser == null || !currentUser.isAdmin) {
            return const Center(child: Text('You are not authorized to view this page.'));
          }

          final pendingRooms = rooms.cast<Room>().where((room) => room.status == 'pending').toList();

          if (pendingRooms.isEmpty) {
            return const Center(child: Text('There are no pending ads at the moment.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            itemCount: pendingRooms.length,
            itemBuilder: (context, index) {
              final room = pendingRooms[index];
              final isProcessing = room.id != null && _processing.contains(room.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (room.images != null && room.images!.isNotEmpty)
                      SizedBox(
                        height: 180,
                        child: PageView.builder(
                          itemCount: room.images!.length,
                          itemBuilder: (context, imageIndex) {
                            final src = room.images![imageIndex];
                            return src.startsWith('http')
                                ? Image.network(
                                    src,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Theme.of(context).colorScheme.surfaceVariant,
                                        child: const Center(child: Icon(Icons.broken_image, size: 48)),
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(src),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  );
                          },
                        ),
                      )
                    else
                      Container(
                        height: 180,
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Center(
                          child: Icon(
                            Icons.photo_library,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text('රු. ${room.price}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                          const SizedBox(height: 8),
                          if (room.description != null && room.description!.isNotEmpty)
                            Text(room.description!),
                          if (room.contact != null && room.contact!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text('Contact: ${room.contact!}'),
                          ],
                          if (room.district != null && room.district!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text('Location: ${room.town ?? ''}${room.town != null && room.town!.isNotEmpty ? ', ' : ''}${room.district!}'),
                          ],
                          if (room.creatorEmail != null && room.creatorEmail!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text('Creator: ${room.creatorEmail!}'),
                          ],
                          if (room.createdAt != null) ...[
                            const SizedBox(height: 10),
                            Text('Created: ${_timeAgo(room.createdAt!)}'),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isProcessing ? null : () => _showRejectReasonDialog(room),
                                  child: isProcessing
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isProcessing ? null : () => _updateRoomStatus(context, room, 'approved'),
                                  child: isProcessing
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text('Approve'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
