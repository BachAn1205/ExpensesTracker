import 'package:expense_repository/expense_repository.dart';

class Expense {
  String expenseId;
  Category category;
  DateTime date;
  int amount;
  String? description;
  String type;
  String? walletId; // Thêm trường walletId
  String? currency; // Thêm trường currency

  Expense({
    required this.expenseId,
    required this.category,
    required this.date,
    required this.amount,
    this.description,
    required this.type,
    this.walletId, // Thêm tham số walletId
    this.currency, // Thêm tham số currency
  });

  static final empty = Expense(
    expenseId: '',
    category: Category.empty,
    date: DateTime.now(),
    amount: 0,
    description: '',
    type: 'expense',
    walletId: null, // Thêm walletId cho empty
    currency: 'VND', // Thêm currency cho empty
  );

  ExpenseEntity toEntity() {
    return ExpenseEntity(
      expenseId: expenseId,
      category: category,
      date: date,
      amount: amount,
      description: description,
      type: type,
      walletId: walletId, // Thêm walletId
      currency: currency, // Thêm currency
    );
  }

  static Expense fromEntity(ExpenseEntity entity) {
    return Expense(
      expenseId: entity.expenseId,
      category: entity.category,
      date: entity.date,
      amount: entity.amount,
      description: entity.description,
      type: entity.type,
      walletId: entity.walletId, // Thêm walletId
      currency: entity.currency, // Thêm currency
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expenseId': expenseId,
      'category': category.toMap(),
      'date': date.toIso8601String(),
      'amount': amount,
      'description': description,
      'type': type,
      'walletId': walletId, // Thêm walletId
      'currency': currency, // Thêm currency
    };
  }

  static Expense fromMap(Map<String, dynamic> map) {
    return Expense(
      expenseId: map['expenseId'] ?? '',
      category: Category.fromMap(map['category'] ?? {}),
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      amount: map['amount'] ?? 0,
      description: map['description'] ?? '',
      type: map['type'] ?? 'expense',
      walletId: map['walletId'], // Thêm walletId
      currency: map['currency'] ?? 'VND', // Thêm currency với giá trị mặc định
    );
  }
}
