import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../constants/app_theme.dart';
import 'status_badge.dart';
import 'priority_badge.dart';

class CityMapView extends StatefulWidget {
  final List<Complaint> complaints;
  final Function(Complaint) onComplaintSelected;
  final Function(double lat, double lng)? onLocationPicked;
  final double? pickedLat;
  final double? pickedLng;
  final bool pickMode;

  const CityMapView({
    super.key,
    required this.complaints,
    required this.onComplaintSelected,
    this.onLocationPicked,
    this.pickedLat,
    this.pickedLng,
    this.pickMode = false,
  });

  @override
  State<CityMapView> createState() => _CityMapViewState();
}

class _CityMapViewState extends State<CityMapView> {
  Complaint? _activeComplaint;
  Offset _mapOffset = const Offset(0, 0);
  double _zoom = 1.0;

  // Reference city center (e.g., Bengaluru City Center ~12.9716, 77.5946)
  static const double baseLat = 12.9716;
  static const double baseLng = 77.5946;
  static const double coordinateScale = 12000.0; // Scale meters to canvas pixels

  Offset _latLngToCanvas(double lat, double lng, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final dx = (lng - baseLng) * coordinateScale * _zoom + _mapOffset.dx;
    final dy = -(lat - baseLat) * coordinateScale * _zoom + _mapOffset.dy;
    return Offset(centerX + dx, centerY + dy);
  }

  Map<String, double> _canvasToLatLng(Offset pos, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final dx = (pos.dx - centerX - _mapOffset.dx) / (_zoom * coordinateScale);
    final dy = -(pos.dy - centerY - _mapOffset.dy) / (_zoom * coordinateScale);
    return {
      'lat': baseLat + dy,
      'lng': baseLng + dx,
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _mapOffset += details.delta;
            });
          },
          onTapUp: (details) {
            if (widget.pickMode && widget.onLocationPicked != null) {
              final coords = _canvasToLatLng(details.localPosition, size);
              widget.onLocationPicked!(coords['lat']!, coords['lng']!);
            } else {
              setState(() {
                _activeComplaint = null;
              });
            }
          },
          child: Stack(
            children: [
              // Custom Painted Map Canvas (City Grid, Roads, Sectors)
              CustomPaint(
                size: size,
                painter: _CityGridPainter(
                  offset: _mapOffset,
                  zoom: _zoom,
                ),
              ),

              // Picked Location Pin (in Pick Mode)
              if (widget.pickedLat != null && widget.pickedLng != null) ...[
                Builder(
                  builder: (context) {
                    final pinPos = _latLngToCanvas(widget.pickedLat!, widget.pickedLng!, size);
                    return Positioned(
                      left: pinPos.dx - 18,
                      top: pinPos.dy - 36,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Selected Location',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Icon(
                            Icons.location_on,
                            color: AppTheme.primary,
                            size: 36,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              // Complaint Pins
              ...widget.complaints.map((c) {
                final pos = _latLngToCanvas(c.lat, c.lng, size);
                final categoryColor = AppTheme.getCategoryColor(c.category);
                final isSelected = _activeComplaint?.id == c.id;

                return Positioned(
                  left: pos.dx - 18,
                  top: pos.dy - 32,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeComplaint = c;
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : categoryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? categoryColor : Colors.white,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: categoryColor.withOpacity(isSelected ? 0.8 : 0.4),
                                blurRadius: isSelected ? 12 : 6,
                                spreadRadius: isSelected ? 3 : 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            AppTheme.getCategoryIcon(c.category),
                            size: isSelected ? 20 : 16,
                            color: isSelected ? categoryColor : Colors.white,
                          ),
                        ),
                        CustomPaint(
                          size: const Size(8, 6),
                          painter: _TrianglePainter(
                            color: isSelected ? categoryColor : categoryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Map Controls Overlay (Zoom In, Zoom Out, Recenter)
              Positioned(
                right: 16,
                bottom: 24,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'zoomIn',
                      backgroundColor: AppTheme.bgCard,
                      foregroundColor: AppTheme.textPrimary,
                      onPressed: () {
                        setState(() {
                          _zoom = (_zoom * 1.25).clamp(0.4, 3.5);
                        });
                      },
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'zoomOut',
                      backgroundColor: AppTheme.bgCard,
                      foregroundColor: AppTheme.textPrimary,
                      onPressed: () {
                        setState(() {
                          _zoom = (_zoom / 1.25).clamp(0.4, 3.5);
                        });
                      },
                      child: const Icon(Icons.remove),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'recenter',
                      backgroundColor: AppTheme.bgCard,
                      foregroundColor: AppTheme.primary,
                      onPressed: () {
                        setState(() {
                          _mapOffset = const Offset(0, 0);
                          _zoom = 1.0;
                        });
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),

              // Active Complaint Popup Card
              if (_activeComplaint != null)
                Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: Card(
                    color: AppTheme.bgCard,
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.getCategoryColor(_activeComplaint!.category).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  AppTheme.getCategoryIcon(_activeComplaint!.category),
                                  color: AppTheme.getCategoryColor(_activeComplaint!.category),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _activeComplaint!.category,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              StatusBadge(status: _activeComplaint!.status, compact: true),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                                onPressed: () {
                                  setState(() {
                                    _activeComplaint = null;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _activeComplaint!.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              PriorityBadge(
                                priority: _activeComplaint!.priority,
                                score: _activeComplaint!.priorityScore,
                                compact: true,
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final selected = _activeComplaint!;
                                  setState(() => _activeComplaint = null);
                                  widget.onComplaintSelected(selected);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                child: const Text('View Full Details'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CityGridPainter extends CustomPainter {
  final Offset offset;
  final double zoom;

  _CityGridPainter({required this.offset, required this.zoom});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0D131F);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.5)
      ..strokeWidth = 1;

    final roadPaint = Paint()
      ..color = const Color(0xFF334155).withOpacity(0.6)
      ..strokeWidth = 3;

    final highwayPaint = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(0.25)
      ..strokeWidth = 6;

    final step = 50.0 * zoom;
    final startX = (offset.dx % step);
    final startY = (offset.dy % step);

    // Draw city grid lines
    for (double x = startX; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = startY; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw prominent city avenues and highways relative to center
    final centerX = size.width / 2 + offset.dx;
    final centerY = size.height / 2 + offset.dy;

    // Major Highway
    canvas.drawLine(Offset(centerX - 400 * zoom, centerY - 250 * zoom), Offset(centerX + 400 * zoom, centerY + 250 * zoom), highwayPaint);
    canvas.drawLine(Offset(centerX - 350 * zoom, centerY + 200 * zoom), Offset(centerX + 350 * zoom, centerY - 200 * zoom), highwayPaint);

    // Arterial Roads
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), roadPaint);
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), roadPaint);
    canvas.drawLine(Offset(0, centerY - 150 * zoom), Offset(size.width, centerY - 150 * zoom), roadPaint);
    canvas.drawLine(Offset(0, centerY + 150 * zoom), Offset(size.width, centerY + 150 * zoom), roadPaint);
    canvas.drawLine(Offset(centerX - 200 * zoom, 0), Offset(centerX - 200 * zoom, size.height), roadPaint);
    canvas.drawLine(Offset(centerX + 200 * zoom, 0), Offset(centerX + 200 * zoom, size.height), roadPaint);

    // Draw City Central Ring
    final ringPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24 * zoom;
    canvas.drawCircle(Offset(centerX, centerY), 90 * zoom, ringPaint);

    // Radar Pulse circles around city center
    final pulsePaint = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 160 * zoom, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant _CityGridPainter oldDelegate) {
    return oldDelegate.offset != offset || oldDelegate.zoom != zoom;
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
