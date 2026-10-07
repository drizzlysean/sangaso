import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/booking_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users with optional role filter
  Stream<List<UserModel>> getAllUsers({UserRole? roleFilter}) {
    Query query = _firestore.collection('users');
    
    if (roleFilter != null) {
      query = query.where('role', isEqualTo: roleFilter.name);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Update user status (ban, suspend, activate)
  Future<void> updateUserStatus(String userId, {
    bool? isBanned,
    bool? isSuspended,
    bool? isVerified,
  }) async {
    final updateData = <String, dynamic>{};
    
    if (isBanned != null) updateData['isBanned'] = isBanned;
    if (isSuspended != null) updateData['isSuspended'] = isSuspended;
    if (isVerified != null) updateData['isVerified'] = isVerified;
    
    if (updateData.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update(updateData);
    }
  }

  // Get all bookings
  Stream<List<BookingModel>> getAllBookings({BookingStatus? statusFilter}) {
    Query query = _firestore.collection('bookings');
    
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.name);
    }
    
    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get platform statistics
  Future<Map<String, dynamic>> getPlatformStats() async {
    try {
      // Get user counts
      final usersSnapshot = await _firestore.collection('users').get();
      final providers = usersSnapshot.docs.where((doc) => doc.data()['role'] == 'provider').length;
      final seekers = usersSnapshot.docs.where((doc) => doc.data()['role'] == 'seeker').length;
      final verifiedProviders = usersSnapshot.docs.where((doc) => 
        doc.data()['role'] == 'provider' && doc.data()['isVerified'] == true
      ).length;
      
      // Get booking counts
      final bookingsSnapshot = await _firestore.collection('bookings').get();
      final totalBookings = bookingsSnapshot.docs.length;
      final completedBookings = bookingsSnapshot.docs.where((doc) => 
        doc.data()['status'] == 'completed'
      ).length;
      final activeBookings = bookingsSnapshot.docs.where((doc) => 
        doc.data()['status'] == 'inProgress'
      ).length;
      
      // Calculate total revenue (from completed bookings)
      double totalRevenue = 0;
      for (var doc in bookingsSnapshot.docs) {
        if (doc.data()['status'] == 'completed') {
          totalRevenue += (doc.data()['price'] as num).toDouble();
        }
      }
      
      return {
        'totalUsers': usersSnapshot.docs.length,
        'providers': providers,
        'seekers': seekers,
        'verifiedProviders': verifiedProviders,
        'pendingKYC': providers - verifiedProviders,
        'totalBookings': totalBookings,
        'completedBookings': completedBookings,
        'activeBookings': activeBookings,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      return {};
    }
  }

  // Reject KYC with reason
  Future<void> rejectKYC(String userId, String reason) async {
    await _firestore.collection('users').doc(userId).update({
      'isVerified': false,
      'kycRejectionReason': reason,
      'kycRejectedAt': FieldValue.serverTimestamp(),
    });
  }

  // Approve KYC
  Future<void> approveKYC(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isVerified': true,
      'kycRejectionReason': FieldValue.delete(),
      'kycRejectedAt': FieldValue.delete(),
      'kycApprovedAt': FieldValue.serverTimestamp(),
    });
  }

  // Search users by name or email
  Future<List<UserModel>> searchUsers(String query) async {
    final snapshot = await _firestore.collection('users').get();
    
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .where((user) {
          final searchQuery = query.toLowerCase();
          final displayName = user.displayName?.toLowerCase() ?? '';
          final email = user.email.toLowerCase();
          final tradingName = user.tradingName?.toLowerCase() ?? '';
          
          return displayName.contains(searchQuery) ||
                 email.contains(searchQuery) ||
                 tradingName.contains(searchQuery);
        })
        .toList();
  }
}
