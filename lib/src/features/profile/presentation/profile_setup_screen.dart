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
  static const int _totalSteps = 3;

  // Field keys: used to validate only the fields on the current step.
  final _nameKey = GlobalKey<FormFieldState<String>>();
  final _phoneKey = GlobalKey<FormFieldState<String>>();
  final _cityKey = GlobalKey<FormFieldState<String>>();
  final _addressKey = GlobalKey<FormFieldState<String>>();
  final _tradingKey = GlobalKey<FormFieldState<String>>();
  final _categoryKey = GlobalKey<FormFieldState<String>>();
  final _priceKey = GlobalKey<FormFieldState<String>>();
  final _bioKey = GlobalKey<FormFieldState<String>>();
  final _heardOtherKey = GlobalKey<FormFieldState<String>>();

  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  // Provider specific
  final _tradingNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _bioController = TextEditingController();
  final _priceController = TextEditingController();

  // Seeker onboarding
  static const _heardOptions = [
    'Friend or family',
    'Social media',
    'Google search',
    'Play Store',
    'Community board',
    'Other',
  ];
  String? _heardAbout;
  final _heardOtherController = TextEditingController();
  String? _heardError;

  int _step = 0;
  bool _isLoading = false;
  UserModel? _currentUser;

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
          } else {
            _heardAbout = user.heardAbout;
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
    _heardOtherController.dispose();
    super.dispose();
  }

  bool get _isProvider => _currentUser?.role == UserRole.provider;

  List<GlobalKey<FormFieldState<String>>> _stepFieldKeys() {
    switch (_step) {
      case 0:
        return [_nameKey, _phoneKey];
      case 1:
        return [_cityKey, _addressKey];
      case 2:
        if (_isProvider) {
          return [_tradingKey, _categoryKey, _priceKey, _bioKey];
        }
        return _heardAbout == 'Other' ? [_heardOtherKey] : const [];
      default:
        return const [];
    }
  }

  bool _validateStep() {
    var ok = true;
    for (final key in _stepFieldKeys()) {
      if (!key.currentState!.validate()) ok = false;
    }
    if (_step == 2 && !_isProvider && _heardAbout == null) {
      setState(() => _heardError = 'Please choose how you heard about Sangaso');
      ok = false;
    }
    return ok;
  }

  void _continue() {
    if (!_validateStep()) return;
    if (_step < _totalSteps - 1) {
      setState(() {
        _step++;
      });
      return;
    }
    _saveProfile();
  }

  void _back() {
    if (_step == 0) {
      if (widget.isEditing) context.pop();
      return;
    }
    setState(() => _step--);
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;
    if (!_validateStep()) return;

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
        heardAbout: _currentUser!.role == UserRole.provider
            ? null
            : (_heardAbout == 'Other'
                ? (_heardOtherController.text.trim().isEmpty
                    ? 'Other'
                    : 'Other: ${_heardOtherController.text.trim()}')
                : _heardAbout),
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
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildStepContent(),
              ),
            ),
            _buildNavBar(),
          ],
        ),
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 0:
        return 'About you';
      case 1:
        return 'Your area';
      case 2:
        return _isProvider ? 'Your business' : 'About Sangaso';
      default:
        return '';
    }
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (!widget.isEditing) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: _step == 0 ? null : _back,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step ${_step + 1} of $_totalSteps  -  $_stepTitle',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(_totalSteps, (i) {
                    final active = i <= _step;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: active ? AppColors.accent : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _isProvider ? _buildProviderStep() : _buildHeardStep();
    }
    return const SizedBox.shrink();
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputField(
          label: 'Display Name',
          icon: Icons.person,
          controller: _displayNameController,
          hintText: 'Enter your display name',
          fieldKey: _nameKey,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Display name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Phone Number',
          icon: Icons.phone,
          controller: _phoneController,
          hintText: 'Enter your phone number',
          keyboardType: TextInputType.phone,
          fieldKey: _phoneKey,
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
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputField(
          label: 'City / Area',
          icon: Icons.location_city,
          controller: _cityController,
          hintText: 'Enter your city or area',
          fieldKey: _cityKey,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'City is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Default Address',
          icon: Icons.home,
          controller: _addressController,
          hintText: 'Enter your complete address',
          maxLines: 2,
          fieldKey: _addressKey,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Address is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProviderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.work_outline, color: AppColors.accent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Fill in your business details to attract more customers',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildInputField(
          label: 'Trading Name',
          icon: Icons.business,
          controller: _tradingNameController,
          hintText: 'e.g., John\'s Plumbing Services',
          fieldKey: _tradingKey,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Trading name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Service Category',
          icon: Icons.category,
          controller: _categoryController,
          hintText: 'e.g., Plumbing, Electrical, Cleaning',
          fieldKey: _categoryKey,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Category is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Base Price (K)',
          icon: Icons.attach_money,
          controller: _priceController,
          hintText: 'e.g., 50.00',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          fieldKey: _priceKey,
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
        _buildInputField(
          label: 'Bio / Description',
          icon: Icons.description,
          controller: _bioController,
          hintText: 'Describe your services and experience',
          maxLines: 4,
          fieldKey: _bioKey,
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
    );
  }

  Widget _buildHeardStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How did you hear about Sangaso?',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your answer helps us spread the word.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ..._heardOptions.map((option) => RadioListTile<String>(
              value: option,
              groupValue: _heardAbout,
              onChanged: (v) {
                setState(() {
                  _heardAbout = v;
                  _heardError = null;
                });
              },
              title: Text(option,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textPrimary)),
              activeColor: AppColors.accent,
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
        if (_heardError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _heardError!,
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        if (_heardAbout == 'Other') ...[
          const SizedBox(height: 8),
          _buildInputField(
            label: 'Tell us more (optional)',
            icon: Icons.edit,
            controller: _heardOtherController,
            hintText: 'e.g., saw a flyer',
            fieldKey: _heardOtherKey,
            validator: null,
          ),
        ],
      ],
    );
  }

  Widget _buildNavBar() {
    final isLast = _step == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_step > 0 || widget.isEditing) ...[
              OutlinedButton(
                onPressed: _isLoading ? null : _back,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_step == 0 ? 'Cancel' : 'Back',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      widget.isEditing ? AppColors.primary : AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                      isLast
                          ? (widget.isEditing ? Icons.save : Icons.check_circle)
                          : Icons.arrow_forward,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isLast
                          ? (widget.isEditing ? 'Save Changes' : 'Save & Continue')
                          : 'Continue',
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
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?)? validator,
    GlobalKey<FormFieldState<String>>? fieldKey,
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
          key: fieldKey,
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
