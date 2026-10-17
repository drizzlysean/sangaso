import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/service_model.dart';

class ServiceService {
  ServiceService({FirebaseFirestore? firestore}) : _override = firestore;

  final FirebaseFirestore? _override;

  FirebaseFirestore get _firestore => _override ?? FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Create a new service
  Future<void> createService(ServiceModel service) async {
    final newService = service.copyWith(
      id: service.id.isEmpty ? _uuid.v4() : service.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _firestore
        .collection('services')
        .doc(newService.id)
        .set(newService.toMap());
  }

  // Update an existing service
  Future<void> updateService(ServiceModel service) async {
    final updatedService = service.copyWith(
      updatedAt: DateTime.now(),
    );
    
    await _firestore
        .collection('services')
        .doc(service.id)
        .update(updatedService.toMap());
  }

  // Delete a service
  Future<void> deleteService(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).delete();
  }

  // Get all services for a specific provider
  Stream<List<ServiceModel>> getProviderServices(String providerId) {
    return _firestore
        .collection('services')
        .where('providerId', isEqualTo: providerId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Get a single service by ID
  Future<ServiceModel?> getService(String serviceId) async {
    final doc = await _firestore.collection('services').doc(serviceId).get();
    if (doc.exists) {
      return ServiceModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Get services by category
  Stream<List<ServiceModel>> getServicesByCategory(String category) {
    return _firestore
        .collection('services')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Get all active services
  Stream<List<ServiceModel>> getAllServices() {
    return _firestore
        .collection('services')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Toggle service active status
  Future<void> toggleServiceStatus(String serviceId, bool isActive) async {
    await _firestore.collection('services').doc(serviceId).update({
      'isActive': isActive,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
