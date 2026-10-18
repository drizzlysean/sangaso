// lib/src/models/user_model.dart
import 'firestore_date.dart';

enum UserRole { seeker, provider, admin }

class UserModel {
  final String id;
  final String email;
  final UserRole role;
  final bool isVerified;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final String? city;
  final String? address;
  // Provider specific
  final String? tradingName;
  final String? category;
  final String? bio;
  final double? basePrice;
  // Onboarding: how the user heard about Sangaso (backward-compatible
  // nullable extension; absent in older documents).
  final String? heardAbout;
  // Admin moderation fields
  final bool isBanned;
  final bool isSuspended;
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.isVerified = false,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.city,
    this.address,
    this.tradingName,
    this.category,
    this.bio,
    this.basePrice,
    this.heardAbout,
    this.isBanned = false,
    this.isSuspended = false,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role.name,
      'isVerified': isVerified,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'city': city,
      'address': address,
      'tradingName': tradingName,
      'category': category,
      'bio': bio,
      'basePrice': basePrice,
      'heardAbout': heardAbout,
      'isBanned': isBanned,
      'isSuspended': isSuspended,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.seeker,
      ),
      isVerified: map['isVerified'] ?? false,
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      city: map['city'],
      address: map['address'],
      tradingName: map['tradingName'],
      category: map['category'],
      bio: map['bio'],
      basePrice: (map['basePrice'] as num?)?.toDouble(),
      heardAbout: map['heardAbout'],
      isBanned: map['isBanned'] ?? false,
      isSuspended: map['isSuspended'] ?? false,
      createdAt: parseFirestoreDateOrNull(map['createdAt'], field: 'createdAt'),
      updatedAt: parseFirestoreDateOrNull(map['updatedAt'], field: 'updatedAt'),
    );
  }

  // copyWith method for easy updates
  UserModel copyWith({
    String? id,
    String? email,
    UserRole? role,
    bool? isVerified,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? city,
    String? address,
    String? tradingName,
    String? category,
    String? bio,
    double? basePrice,
    String? heardAbout,
    bool? isBanned,
    bool? isSuspended,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      city: city ?? this.city,
      address: address ?? this.address,
      tradingName: tradingName ?? this.tradingName,
      category: category ?? this.category,
      bio: bio ?? this.bio,
      basePrice: basePrice ?? this.basePrice,
      heardAbout: heardAbout ?? this.heardAbout,
      isBanned: isBanned ?? this.isBanned,
      isSuspended: isSuspended ?? this.isSuspended,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
