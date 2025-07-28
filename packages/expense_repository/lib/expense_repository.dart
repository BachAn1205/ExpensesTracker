library expense_repository;

export 'src/entities/entities.dart';
export 'src/models/models.dart';
export 'src/expense_repo.dart';
export 'src/firebase_expense_repo.dart';

import 'src/models/category.dart';
import 'src/models/expense.dart';
import 'src/models/wallet.dart';

abstract class ExpenseRepository {
  Future<List<Category>> getCategories();
  Future<void> createCategory(Category category);
  Future<List<Expense>> getExpenses();
  Future<void> createExpense(Expense expense);
  Future<List<Wallet>> getWallets();
  Future<void> createWallet(Wallet wallet);
  Future<void> updateWallet(Wallet wallet);
  Future<void> deleteWallet(String walletId);
}