import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  requested,
  accepted,
  declined,
  inProgress,
  completed,
  cancelled,
}

class BookingModel {
  final String id;
  final String seekerId;
  final String providerId;
  final String serviceType;
  final DateTime scheduledTime;
  final String address;
  final double price;
  final BookingStatus status;
  final DateTime createdAt;

  // Denormalized seeker information for quick access
  final String? seekerName;
  final String? seekerPhone;
  final String? seekerEmail;

  // Denormalized provider information for quick access
  final String? providerName;
  final String? providerPhone;
  final String? providerEmail;

  // Additional booking details
  final String? specialInstructions;

  // Status tracking
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  BookingModel({
    required this.id,
    required this.seekerId,
    required this.providerId,
    required this.serviceType,
    required this.scheduledTime,
    required this.address,
    required this.price,
    required this.status,
    required this.createdAt,
    this.seekerName,
    this.seekerPhone,
    this.seekerEmail,
    this.providerName,
    this.providerPhone,
    this.providerEmail,
    this.specialInstructions,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seekerId': seekerId,
      'providerId': providerId,
      'serviceType': serviceType,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'address': address,
      'price': price,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'seekerName': seekerName,
      'seekerPhone': seekerPhone,
      'seekerEmail': seekerEmail,
      'providerName': providerName,
      'providerPhone': providerPhone,
      'providerEmail': providerEmail,
      'specialInstructions': specialInstructions,
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      seekerId: map['seekerId'] ?? '',
      providerId: map['providerId'] ?? '',
      serviceType: map['serviceType'] ?? '',
      scheduledTime: (map['scheduledTime'] as Timestamp).toDate(),
      address: map['address'] ?? '',
      price: (map['price'] as num).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.requested,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      seekerName: map['seekerName'],
      seekerPhone: map['seekerPhone'],
      seekerEmail: map['seekerEmail'],
      providerName: map['providerName'],
      providerPhone: map['providerPhone'],
      providerEmail: map['providerEmail'],
      specialInstructions: map['specialInstructions'],
      acceptedAt: map['acceptedAt'] != null
          ? (map['acceptedAt'] as Timestamp).toDate()
          : null,
      startedAt: map['startedAt'] != null
          ? (map['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Null get bookingDate => null;
}
