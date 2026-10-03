import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../services/api_service.dart';
import '../../services/image_picker_service.dart';
import '../../services/location_service.dart';
import '../../constants/app_theme.dart';
import '../../widgets/duplicate_dialog.dart';
import '../../widgets/city_map_view.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();

  String _selectedCategory = 'Pothole';
  double _lat = LocationService.defaultLat;
  double _lng = LocationService.defaultLng;
  String _locationStatus = 'Acquiring GPS location...';
  bool _isLocating = false;

  Uint8List? _imageBytes;
  String? _imageName;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Pothole',
      'dept': 'Roads',
      'priority': 2,
      'icon': Icons.warning_amber_rounded,
      'color': const Color(0xFFF97316),
    },
    {
      'name': 'Streetlight',
      'dept': 'Electricity',
      'priority': 2,
      'icon': Icons.lightbulb_outline_rounded,
      'color': const Color(0xFFFBBF24),
    },
    {
      'name': 'Garbage',
      'dept': 'Sanitation',
      'priority': 1,
      'icon': Icons.delete_outline_rounded,
      'color': const Color(0xFF10B981),
    },
    {
      'name': 'Water Leakage',
      'dept': 'Water',
      'priority': 3,
      'icon': Icons.water_drop_outlined,
      'color': const Color(0xFF06B6D4),
    },
    {
      'name': 'Traffic',
      'dept': 'Traffic',
      'priority': 2,
      'icon': Icons.traffic_rounded,
      'color': const Color(0xFF8B5CF6),
    },
  ];

  @override
  void initState() {
    super.initState();
    // Automatically capture GPS location on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureLocation();
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isLocating = true;
      _locationStatus = 'Acquiring high-accuracy GPS...';
    });

    final result = await LocationService.getCurrentLocation(context: context);
    if (mounted) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
        _isLocating = false;
        if (result.isDefaultFallback) {
          _locationStatus = 'Default Central Center (GPS unavailable)';
        } else {
          _locationStatus = 'Real-time GPS Location Verified';
        }
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final photo = await ImagePickerService.pickImage(context: context, source: source);
    if (photo != null) {
      setState(() {
        _imageBytes = photo.bytes;
        _imageName = photo.name;
      });
    }
  }

  void _showRetakeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
              title: const Text('Retake Photo with Camera', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.accent),
              title: const Text('Choose Different from Gallery', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit({bool force = false}) async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ComplaintProvider>(context, listen: false);

    try {
      final complaint = await provider.submitComplaint(
        category: _selectedCategory,
        description: _descController.text.trim(),
        lat: _lat,
        lng: _lng,
        imageBytes: _imageBytes,
        imageName: _imageName,
        force: force,
      );

      if (complaint != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complaint #${complaint.id} registered and auto-assigned to ${complaint.department}!'),
            backgroundColor: AppTheme.statusResolved,
          ),
        );
        Navigator.pop(context);
      }
    } on DuplicateException catch (dup) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => DuplicateDialog(
            duplicate: dup.duplicate,
            onSupport: () async {
              final ok = await provider.supportComplaint(dup.duplicate.id);
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Supported issue #${dup.duplicate.id}! Priority boosted to ${dup.duplicate.priorityScore}.'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
                Navigator.pop(context);
              }
            },
            onForceSubmit: () {
              _handleSubmit(force: true);
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ComplaintProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Urban Problem'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Selection
              const Text(
                '1. Select Problem Category',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Auto-routes to the designated department with base urgency weighting.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),

              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['name'];
                    final color = cat['color'] as Color;

                    return InkWell(
                      onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 110,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.2) : AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? color : AppTheme.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat['icon'] as IconData, color: isSelected ? color : AppTheme.textMuted, size: 26),
                            const SizedBox(height: 6),
                            Text(
                              cat['name'] as String,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Base: +${cat['priority']}',
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Description Field
              const Text(
                '2. Issue Description',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe the problem clearly (e.g. Broken pipe flooding opposite metro gate 2)...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please describe the problem' : null,
              ),

              const SizedBox(height: 24),

              // Location Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '3. GPS Location & Pin',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isLocating ? null : _captureLocation,
                    icon: _isLocating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                          )
                        : const Icon(Icons.my_location_rounded, size: 16),
                    label: const Text('Use my location', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primary),
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Coordinates Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pin_drop_rounded, color: AppTheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _locationStatus,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            'Latitude: ${_lat.toStringAsFixed(6)} • Longitude: ${_lng.toStringAsFixed(6)}',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Embedded Interactive Pin Picker Map
              Container(
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: CityMapView(
                  complaints: provider.complaints,
                  pickMode: true,
                  pickedLat: _lat,
                  pickedLng: _lng,
                  userLat: _lat,
                  userLng: _lng,
                  onRecenter: _captureLocation,
                  onComplaintSelected: (_) {},
                  onLocationPicked: (newLat, newLng) {
                    setState(() {
                      _lat = newLat;
                      _lng = newLng;
                      _locationStatus = 'Adjusted Location Pin on Map';
                    });
                  },
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '💡 Tap anywhere on the map to adjust your issue location pin.',
                style: TextStyle(color: AppTheme.accent, fontSize: 11),
              ),

              const SizedBox(height: 24),

              // Photo Upload Section
              const Text(
                '4. Photo Evidence',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              if (_imageBytes != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.statusResolved),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _imageBytes!,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _imageName ?? 'photo.jpg',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showRetakeOptions,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retake'),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _imageBytes = null;
                              _imageName = null;
                            }),
                            icon: const Icon(Icons.delete_outline_rounded, size: 16),
                            label: const Text('Remove'),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.priorityHigh),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text('Take Photo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppTheme.primary),
                          foregroundColor: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: const Text('Choose from Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppTheme.border),
                          foregroundColor: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.isLoading ? null : () => _handleSubmit(force: false),
                  icon: provider.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(provider.isLoading ? 'Checking Duplicates & Submitting...' : 'Submit Urban Complaint'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
