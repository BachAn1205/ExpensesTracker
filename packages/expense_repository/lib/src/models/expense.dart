import 'package:expense_repository/expense_repository.dart';

class Expense {
  String expenseId;
  Category category;
  DateTime date;
  int amount;

  Expense({
    required this.expenseId,
    required this.category,
    required this.date,
    required this.amount,
  });

  static final empty = Expense(
    expenseId: '',
    category: Category.empty,
    date: DateTime.now(),
    amount: 0,
  );

  ExpenseEntity toEntity() {
    return ExpenseEntity(
      expenseId: expenseId,
      category: category,
      date: date,
      amount: amount,
    );
  }

  static Expense fromEntity(ExpenseEntity entity) {
    return Expense(
      expenseId: entity.expenseId,
      category: entity.category,
      date: entity.date,
      amount: entity.amount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expenseId': expenseId,
      'category': category.toMap(),
      'date': date.toIso8601String(),
      'amount': amount,
    };
  }

  static Expense fromMap(Map<String, dynamic> map) {
    return Expense(
      expenseId: map['expenseId'] ?? '',
      category: Category.fromMap(map['category'] ?? {}),
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      amount: map['amount'] ?? 0,
    );
  }
}