import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet.dart';

class WalletEntity {
  final String walletId;
  final String userId;
  final String name;
  final double balance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletEntity({
    required this.walletId,
    required this.userId,
    required this.name,
    required this.balance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toDocument() {
    return {
      'walletId': walletId,
      'userId': userId,
      'name': name,
      'balance': balance,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory WalletEntity.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletEntity(
      walletId: data['walletId'] ?? '',
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'VND',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Wallet toWallet() {
    return Wallet(
      walletId: walletId,
      userId: userId,
      name: name,
      balance: balance,
      currency: currency,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
} 