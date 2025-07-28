import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_repository/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ExpenseProvider() {
    // Lắng nghe thay đổi user để tự động fetch expenses
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        // User đã đăng nhập, fetch expenses
        print('User logged in, fetching expenses for user: ${user.uid}');
        // Đợi một chút để đảm bảo Firebase Auth đã sẵn sàng
        Future.delayed(const Duration(milliseconds: 500), () {
          fetchExpenses(FirebaseExpenseRepo());
        });
      } else {
        // User đã đăng xuất, clear expenses
        print('User logged out, clearing expenses');
        _expenses = [];
        notifyListeners();
      }
    });
  }

  Future<void> fetchExpenses(ExpenseRepository repo) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      print('Fetching expenses from repository...');
      final fetchedExpenses = await repo.getExpenses();
      print('Repository returned ${fetchedExpenses.length} expenses');
      
      _expenses = fetchedExpenses;
      print('Updated _expenses list with ${_expenses.length} items');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error fetching expenses: $e');
    }
  }

  void setExpenses(List<Expense> expenses) {
    _expenses = expenses;
    notifyListeners();
  }

  void addExpense(Expense expense) {
    _expenses.insert(0, expense); // Thêm vào đầu danh sách
    notifyListeners();
  }

  void removeExpense(String expenseId) {
    _expenses.removeWhere((expense) => expense.expenseId == expenseId);
    notifyListeners();
  }

  // Phương thức để force refresh dữ liệu
  Future<void> refreshExpenses() async {
    print('Force refreshing expenses...');
    await fetchExpenses(FirebaseExpenseRepo());
  }
}

