import 'package:flutter/material.dart';
import 'package:expense_repository/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  Future<void> fetchExpenses(ExpenseRepository repo) async {
    _expenses = await repo.getExpenses();
    notifyListeners();
  }

  void setExpenses(List<Expense> expenses) {
    _expenses = expenses;
    notifyListeners();
  }
}

