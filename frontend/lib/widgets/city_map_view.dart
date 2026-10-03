import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/complaint.dart';
import '../constants/app_theme.dart';
import '../services/location_service.dart';
import 'status_badge.dart';
import 'priority_badge.dart';

class CityMapView extends StatefulWidget {
  final List<Complaint> complaints;
  final Function(Complaint) onComplaintSelected;
  final Function(double lat, double lng)? onLocationPicked;
  final double? pickedLat;
  final double? pickedLng;
  final double? userLat;
  final double? userLng;
  final bool pickMode;
  final VoidCallback? onRecenter;

  const CityMapView({
    super.key,
    required this.complaints,
    required this.onComplaintSelected,
    this.onLocationPicked,
    this.pickedLat,
    this.pickedLng,
    this.userLat,
    this.userLng,
    this.pickMode = false,
    this.onRecenter,
  });

  @override
  State<CityMapView> createState() => _CityMapViewState();
}

class _CityMapViewState extends State<CityMapView> {
  final MapController _mapController = MapController();
  Complaint? _activeComplaint;

  // Fallback city center coordinates (16.5062, 80.6480)
  static const double fallbackLat = LocationService.defaultLat;
  static const double fallbackLng = LocationService.defaultLng;

  LatLng get _initialCenter {
    if (widget.pickMode && widget.pickedLat != null && widget.pickedLng != null) {
      return LatLng(widget.pickedLat!, widget.pickedLng!);
    }
    if (widget.userLat != null && widget.userLng != null) {
      return LatLng(widget.userLat!, widget.userLng!);
    }
    if (widget.complaints.isNotEmpty) {
      return LatLng(widget.complaints.first.lat, widget.complaints.first.lng);
    }
    return const LatLng(fallbackLat, fallbackLng);
  }

  void _recenter() {
    final target = (widget.userLat != null && widget.userLng != null)
        ? LatLng(widget.userLat!, widget.userLng!)
        : (widget.pickedLat != null && widget.pickedLng != null)
            ? LatLng(widget.pickedLat!, widget.pickedLng!)
            : const LatLng(fallbackLat, fallbackLng);

    _mapController.move(target, 15.0);
    if (widget.onRecenter != null) {
      widget.onRecenter!();
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    // 1. User Location Marker
    if (widget.userLat != null && widget.userLng != null) {
      markers.add(
        Marker(
          point: LatLng(widget.userLat!, widget.userLng!),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.25),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 1.5),
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                  boxShadow: [
                    BoxShadow(color: Colors.white, blurRadius: 4, spreadRadius: 1),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Pick Mode Draggable / Tappable Pin
    if (widget.pickMode && widget.pickedLat != null && widget.pickedLng != null) {
      markers.add(
        Marker(
          point: LatLng(widget.pickedLat!, widget.pickedLng!),
          width: 50,
          height: 50,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onPanUpdate: (details) {
              // Allows drag adjustment
            },
            child: const Icon(
              Icons.location_on_rounded,
              color: AppTheme.priorityHigh,
              size: 48,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Complaint Markers coloured by Status
    for (final c in widget.complaints) {
      final statusColor = AppTheme.getStatusColor(c.status);
      final isSelected = _activeComplaint?.id == c.id;

      markers.add(
        Marker(
          point: LatLng(c.lat, c.lng),
          width: isSelected ? 48 : 38,
          height: isSelected ? 48 : 38,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _activeComplaint = c;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: isSelected ? 0.6 : 0.4),
                    blurRadius: isSelected ? 12 : 6,
                    spreadRadius: isSelected ? 3 : 1,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  AppTheme.getCategoryIcon(c.category),
                  color: Colors.white,
                  size: isSelected ? 22 : 16,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Real OpenStreetMap Tiles
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: widget.pickMode ? 15.0 : 13.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            onTap: (tapPosition, point) {
              if (widget.pickMode && widget.onLocationPicked != null) {
                widget.onLocationPicked!(point.latitude, point.longitude);
              } else {
                setState(() {
                  _activeComplaint = null;
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.citypulse.app',
              maxZoom: 19,
            ),
            MarkerLayer(markers: markers),
          ],
        ),

        // Pick Mode Banner
        if (widget.pickMode)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgCard.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary, width: 1.2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: AppTheme.primary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap anywhere on the map to adjust your issue location pin.',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Map Control Floating Buttons (Recenter, Zoom In, Zoom Out)
        Positioned(
          right: 14,
          bottom: _activeComplaint != null ? 180 : 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'map_recenter_${widget.pickMode}',
                backgroundColor: AppTheme.bgCard,
                foregroundColor: AppTheme.primary,
                onPressed: _recenter,
                tooltip: 'Recenter on My Location',
                child: const Icon(Icons.my_location_rounded, size: 20),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6),
                  ],
                ),
                child: Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, size: 20, color: AppTheme.textPrimary),
                      tooltip: 'Zoom In',
                      onPressed: _zoomIn,
                    ),
                    const Divider(height: 1, color: AppTheme.border),
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20, color: AppTheme.textPrimary),
                      tooltip: 'Zoom Out',
                      onPressed: _zoomOut,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Active Complaint Bottom Card Overlay
        if (_activeComplaint != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildActiveComplaintCard(_activeComplaint!),
          ),
      ],
    );
  }

  Widget _buildActiveComplaintCard(Complaint complaint) {
    String? distanceText;
    if (widget.userLat != null && widget.userLng != null) {
      final dist = LocationService.distanceBetween(
        widget.userLat!,
        widget.userLng!,
        complaint.lat,
        complaint.lng,
      );
      distanceText = LocationService.formatDistance(dist);
    } else if (complaint.distanceMeters != null) {
      distanceText = LocationService.formatDistance(complaint.distanceMeters!.toDouble());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.getStatusColor(complaint.status), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.getCategoryColor(complaint.category).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      AppTheme.getCategoryIcon(complaint.category),
                      color: AppTheme.getCategoryColor(complaint.category),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    complaint.category,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: complaint.status, compact: true),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
                onPressed: () => setState(() => _activeComplaint = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            complaint.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  PriorityBadge(
                    priority: complaint.priority,
                    score: complaint.priorityScore,
                    compact: true,
                  ),
                  if (distanceText != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.navigation_rounded, size: 11, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '$distanceText away',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => widget.onComplaintSelected(complaint),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text('View Details', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
