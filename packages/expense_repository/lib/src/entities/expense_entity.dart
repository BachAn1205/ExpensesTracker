import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';

class ExpenseEntity {
  final String expenseId;
  final Category category;
  final DateTime date;
  final int amount;
  final String? description;
  final String type;

  ExpenseEntity({
    required this.expenseId,
    required this.category,
    required this.date,
    required this.amount,
    this.description,
    required this.type,
  });

  Map<String, Object?> toDocument() {
    return {
      'transactionId': expenseId, // Đổi thành transactionId để phù hợp với transactions collection
      'categoryId': category.categoryId,
      'categoryName': category.name,
      'categoryIcon': category.icon,
      'categoryColor': category.color,
      'date': date,
      'amount': amount.toDouble(), // Đảm bảo amount là double
      'description': description,
      'type': type,
    };
  }

  static ExpenseEntity fromDocument(Map<String, dynamic> doc) {
    // Tạo Category từ dữ liệu trong transaction
    final category = Category(
      categoryId: doc['categoryId'] ?? '',
      name: doc['categoryName'] ?? '',
      totalExpenses: 0,
      icon: doc['categoryIcon'] ?? '',
      color: doc['categoryColor'] ?? 0xFF000000,
    );

    // Xử lý amount - có thể là double hoặc int
    int amount;
    if (doc['amount'] is double) {
      amount = (doc['amount'] as double).toInt();
    } else if (doc['amount'] is int) {
      amount = doc['amount'] as int;
    } else {
      amount = 0;
    }

    return ExpenseEntity(
      expenseId: doc['transactionId'] ?? doc['expenseId'] ?? '', // Hỗ trợ cả transactionId và expenseId
      category: category,
      date: (doc['date'] as Timestamp).toDate(),
      amount: amount,
      description: doc['description'] ?? '',
      type: doc['type'] ?? 'expense',
    );
  }
}