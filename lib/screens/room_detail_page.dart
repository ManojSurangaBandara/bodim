import 'dart:io';

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
          (r) => r.id != null && r.id == widget.room.id,
          orElse: () => widget.room,
        );
        final images = room.images ?? [];
        final currentUser = AppState.instance.currentUser.value;
        final canDelete =
            currentUser != null && room.creatorEmail == currentUser.email;

        return Scaffold(
          appBar: AppBar(
            title: Text(room.title),
            actions: canDelete
                ? [
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
                  ]
                : null,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image carousel / placeholder
                SizedBox(
                  height: 300,
                  child: images.isEmpty
                      ? Container(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.06),
                          child: Center(
                            child: Icon(Icons.home, size: 96, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        )
                      : Stack(
                          children: [
                            PageView.builder(
                              itemCount: images.length,
                              onPageChanged: (i) => setState(() => _page = i),
                              itemBuilder: (context, i) {
                                final src = images[i];
                                final heroTag = '${room.title}-${room.createdAt?.millisecondsSinceEpoch ?? room.price}-$i';

                                Widget img;
                                if (src.startsWith('http')) {
                                  img = Image.network(
                                    src,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                } else {
                                  final f = File(src);
                                  img = f.existsSync()
                                      ? Image.file(f, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                                      : Container(color: Colors.grey.shade200);
                                }

                                return GestureDetector(
                                  onTap: () => _openFullScreen(i),
                                  child: Hero(
                                    tag: heroTag,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        img,
                                        Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [Colors.transparent, Theme.of(context).colorScheme.onSurface.withOpacity(0.12)],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              bottom: 8,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(images.length, (i) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: _page == i ? 10 : 8,
                                    height: _page == i ? 10 : 8,
                                    decoration: BoxDecoration(
                                      color: _page == i
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              room.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          Text(
                            'රු. ${room.price}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: Theme.of(context).colorScheme.primary),
                          ),
                        ],
                      ),
                      if (room.status != 'approved')
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Chip(
                            backgroundColor: room.status == 'pending'
                                ? Colors.orange.shade100
                                : Colors.red.shade100,
                            label: Text(
                              room.status!.toUpperCase(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: room.status == 'pending'
                                        ? Colors.orange.shade900
                                        : Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (room.description != null && room.description!.isNotEmpty)
                        Text(
                          room.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                      if (room.createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Posted on: ${_formatDateTime(room.createdAt!)}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),

                      const SizedBox(height: 12),
                      if (room.contact != null && room.contact!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 18,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            SelectableText(
                              room.contact!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),

                      if (room.district != null && room.town != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 18,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${room.town}, ${room.district}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: PressableScale(
                              child: ElevatedButton.icon(
                                onPressed: room.contact == null || room.contact!.isEmpty
                                    ? null
                                    : () => _call(room.contact!),
                                icon: const Icon(Icons.phone),
                                label: const Text('Call'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: PressableScale(
                              child: OutlinedButton.icon(
                                onPressed: room.contact == null || room.contact!.isEmpty
                                    ? null
                                    : () => _sms(room.contact!),
                                icon: const Icon(Icons.message),
                                label: const Text('SMS'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: PressableScale(
                              child: OutlinedButton.icon(
                                onPressed: room.contact == null || room.contact!.isEmpty
                                    ? null
                                    : () => _whatsapp(room.contact!),
                                icon: const Icon(Icons.chat),
                                label: const Text('WhatsApp'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
