import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../models/user_model.dart'; // CHANGED TO RELATIVE IMPORT
import '../../../services/account_deletion_service.dart';
import '../../../services/auth_service.dart'; // CHANGED TO RELATIVE IMPORT

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // For web: Store image as bytes
  Uint8List? _webImageBytes;

  // For mobile/desktop
  File? _selectedImage;

  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // Define your colors - UPDATED TO MATCH SCREENSHOT
  final Color greenAccent = AppColors.primary;
  final Color orangeAccent = AppColors.accent;
  final Color textPrimary = AppColors.textPrimary;
  final Color textSecondary = AppColors.textSecondary;
  final Color backgroundLight = AppColors.background;
  final Color borderColor = AppColors.cardBorder;
  final Color buttonBackground = AppColors.accent;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // Web: Use bytes
          final bytes = await pickedFile.readAsBytes();
          if (!mounted) return;
          setState(() {
            _webImageBytes = bytes;
          });
        } else {
          // Mobile/Desktop: Use File
          if (!mounted) return;
          setState(() {
            _selectedImage = File(pickedFile.path);
          });
        }
        _showImagePreview();
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Could not open the camera or gallery.');
    }
  }

  Future<void> _uploadProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackbar('You must be logged in');
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? downloadUrl;

      if (kIsWeb && _webImageBytes != null) {
        // Web: Upload bytes directly
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        final metadata = SettableMetadata(contentType: 'image/jpeg');

        final uploadTask = storageRef.putData(_webImageBytes!, metadata);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } else if (_selectedImage != null) {
        // Mobile/Desktop: Upload file
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = await storageRef.putFile(_selectedImage!);
        downloadUrl = await uploadTask.ref.getDownloadURL();
      } else {
        _showErrorSnackbar('No image selected');
        return;
      }

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'photoUrl': downloadUrl, 'updatedAt': DateTime.now().toIso8601String()},
      );

      // Update local user model - FIXED: Use copyWith instead of constructor
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUserModel;
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          photoUrl: downloadUrl,
          updatedAt: DateTime.now(),
        );
        authService.updateUser(updatedUser);
      }

      _showSuccessSnackbar('Profile picture updated successfully!');

      // Clear selected image
      setState(() {
        _selectedImage = null;
        _webImageBytes = null;

      });

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        String msg;
        switch (e.code) {
          case 'object-not-found':
            msg = 'Upload failed: the app\'s photo storage isn\'t set up yet. '
                'Please contact support — Firebase Storage needs to be enabled for this project.';
            break;
          case 'unauthorized':
            msg = 'Upload failed: you don\'t have permission to upload photos. '
                'Please contact support — Storage security rules need to be configured.';
            break;
          case 'canceled':
            msg = 'Upload was cancelled.';
            break;
          default:
            msg = 'Failed to upload image (${e.code}). Please try again.';
        }
        _showErrorSnackbar(msg);
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Failed to upload image: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildProfilePicture(UserModel user) {
    final hasImage = kIsWeb ? _webImageBytes != null : _selectedImage != null;
    final photoUrl = user.photoUrl;
    final hasPhotoUrl = photoUrl != null && photoUrl.isNotEmpty;

    return CircleAvatar(
      radius: 60,
      backgroundColor: AppColors.background,
      backgroundImage: hasImage
          ? (kIsWeb
                ? MemoryImage(_webImageBytes!) as ImageProvider
                : FileImage(_selectedImage!) as ImageProvider)
          : (hasPhotoUrl ? NetworkImage(photoUrl) as ImageProvider : null),
      child: !hasImage && !hasPhotoUrl
          ? Icon(Icons.person, size: 60, color: textSecondary)
          : null,
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Update Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Camera Option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt, color: greenAccent),
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Use your camera to take a new photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),

              // Gallery Option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library, color: orangeAccent),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Select a photo from your device'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImagePreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Preview Profile Picture',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedImage = null;
                            _webImageBytes = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Image Preview
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: kIsWeb && _webImageBytes != null
                          ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                          : _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: backgroundLight,
                                  child: const Icon(
                                    Icons.error_outline,
                                    size: 50,
                                    color: Colors.red,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: backgroundLight,
                              child: const Icon(
                                Icons.error_outline,
                                size: 50,
                                color: Colors.red,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (_isUploading)
                    const CircularProgressIndicator(color: AppColors.primary)
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Choose Different'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _uploadProfilePicture,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text('Upload & Save'),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedImage = null;
                          _webImageBytes = null;
                        });
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor1,
    Color iconColor2,
    Color backgroundLight,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [iconColor1, iconColor2]),
            boxShadow: [
              BoxShadow(
                color: iconColor1.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // Debug check when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      final user = authService.currentUserModel;
      if (user != null) {
        if (kDebugMode) {
        }
      } else {
        if (kDebugMode) {
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUserModel;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'You are not logged in',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    // Get display name or fallback
    final displayName = user.displayName?.isNotEmpty == true
        ? user.displayName
        : user.email.split('@')[0];

    // Check if user is provider
    final isProvider = user.role == UserRole.provider;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
        ),
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [orangeAccent, greenAccent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              onPressed: () async {
                await authService.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture with Camera/Gallery
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [greenAccent, orangeAccent.withOpacity(0.5)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: _buildProfilePicture(user),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [orangeAccent, greenAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isUploading ? Icons.cloud_upload : Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Display Name
            Text(
              displayName!,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Email
            Text(
              user.email,
              style: TextStyle(fontSize: 16, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isProvider
                      ? [orangeAccent, greenAccent]
                      : [greenAccent, orangeAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                user.role.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Profile Details Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.phoneNumber != null &&
                      user.phoneNumber!.isNotEmpty) ...[
                    _buildInfoRow(
                      Icons.phone_outlined,
                      'Phone',
                      user.phoneNumber!,
                      greenAccent,
                      orangeAccent,
                      backgroundLight,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: borderColor, height: 1),
                    ),
                  ],
                  if (user.city != null && user.city!.isNotEmpty) ...[
                    _buildInfoRow(
                      Icons.location_city_outlined,
                      'City',
                      user.city!,
                      orangeAccent,
                      greenAccent,
                      backgroundLight,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: borderColor, height: 1),
                    ),
                  ],
                  if (user.address != null && user.address!.isNotEmpty) ...[
                    _buildInfoRow(
                      Icons.home_outlined,
                      'Address',
                      user.address!,
                      greenAccent,
                      orangeAccent,
                      backgroundLight,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: borderColor, height: 1),
                    ),
                  ],
                  if (isProvider) ...[
                    if (user.tradingName != null &&
                        user.tradingName!.isNotEmpty) ...[
                      _buildInfoRow(
                        Icons.business_outlined,
                        'Trading Name',
                        user.tradingName!,
                        orangeAccent,
                        greenAccent,
                        backgroundLight,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: borderColor, height: 1),
                      ),
                    ],
                    if (user.category != null && user.category!.isNotEmpty) ...[
                      _buildInfoRow(
                        Icons.category_outlined,
                        'Category',
                        user.category!,
                        greenAccent,
                        orangeAccent,
                        backgroundLight,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: borderColor, height: 1),
                      ),
                    ],
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      _buildInfoRow(
                        Icons.description_outlined,
                        'Bio',
                        user.bio!,
                        orangeAccent,
                        greenAccent,
                        backgroundLight,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: borderColor, height: 1),
                      ),
                    ],
                    if (user.basePrice != null) ...[
                      _buildInfoRow(
                        Icons.attach_money,
                        'Base Price',
                        'K${user.basePrice!.toStringAsFixed(2)}',
                        greenAccent,
                        orangeAccent,
                        backgroundLight,
                      ),
                    ],
                  ],

                  // Show message if no profile info
                  if (user.phoneNumber?.isEmpty != false &&
                      user.city?.isEmpty != false &&
                      user.address?.isEmpty != false &&
                      (!isProvider ||
                          (user.tradingName?.isEmpty != false &&
                              user.category?.isEmpty != false &&
                              user.bio?.isEmpty != false &&
                              user.basePrice == null))) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No profile information yet',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Edit Profile" to add your details',
                              style: TextStyle(
                                color: textSecondary.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Edit Profile Button
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
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/profile/edit');
                },
                icon: const Icon(Icons.edit, size: 20, color: Colors.white),
                label: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Provider-specific button
            if (isProvider) ...[
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push('/services');
                  },
                  icon: Icon(Icons.room_service, size: 20, color: orangeAccent),
                  label: Text(
                    'My Services',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Sign out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: authService.signOut,
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Danger zone — account deletion
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _confirmDeleteAccount,
                icon: const Icon(Icons.delete_forever_outlined, size: 20),
                label: const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              ' Deletes your Sangaso account immediately. Requires your password to confirm.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var understood = false;
    bool busy = false;
    String? errorText;
    final authService = context.read<AuthService>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          void setBusy(bool value) => setDialogState(() => busy = value);

          Future<void> onDelete() async {
            if (!(formKey.currentState?.validate() ?? false)) return;
            if (!understood) {
              setDialogState(() =>
                  errorText = 'Please confirm you understand this is permanent.');
              return;
            }
            setBusy(true);
            try {
              final result =
                  await context.read<AccountDeletionService>().deleteAccount(
                        password: passwordController.text,
                      );
              setDialogState(() => busy = false);
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              if (result.summary == 'DELETED_WITH_REMNANTS') {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Account deleted. Some message and booking history will be removed from our servers soon.'),
                    backgroundColor: AppColors.charcoal,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } on FirebaseAuthException catch (e) {
              setBusy(false);
              setDialogState(() {
                errorText = switch (e.code) {
                  'invalid-credential' ||
                  'wrong-password' ||
                  'user-not-found' =>
                    'Incorrect password. Please try again.',
                  'too-many-requests' =>
                    'Too many attempts. Please wait a moment and try again.',
                  'network-request-failed' =>
                    'Network problem. Please check your connection.',
                  _ => 'Your account could not be deleted right now. '
                      'Please try again later.',
                };
              });
            } catch (_) {
              setBusy(false);
              setDialogState(() =>
                  errorText = 'Your account could not be deleted right now. '
                      'Please try again later.');
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Delete Account',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This permanently deletes your Sangaso account and profile '
                    "right now. It cannot be undone. Your service listings "
                    'will be removed.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Enter your password' : null,
                    decoration: InputDecoration(
                      labelText: 'Confirm your password',
                      labelStyle: const TextStyle(fontSize: 14),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      filled: true,
                      fillColor: AppColors.primaryDim,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  CheckboxListTile(
                    value: understood,
                    activeColor: AppColors.error,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'I understand this is permanent',
                      style: TextStyle(fontSize: 13),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        understood = value ?? false;
                        errorText = null;
                      });
                    },
                  ),
                  if (errorText != null)
                    Text(
                      errorText!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.error, height: 1.4),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: busy ? null : onDelete,
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Delete Account'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && mounted) {
      await authService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been deleted.'),
            backgroundColor: AppColors.charcoal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/login');
      }
    }
  }
}
