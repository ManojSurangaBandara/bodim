import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/room.dart';
import '../services/app_state.dart';
import 'add_post_page.dart';
import '../widgets/pressable_scale.dart';

class RoomDetailPage extends StatefulWidget {
  final Room room;
  const RoomDetailPage({super.key, required this.room});

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  int _page = 0;

  Room get _currentRoom {
    final rooms = AppState.instance.rooms.value;
    return rooms.firstWhere(
      (r) => r.id != null && r.id == widget.room.id,
      orElse: () => widget.room,
    );
  }

  void _openFullScreen(int initialPage) {
    final images = _currentRoom.images ?? [];
    if (images.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            FullScreenGallery(images: images, initialPage: initialPage),
      ),
    );
  }

  Future<void> _call(String number) async {
    final sanitized = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: sanitized);

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await Clipboard.setData(ClipboardData(text: sanitized));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open dialer — number copied to clipboard'),
        ),
      );
    }
  }

  Future<void> _sms(String number) async {
    final sanitized = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'sms', path: sanitized);

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await Clipboard.setData(ClipboardData(text: sanitized));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open messaging app — number copied to clipboard',
          ),
        ),
      );
    }
  }

  Future<void> _whatsapp(String number) async {
    // normalize and prepare number for whatsapp (no +, country code present)
    var n = number.replaceAll(RegExp(r'[^0-9+]'), '');
    if (n.startsWith('+')) n = n.substring(1);
    if (n.startsWith('0')) n = '94' + n.substring(1);

    print('Original number: $number, Normalized: $n');

    final native = Uri.parse('whatsapp://send?phone=$n');
    final web = Uri.parse('https://wa.me/$n');
    final playStore = Uri.parse('market://details?id=com.whatsapp');

    try {
      // 1) try native app
      if (await canLaunchUrl(native)) {
        print('Trying native WhatsApp URI: $native');
        final ok = await launchUrl(
          native,
          mode: LaunchMode.externalApplication,
        );
        if (ok) {
          print('Native WhatsApp launched successfully');
          return;
        } else {
          print('Native launch failed');
        }
      } else {
        print('Native URI not launchable');
      }

      // 2) try web fallback
      print('Trying web WhatsApp URI: $web');
      final ok = await launchUrl(web, mode: LaunchMode.platformDefault);
      if (ok) {
        print('Web WhatsApp launched successfully');
        return;
      } else {
        print('Web launch failed');
      }

      // 3) offer to open Play Store (Android) so user can install WhatsApp
      if (await canLaunchUrl(playStore)) {
        print('Trying Play Store URI: $playStore');
        await launchUrl(playStore, mode: LaunchMode.externalApplication);
        return;
      } else {
        print('Play Store URI not launchable');
      }
    } catch (e) {
      print('Exception during WhatsApp launch: $e');
    }

    print('All attempts failed, showing SnackBar');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not open WhatsApp for $n — is WhatsApp installed?',
        ),
      ),
    );
  }

  Future<void> _deleteRoom() async {
    final parentNavigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Ad'),
        content: const Text('Are you sure you want to delete this ad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await AppState.instance.deleteRoom(_currentRoom);
              Navigator.of(ctx).pop();
              parentNavigator.pop(); // back to list
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectRoom(Room room) async {
    if (room.id == null) return;
    final parentContext = context;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reject Ad'),
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

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Text('No reject reasons available. Add them in Reject Reasons.');
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final text = docs[index].data()['text'] as String? ?? '';
                    return ListTile(
                      title: Text(text),
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        try {
                          await FirebaseFirestore.instance.collection('rooms').doc(room.id).update({
                            'status': 'rejected',
                            'rejectionReason': text,
                          });
                          if (!mounted) return;
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(content: Text('Ad rejected successfully.')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(content: Text('Failed to reject ad: $e')),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    String timeStr = _formatTime(local);

    if (difference.inDays == 0) {
      return '$timeStr today';
    } else if (difference.inDays == 1) {
      return '$timeStr yesterday';
    } else {
      return '${local.day}/${local.month}/${local.year} at $timeStr';
    }
  }

  String _formatTime(DateTime dt) {
    int hour = dt.hour;
    int minute = dt.minute;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Room>>(
      valueListenable: AppState.instance.rooms,
      builder: (context, rooms, _) {
        final room = rooms.firstWhere(
          (r) => r.id == widget.room.id,
          orElse: () => widget.room,
        );
        final images = room.images ?? [];
        final currentUser = AppState.instance.currentUser.value;
        final canDelete =
            currentUser != null && room.creatorEmail == currentUser.email;
        final canAdminReject = currentUser != null && currentUser.isAdmin;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(
                  Icons.home_work,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'බෝඩිම්.lk',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            actions: [
              if (canAdminReject)
                IconButton(
                  icon: const Icon(Icons.block),
                  tooltip: 'Reject Ad',
                  onPressed: room.status == 'rejected' ? null : () => _rejectRoom(room),
                ),
              if (canDelete) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddPostPage(roomToEdit: room),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteRoom,
                ),
              ],
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
                stops: [0.0, 1.0],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image carousel
                  if (images.isNotEmpty)
                    Container(
                      height: 250,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PageView.builder(
                              itemCount: images.length,
                              onPageChanged: (index) => setState(() => _page = index),
                              itemBuilder: (context, index) {
                                final image = images[index];
                                Widget content = image.startsWith('http')
                                    ? Image.network(
                                        image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Theme.of(context).colorScheme.surfaceVariant,
                                            child: const Center(
                                              child: Icon(Icons.broken_image, size: 48),
                                            ),
                                          );
                                        },
                                      )
                                    : Image.file(
                                        File(image),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Theme.of(context).colorScheme.surfaceVariant,
                                            child: const Center(
                                              child: Icon(Icons.broken_image, size: 48),
                                            ),
                                          );
                                        },
                                      );

                                return GestureDetector(
                                  onTap: () => _openFullScreen(index),
                                  child: content,
                                );
                              },
                            ),
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(images.length, (index) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: _page == index ? 12 : 8,
                                    height: _page == index ? 12 : 8,
                                    decoration: BoxDecoration(
                                      color: _page == index
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : Theme.of(context).colorScheme.onPrimary.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Room details card
                  Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            room.title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),

                          // Price
                          Text(
                            'රු. ${room.price}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          if (room.description != null && room.description!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  room.description!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                          // Location
                          if (room.district != null && room.town != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${room.town}, ${room.district}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                          // Posted time
                          if (room.createdAt != null)
                            Text(
                              'Posted: ${_formatDateTime(room.createdAt!)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Contact buttons
                  if (room.contact != null && room.contact!.isNotEmpty)
                    Card(
                      margin: const EdgeInsets.all(16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: PressableScale(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _call(room.contact!),
                                      icon: const Icon(Icons.call),
                                      label: const Text('Call'),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(50),
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: PressableScale(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _sms(room.contact!),
                                      icon: const Icon(Icons.message),
                                      label: const Text('SMS'),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(50),
                                        side: BorderSide(color: Colors.blue.shade600),
                                        foregroundColor: Colors.blue.shade700,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            PressableScale(
                              child: OutlinedButton.icon(
                                onPressed: room.contact == null || room.contact!.isNotEmpty
                                    ? () => _whatsapp(room.contact!)
                                    : null,
                                icon: const Icon(Icons.chat),
                                label: const Text('WhatsApp'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  side: BorderSide(color: Colors.green.shade600),
                                  foregroundColor: Colors.green.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialPage;
  const FullScreenGallery({
    Key? key,
    required this.images,
    this.initialPage = 0,
  }) : super(key: key);

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.initialPage;
    _controller = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) {
              final src = widget.images[i];
              Widget image;
              if (src.startsWith('http')) {
                image = Image.network(
                  src,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(context).colorScheme.background,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    );
                  },
                );
              } else {
                final f = File(src);
                image = f.existsSync()
                    ? Image.file(f, fit: BoxFit.contain)
                    : Container(color: Theme.of(context).colorScheme.background);
              }
              return Center(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: image,
                ),
              );
            },
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _current == i ? 10 : 8,
                  height: _current == i ? 10 : 8,
                  decoration: BoxDecoration(
                    color: _current == i ? Theme.of(context).colorScheme.onBackground : Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
