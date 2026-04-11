import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_state.dart';
import '../models/room.dart';
import '../widgets/room_card.dart';
import '../widgets/pressable_scale.dart';
import 'login_page.dart';
import 'add_post_page.dart';
import 'my_ads_page.dart';
import 'pending_ads_page.dart';
import 'reject_reasons_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedDistrict;
  String? _selectedTown;
  RangeValues? _priceRange;
  bool _isOffline = false;
  bool _showBackOnline = false;
  bool _filtersExpanded = true;
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _checkConnectivity(),
    );
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    bool connected = false;
    try {
      final result = await InternetAddress.lookup('example.com').timeout(
        const Duration(seconds: 5),
      );
      connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      connected = false;
    }

    if (!mounted) return;

    if (connected) {
      if (_isOffline) {
        setState(() {
          _isOffline = false;
          _showBackOnline = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() {
            _showBackOnline = false;
          });
        });
      }
    } else {
      if (!_isOffline) {
        setState(() {
          _isOffline = true;
          _showBackOnline = false;
        });
      }
    }
  }

  Future<void> _retryConnectivity() async {
    await _checkConnectivity();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.home_work,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'බෝඩිම්.lk',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppState.instance.themeMode,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              final icon = isDark ? Icons.nightlight_round : Icons.wb_sunny;
              final tooltip = isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode';
              return IconButton(
                icon: Icon(icon, color: Theme.of(context).colorScheme.primary),
                tooltip: tooltip,
                onPressed: () => AppState.instance.cycleThemeMode(),
              );
            },
          ),

          ValueListenableBuilder(
            valueListenable: app.currentUser,
            builder: (context, user, child) {
              if (user == null) {
                return TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              } else {
                return PopupMenuButton<int>(
                  onSelected: (v) {
                    if (v == 1) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyAdsPage()),
                      );
                    } else if (v == 2) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    } else if (v == 3) {
                      app.logout();
                    } else if (v == 4) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PendingAdsPage()),
                      );
                    } else if (v == 5) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RejectReasonsPage()),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 0,
                      child: Row(
                        children: [
                          Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(user.email),
                        ],
                      ),
                    ),
                    const PopupMenuItem(value: 1, child: Text('My Ads')),
                    const PopupMenuItem(value: 2, child: Text('Profile')),
                    if (user.isAdmin) ...[
                      const PopupMenuItem(value: 4, child: Text('Pending Ads')),
                      const PopupMenuItem(value: 5, child: Text('Reject Reasons')),
                    ],
                    const PopupMenuItem(value: 3, child: Text('Logout')),
                  ],
                  icon: Icon(
                    Icons.account_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }
            },
          ),
        ],
      ),

      // body: add location filter above the list
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          children: [
            ValueListenableBuilder<List>(
              valueListenable: app.rooms,
              builder: (context, rooms, child) {
                final allRooms = List.of(rooms.cast<Room>().where((r) => r.status == 'approved'));

                // compute unique districts and towns
                final districts = {
                  for (var r in allRooms)
                    if (r.district != null && r.district!.trim().isNotEmpty)
                      r.district!,
                }.toList();
                districts.sort();

                final towns = {
                  for (var r in allRooms)
                    if ((_selectedDistrict == null ||
                            r.district == _selectedDistrict) &&
                        r.town != null &&
                        r.town!.trim().isNotEmpty)
                      r.town!,
                }.toList();
                towns.sort();

                // --- price parsing / range preparation for slider & filtering ---
                int? parsePrice(String? s) {
                  if (s == null) return null;
                  final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.isEmpty) return null;
                  return int.tryParse(digits);
                }

                final priceList = allRooms
                    .map((r) => parsePrice(r.price))
                    .whereType<int>()
                    .toList();

                int? minPrice;
                int? maxPrice;
                if (priceList.isNotEmpty) {
                  minPrice = priceList.reduce((a, b) => a < b ? a : b);
                  maxPrice = priceList.reduce((a, b) => a > b ? a : b);
                }

                // flow-safe aliases used below so the analyzer has non-null locals
                final int minP = minPrice ?? 0;
                final int maxP = maxPrice ?? 0;

                final RangeValues? effectivePriceRange = priceList.isNotEmpty
                    ? RangeValues(
                        (_priceRange != null)
                            ? _priceRange!.start.clamp(
                                minP.toDouble(),
                                maxP.toDouble(),
                              )
                            : minP.toDouble(),
                        (_priceRange != null)
                            ? _priceRange!.end.clamp(minP.toDouble(), maxP.toDouble())
                            : maxP.toDouble(),
                      )
                    : null;

                // filtered list (now includes price range when set)
                final filtered = allRooms.where((r) {
                  if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
                    if (r.district != _selectedDistrict) return false;
                  }
                  if (_selectedTown != null && _selectedTown!.isNotEmpty) {
                    if (r.town != _selectedTown) return false;
                  }

                  if (effectivePriceRange != null) {
                    final p = parsePrice(r.price);
                    if (p == null)
                      return false; // hide unparseable-priced items when filtering
                    if (p < effectivePriceRange.start.round() ||
                        p > effectivePriceRange.end.round())
                      return false;
                  }

                  return true;
                }).toList();

                return Column(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: AppState.instance.updateAvailable,
                      builder: (context, available, _) {
                        if (!available) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.all(12),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.orange.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.system_update,
                                    color: Colors.orange.shade700,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'A new version is available!',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final url = AppState.instance.updateUrl.value;
                                      if (url != null) {
                                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade600,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Update'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_isOffline || _showBackOnline)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: _isOffline ? Colors.red.shade50 : Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  _isOffline ? Icons.wifi_off : Icons.wifi,
                                  color: _isOffline ? Colors.red.shade700 : Colors.green.shade700,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _isOffline ? 'You\'re offline — check your connection' : 'Back online!',
                                    style: TextStyle(
                                      color: _isOffline ? Colors.red.shade800 : Colors.green.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (_isOffline)
                                  TextButton(
                                    onPressed: _retryConnectivity,
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red.shade700,
                                    ),
                                    child: const Text('Retry'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Modern filter card
                    Card(
                      margin: const EdgeInsets.all(12),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _filtersExpanded = !_filtersExpanded;
                                });
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Filters',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: 'Clear filters',
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _selectedDistrict = null;
                                        _selectedTown = null;
                                        _priceRange = null;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    tooltip: _filtersExpanded ? 'Collapse filters' : 'Expand filters',
                                    icon: Icon(_filtersExpanded ? Icons.expand_less : Icons.expand_more),
                                    onPressed: () {
                                      setState(() {
                                        _filtersExpanded = !_filtersExpanded;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: _filtersExpanded
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: DropdownButtonFormField<String>(
                                                  isExpanded: true,
                                                  value:
                                                      (_selectedDistrict != null &&
                                                          districts.contains(_selectedDistrict))
                                                      ? _selectedDistrict
                                                      : null,
                                                  decoration: InputDecoration(
                                                    labelText: 'District',
                                                    prefixIcon: const Icon(Icons.location_city),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                  ),
                                                  items: ['All', ...districts]
                                                      .map(
                                                        (d) => DropdownMenuItem(
                                                          value: d == 'All' ? null : d,
                                                          child: Text(d),
                                                        ),
                                                      )
                                                      .toList(),
                                                  onChanged: (v) {
                                                    setState(() {
                                                      _selectedDistrict = v;
                                                      _selectedTown = null;
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: DropdownButtonFormField<String>(
                                                  isExpanded: true,
                                                  value:
                                                      (_selectedTown != null &&
                                                          towns.contains(_selectedTown))
                                                      ? _selectedTown
                                                      : null,
                                                  decoration: InputDecoration(
                                                    labelText: 'Town',
                                                    prefixIcon: const Icon(Icons.location_on),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                  ),
                                                  items: ['All', ...towns]
                                                      .map(
                                                        (t) => DropdownMenuItem(
                                                          value: t == 'All' ? null : t,
                                                          child: Text(t),
                                                        ),
                                                      )
                                                      .toList(),
                                                  onChanged: (v) {
                                                    setState(() {
                                                      _selectedTown = v;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Price filter (RangeSlider) — visible only when numeric prices exist
                                          if (priceList.isNotEmpty) ...[
                                            const SizedBox(height: 20),
                                            Text(
                                              'Price Range (රු./month)',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            RangeSlider(
                                              values: effectivePriceRange!,
                                              min: minPrice!.toDouble(),
                                              max: maxPrice!.toDouble(),
                                              labels: RangeLabels(
                                                'රු. ${effectivePriceRange.start.round()}',
                                                'රු. ${effectivePriceRange.end.round()}',
                                              ),
                                              onChanged: (v) {
                                                setState(() {
                                                  _priceRange = v;
                                                });
                                              },
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Min: රු. ${effectivePriceRange.start.round()}',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                                Text(
                                                  'Max: රු. ${effectivePriceRange.end.round()}',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                margin: const EdgeInsets.all(24),
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 80,
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'No rooms found',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try adjusting your filters or check back later for new listings.',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _selectedDistrict = null;
                                            _selectedTown = null;
                                            _priceRange = null;
                                          });
                                        },
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Clear Filters'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: RoomCard(room: filtered[index]),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),

            ValueListenableBuilder<bool>(
              valueListenable: AppState.instance.forceUpdateRequired,
              builder: (context, forceUpdate, _) {
                if (!forceUpdate) return const SizedBox.shrink();
                return Positioned.fill(
                  child: AbsorbPointer(
                    absorbing: true,
                    child: Container(
                      color: Colors.white.withOpacity(0.95),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.system_update,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Update Required',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'A mandatory update is available. You must update the app before continuing.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  final url = AppState.instance.updateUrl.value;
                                  if (url != null) {
                                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Update Now'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            ValueListenableBuilder<bool>(
              valueListenable: AppState.instance.forceUpdateRequired,
              builder: (context, forceUpdate, _) {
                if (!forceUpdate) return const SizedBox.shrink();
                return Positioned.fill(
                  child: AbsorbPointer(
                    absorbing: true,
                    child: Container(
                      color: Colors.white.withOpacity(0.95),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.system_update,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Update Required',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'A mandatory update is available. You must update the app before continuing.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  final url = AppState.instance.updateUrl.value;
                                  if (url != null) {
                                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Update Now'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      floatingActionButton: ValueListenableBuilder(
        valueListenable: app.currentUser,
        builder: (context, user, child) {
          if (user == null) return const SizedBox.shrink();
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: PressableScale(
              child: FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddPostPage()),
                ),
                tooltip: 'Add New Room Listing',
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Room',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
