import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isEditing;

  const ProfileSetupScreen({super.key, this.isEditing = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  // Provider specific
  final _tradingNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _bioController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isLoading = false;
  UserModel? _currentUser;

  // Use the same colors as BookingDetailsScreen
  // Colors from AppColors
  
  
  
  
  
  
  
  
  
  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUser();
    });
  }

  Future<void> _loadUser() async {
    try {
      final authService = context.read<AuthService>();
      final user = authService.currentUserModel;

      if (mounted) {
        setState(() => _currentUser = user);

        // Pre-fill existing data if editing
        if (user != null) {
          _displayNameController.text = user.displayName ?? '';
          _phoneController.text = user.phoneNumber ?? '';
          _cityController.text = user.city ?? '';
          _addressController.text = user.address ?? '';

          if (user.role == UserRole.provider) {
            _tradingNameController.text = user.tradingName ?? '';
            _categoryController.text = user.category ?? '';
            _bioController.text = user.bio ?? '';
            _priceController.text = user.basePrice?.toStringAsFixed(2) ?? '';
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _tradingNameController.dispose();
    _categoryController.dispose();
    _bioController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Use copyWith to update only the changed fields
      final updatedUser = _currentUser!.copyWith(
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        tradingName: _currentUser!.role == UserRole.provider
            ? (_tradingNameController.text.trim().isEmpty
            ? null
            : _tradingNameController.text.trim())
            : null,
        category: _currentUser!.role == UserRole.provider
            ? (_categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim())
            : null,
        bio: _currentUser!.role == UserRole.provider
            ? (_bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim())
            : null,
        basePrice: _currentUser!.role == UserRole.provider
            ? (_priceController.text.trim().isEmpty
            ? null
            : double.tryParse(_priceController.text.trim()))
            : null,
        updatedAt: DateTime.now(),
      );

      // Use the updateUserProfile method from your AuthService
      await context.read<AuthService>().updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Profile updated successfully!'
                  : 'Profile completed!',
            ),
            backgroundColor: AppColors.primary,
          ),
        );

        if (widget.isEditing) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (kDebugMode) {
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final isProvider = _currentUser!.role == UserRole.provider;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Profile' : 'Complete Profile',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.accent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        leading: widget.isEditing
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isProvider ? Icons.business : Icons.person,
                        color: AppColors.accent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEditing
                                ? 'Edit Your Profile'
                                : 'Complete Your Profile',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fill in your details below',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Display Name
              _buildInputField(
                label: 'Display Name',
                icon: Icons.person,
                controller: _displayNameController,
                hintText: 'Enter your display name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Display name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              _buildInputField(
                label: 'Phone Number',
                icon: Icons.phone,
                controller: _phoneController,
                hintText: 'Enter your phone number',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  if (!RegExp(r'^[0-9+\-\s]{10,}$').hasMatch(value)) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // City
              _buildInputField(
                label: 'City / Area',
                icon: Icons.location_city,
                controller: _cityController,
                hintText: 'Enter your city or area',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'City is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              _buildInputField(
                label: 'Default Address',
                icon: Icons.home,
                controller: _addressController,
                hintText: 'Enter your complete address',
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),

              // Provider-specific fields
              if (isProvider) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.work_outline, color: AppColors.accent, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Service Provider Details',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill in your business details to attract more customers',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Trading Name
                _buildInputField(
                  label: 'Trading Name',
                  icon: Icons.business,
                  controller: _tradingNameController,
                  hintText: 'e.g., John\'s Plumbing Services',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Trading name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category
                _buildInputField(
                  label: 'Service Category',
                  icon: Icons.category,
                  controller: _categoryController,
                  hintText: 'e.g., Plumbing, Electrical, Cleaning',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Category is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Base Price
                _buildInputField(
                  label: 'Base Price (K)',
                  icon: Icons.attach_money,
                  controller: _priceController,
                  hintText: 'e.g., 50.00',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Base price is required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Bio
                _buildInputField(
                  label: 'Bio / Description',
                  icon: Icons.description,
                  controller: _bioController,
                  hintText: 'Describe your services and experience',
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bio is required';
                    }
                    if (value.length < 20) {
                      return 'Please provide a more detailed description (min. 20 characters)';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isEditing ? AppColors.primary : AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isEditing ? Icons.save : Icons.check_circle,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.isEditing ? 'Save Changes' : 'Save & Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Skip button for initial setup (not for editing)
              if (!widget.isEditing) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/home'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: AppColors.accentLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.accent,
                width: 2,
              ),
            ),
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 12 : 0,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}