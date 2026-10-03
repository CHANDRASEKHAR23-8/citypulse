import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../services/api_service.dart';
import '../../services/image_picker_service.dart';
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
  double _lat = 12.9716;
  double _lng = 77.5946;
  String _locationName = 'MG Road / City Center';

  Uint8List? _imageBytes;
  String? _imageName;
  bool _showMapPicker = false;

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

  final List<Map<String, dynamic>> _landmarkPresets = [
    {'name': 'City Center (MG Road)', 'lat': 12.9716, 'lng': 77.5946},
    {'name': 'East Hub (Indiranagar)', 'lat': 12.9784, 'lng': 77.6408},
    {'name': 'South Quarter (Koramangala)', 'lat': 12.9352, 'lng': 77.6245},
    {'name': 'Tech Corridor (Whitefield)', 'lat': 12.9698, 'lng': 77.7500},
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
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
                  TextButton.icon(
                    onPressed: () => setState(() => _showMapPicker = !_showMapPicker),
                    icon: Icon(_showMapPicker ? Icons.view_headline : Icons.map_outlined, size: 16),
                    label: Text(_showMapPicker ? 'Hide Map' : 'Select on Map'),
                  ),
                ],
              ),
              const SizedBox(height: 4),

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
                    const Icon(Icons.my_location_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _locationName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Lat: ${_lat.toStringAsFixed(4)}, Lng: ${_lng.toStringAsFixed(4)}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Quick Landmark Presets
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _landmarkPresets.map((preset) {
                  final isChosen = _lat == preset['lat'] && _lng == preset['lng'];
                  return ChoiceChip(
                    label: Text(preset['name'] as String, style: const TextStyle(fontSize: 11)),
                    selected: isChosen,
                    selectedColor: AppTheme.primary.withOpacity(0.2),
                    backgroundColor: AppTheme.bgCard,
                    labelStyle: TextStyle(
                      color: isChosen ? AppTheme.primary : AppTheme.textSecondary,
                      fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _lat = preset['lat'] as double;
                          _lng = preset['lng'] as double;
                          _locationName = preset['name'] as String;
                        });
                      }
                    },
                  );
                }).toList(),
              ),

              // Embedded Interactive Pin Picker Map
              if (_showMapPicker) ...[
                const SizedBox(height: 12),
                Container(
                  height: 220,
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
                    onComplaintSelected: (_) {},
                    onLocationPicked: (newLat, newLng) {
                      setState(() {
                        _lat = newLat;
                        _lng = newLng;
                        _locationName = 'Custom Map Pin';
                      });
                    },
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '💡 Tap anywhere on the grid to place your issue pin',
                  style: TextStyle(color: AppTheme.accent, fontSize: 11),
                ),
              ],

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
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _imageBytes!,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Photo Attached',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              _imageName ?? 'photo.jpg',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.priorityHigh, size: 20),
                        tooltip: 'Remove Photo',
                        onPressed: () => setState(() {
                          _imageBytes = null;
                          _imageName = null;
                        }),
                      ),
                    ],
                  ),
                ),

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
