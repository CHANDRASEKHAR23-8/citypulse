import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/complaint.dart';
import '../../providers/complaint_provider.dart';
import '../../services/image_picker_service.dart';
import '../../constants/app_theme.dart';

class UpdateStatusSheet extends StatefulWidget {
  final Complaint complaint;

  const UpdateStatusSheet({super.key, required this.complaint});

  @override
  State<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<UpdateStatusSheet> {
  final _noteController = TextEditingController();
  late String _status;
  Uint8List? _resolutionImageBytes;
  String? _resolutionImageName;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Default next step
    if (widget.complaint.status == 'ASSIGNED') {
      _status = 'IN_PROGRESS';
    } else if (widget.complaint.status == 'IN_PROGRESS') {
      _status = 'RESOLVED';
    } else {
      _status = widget.complaint.status;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickResolutionPhoto(ImageSource source) async {
    final photo = await ImagePickerService.pickImage(context: context, source: source);
    if (photo != null) {
      setState(() {
        _resolutionImageBytes = photo.bytes;
        _resolutionImageName = photo.name;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final provider = Provider.of<ComplaintProvider>(context, listen: false);
    final ok = await provider.updateStatus(
      widget.complaint.id,
      status: _status,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      resolutionImageBytes: _resolutionImageBytes,
      resolutionImageName: _resolutionImageName,
    );

    setState(() => _isSubmitting = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint #${widget.complaint.id} status successfully updated to $_status!'),
          backgroundColor: AppTheme.statusResolved,
        ),
      );
      Navigator.pop(context, true);
    } else if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to update status'),
          backgroundColor: AppTheme.priorityHigh,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Issue #${widget.complaint.id}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Category: ${widget.complaint.category} • Current: ${widget.complaint.status}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Select Target Status
            const Text(
              'Set New Status',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusOption('IN_PROGRESS', 'In Progress', Icons.autorenew_rounded, AppTheme.statusInProgress),
                const SizedBox(width: 10),
                _buildStatusOption('RESOLVED', 'Resolved', Icons.check_circle_outline_rounded, AppTheme.statusResolved),
              ],
            ),

            const SizedBox(height: 18),

            // Note input
            const Text(
              'Resolution Note / Field Remarks',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Dispatched maintenance crew, replaced blown fuse, verified working.',
              ),
            ),

            const SizedBox(height: 18),

            // Resolution Photo
            const Text(
              'Resolution Photo Proof (Optional/Recommended)',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
              const SizedBox(height: 8),

              if (_resolutionImageBytes != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgInput,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.statusResolved),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _resolutionImageBytes!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resolution Proof Attached',
                              style: TextStyle(
                                color: AppTheme.statusResolved,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              _resolutionImageName ?? 'resolution.jpg',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.priorityHigh, size: 20),
                        tooltip: 'Remove',
                        onPressed: () => setState(() {
                          _resolutionImageBytes = null;
                          _resolutionImageName = null;
                        }),
                      ),
                    ],
                  ),
                ),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickResolutionPhoto(ImageSource.camera),
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
                      onPressed: () => _pickResolutionPhoto(ImageSource.gallery),
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

            const SizedBox(height: 24),

            // Save Status Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isSubmitting ? 'Updating...' : 'Confirm Status Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getStatusColor(_status),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(String statusVal, String label, IconData icon, Color color) {
    final isSelected = _status == statusVal;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _status = statusVal),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : AppTheme.bgInput,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppTheme.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : AppTheme.textMuted, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
