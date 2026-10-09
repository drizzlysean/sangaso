import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../models/service_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/service_service.dart';

class AddEditServiceScreen extends StatefulWidget {
  final String? serviceId;

  const AddEditServiceScreen({super.key, this.serviceId});

  @override
  State<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends State<AddEditServiceScreen> {
  static const int _maxImages = 5;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  bool _isLoading = false;
  bool _isUploadingImages = false;
  ServiceModel? _existingService;

  // Newly picked images, pending upload on save. Each entry is either a
  // File (mobile/desktop) or raw bytes (web) — exactly one of the two
  // lists holds data at any given index, matched by position.
  final List<File> _pickedImageFiles = [];
  final List<Uint8List> _pickedImageBytes = [];
  // Existing (already-uploaded) image URLs, carried over when editing.
  List<String> _imageUrls = [];

  int get _totalImageCount =>
      _imageUrls.length + _pickedImageFiles.length + _pickedImageBytes.length;

  // Define orange and green colors
  final Color greenAccent = AppColors.primary;
  final Color orangeAccent = AppColors.accent;
  final Color textPrimary = AppColors.text1;
  final Color textSecondary = AppColors.text2;
  final Color backgroundLight = AppColors.surfaceGrey;
  final Color borderColor = const Color(0xFFE9ECEF);

  final List<String> _categories = [
    'Cleaning',
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'Gardening',
    'Moving',
    'Tutoring',
    'Beauty & Wellness',
    'IT & Tech Support',
    'Event Planning',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.serviceId != null) {
      _loadService();
    }
  }

  Future<void> _loadService() async {
    setState(() => _isLoading = true);
    try {
      final serviceService = context.read<ServiceService>();
      final service = await serviceService.getService(widget.serviceId!);
      if (service != null && mounted) {
        setState(() {
          _existingService = service;
          _nameController.text = service.name;
          _descriptionController.text = service.description;
          _priceController.text = service.price.toStringAsFixed(2);
          _selectedCategory = service.category;
          _imageUrls = List<String>.from(service.imageUrls);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickServiceImage(ImageSource source) async {
    if (_totalImageCount >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can add up to $_maxImages photos per service.')),
      );
      return;
    }
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (pickedFile == null) return;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        if (!mounted) return;
        setState(() => _pickedImageBytes.add(bytes));
      } else {
        if (!mounted) return;
        setState(() => _pickedImageFiles.add(File(pickedFile.path)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: orangeAccent,
          ),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(Icons.camera_alt_outlined, color: greenAccent),
            title: const Text('Take a photo'),
            onTap: () {
              Navigator.pop(sheetContext);
              _pickServiceImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: orangeAccent),
            title: const Text('Choose from gallery'),
            onTap: () {
              Navigator.pop(sheetContext);
              _pickServiceImage(ImageSource.gallery);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _removePickedFile(int index) {
    setState(() => _pickedImageFiles.removeAt(index));
  }

  void _removePickedBytes(int index) {
    setState(() => _pickedImageBytes.removeAt(index));
  }

  void _removeExistingImage(String url) {
    setState(() => _imageUrls.remove(url));
  }

  /// Uploads every newly picked image (if any) to Firebase Storage and
  /// returns the full list of image URLs to save on the service — the
  /// kept existing URLs followed by the newly uploaded ones, in the
  /// order they were added.
  Future<List<String>> _uploadPendingImagesIfNeeded(String providerId) async {
    if (_pickedImageFiles.isEmpty && _pickedImageBytes.isEmpty) {
      return _imageUrls;
    }

    setState(() => _isUploadingImages = true);
    try {
      final uploaded = <String>[];

      for (final file in _pickedImageFiles) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('service_images')
            .child('${providerId}_${DateTime.now().microsecondsSinceEpoch}.jpg');
        final task = await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
        uploaded.add(await task.ref.getDownloadURL());
      }

      for (final bytes in _pickedImageBytes) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('service_images')
            .child('${providerId}_${DateTime.now().microsecondsSinceEpoch}.jpg');
        final task = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        uploaded.add(await task.ref.getDownloadURL());
      }

      return [..._imageUrls, ...uploaded];
    } finally {
      if (mounted) setState(() => _isUploadingImages = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    final user = authService.currentUserModel;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final serviceService = context.read<ServiceService>();
      final imageUrls = await _uploadPendingImagesIfNeeded(user.id);

      final service = ServiceModel(
        id: widget.serviceId ?? '',
        providerId: user.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        price: double.parse(_priceController.text.trim()),
        imageUrls: imageUrls,
        isActive: _existingService?.isActive ?? true,
        createdAt: _existingService?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.serviceId == null) {
        await serviceService.createService(service);
      } else {
        await serviceService.updateService(service);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.serviceId == null
                  ? 'Service created successfully'
                  : 'Service updated successfully',
            ),
            backgroundColor: greenAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: orangeAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.serviceId == null ? 'Add Service' : 'Edit Service',
          style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
        ),
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(greenAccent),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with icon
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  greenAccent,
                                  orangeAccent.withOpacity(0.7),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: greenAccent.withOpacity(0.2),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.serviceId == null
                                  ? Icons.add_business
                                  : Icons.edit,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.serviceId == null
                                ? 'Create New Service'
                                : 'Edit Service Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fill in the details below',
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Service Photos
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Photos',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              '$_totalImageCount/$_maxImages',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The first photo is used as the cover image customers see first.',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 90,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // Existing uploaded images (kept from before, or already saved)
                              for (final url in _imageUrls)
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Stack(children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        url,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 90,
                                          height: 90,
                                          color: backgroundLight,
                                          child: const Icon(Icons.broken_image_outlined),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: _isUploadingImages ? null : () => _removeExistingImage(url),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                              // Newly picked images pending upload (mobile/desktop file paths)
                              for (int i = 0; i < _pickedImageFiles.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Stack(children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(_pickedImageFiles[i], width: 90, height: 90, fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: _isUploadingImages ? null : () => _removePickedFile(i),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                              // Newly picked images pending upload (web bytes)
                              for (int i = 0; i < _pickedImageBytes.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Stack(children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(_pickedImageBytes[i], width: 90, height: 90, fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: _isUploadingImages ? null : () => _removePickedBytes(i),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                              // Add-photo tile — stays visible until the cap is reached
                              if (_totalImageCount < _maxImages)
                                GestureDetector(
                                  onTap: _isUploadingImages ? null : _showImageSourcePicker,
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: backgroundLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: _isUploadingImages
                                        ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                                        : Icon(Icons.add_a_photo_outlined, color: textSecondary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Service Name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'e.g., House Cleaning, Plumbing Repair',
                            filled: true,
                            fillColor: backgroundLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: greenAccent,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.room_service,
                              color: textSecondary,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a service name';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Category Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: backgroundLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.category,
                                color: textSecondary,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                            ),
                            dropdownColor: Colors.white,
                            style: TextStyle(color: textPrimary, fontSize: 16),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: textSecondary,
                            ),
                            isExpanded: true,
                            items: _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedCategory = value);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a category';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText:
                                'Describe your service in detail...\nWhat skills do you offer?\nWhat makes your service special?\nWhat areas do you serve?',
                            filled: true,
                            fillColor: backgroundLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: greenAccent,
                                width: 2,
                              ),
                            ),
                            alignLabelWithHint: true,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a description';
                            }
                            if (value.trim().length < 20) {
                              return 'Description must be at least 20 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price (K)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          decoration: InputDecoration(
                            hintText: 'e.g., 150.00',
                            filled: true,
                            fillColor: backgroundLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: greenAccent,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.attach_money,
                              color: textSecondary,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a price';
                            }
                            final price = double.tryParse(value.trim());
                            if (price == null || price <= 0) {
                              return 'Please enter a valid price';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [greenAccent, orangeAccent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: greenAccent.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveService,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.serviceId == null
                                        ? Icons.add_circle_outline
                                        : Icons.save,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    widget.serviceId == null
                                        ? 'Create Service'
                                        : 'Update Service',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
