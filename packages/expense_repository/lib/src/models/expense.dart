import 'package:expense_repository/expense_repository.dart';

class Expense {
  String expenseId;
  Category category;
  DateTime date;
  int amount;
  String? description;
  String type;

  Expense({
    required this.expenseId,
    required this.category,
    required this.date,
    required this.amount,
    this.description,
    required this.type,
  });

  static final empty = Expense(
    expenseId: '',
    category: Category.empty,
    date: DateTime.now(),
    amount: 0,
    description: '',
    type: 'expense',
  );

  ExpenseEntity toEntity() {
    return ExpenseEntity(
      expenseId: expenseId,
      category: category,
      date: date,
      amount: amount,
      description: description,
      type: type,
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
    );
  }
}
