import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/review_model.dart';

abstract class ReviewService {
  Future<void> addReview({
    required String bookingId,
    required String seekerId,
    required String providerId,
    required double rating,
    required String comment,
  });
  Stream<List<ReviewModel>> getReviewsForProvider(String providerId);
  Future<double> getAverageRating(String providerId);
}

class FirebaseReviewService implements ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  @override
  Future<void> addReview({
    required String bookingId,
    required String seekerId,
    required String providerId,
    required double rating,
    required String comment,
  }) async {
    // Prevent duplicate reviews for the same booking (e.g. accidental
    // double-tap on Submit, or reopening the review dialog).
    final existing = await _firestore
        .collection('reviews')
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('You have already reviewed this booking.');
    }

    final id = _uuid.v4();
    final review = ReviewModel(
      id: id,
      bookingId: bookingId,
      seekerId: seekerId,
      providerId: providerId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('reviews').doc(id).set(review.toMap());
  }

  @override
  Future<double> getAverageRating(String providerId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('providerId', isEqualTo: providerId)
        .get();
    if (snapshot.docs.isEmpty) return 0.0;
    final total = snapshot.docs.fold<double>(
      0.0,
      (sum, doc) => sum + ((doc.data()['rating'] as num?)?.toDouble() ?? 0.0),
    );
    return total / snapshot.docs.length;
  }

  @override
  Stream<List<ReviewModel>> getReviewsForProvider(String providerId) {
    return _firestore
        .collection('reviews')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) {
      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    });
  }
}
