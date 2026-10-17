import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_date.dart';

class MessageModel {
  final String id;
  final String bookingId;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      bookingId: map['bookingId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      timestamp: parseFirestoreDate(map['timestamp'], field: 'timestamp'),
      isRead: map['isRead'] ?? false,
    );
  }
}
