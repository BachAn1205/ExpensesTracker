import 'package:flutter/foundation.dart';
import 'package:expense_repository/expense_repository.dart';

class WalletProvider extends ChangeNotifier {
  List<Wallet> _wallets = [];
  bool _isLoading = false;
  String? _error;

  List<Wallet> get wallets => _wallets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWallets(ExpenseRepository repository) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('WalletProvider: Fetching wallets...');
      _wallets = await repository.getWallets();
      print('WalletProvider: Fetched ${_wallets.length} wallets');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('WalletProvider: Error fetching wallets: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWallet(ExpenseRepository repository, Wallet wallet) async {
    try {
      print('WalletProvider: Adding wallet: ${wallet.name}');
      await repository.createWallet(wallet);
      await fetchWallets(repository);
    } catch (e) {
      print('WalletProvider: Error adding wallet: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateWallet(ExpenseRepository repository, Wallet wallet) async {
    try {
      print('WalletProvider: Updating wallet: ${wallet.name}');
      await repository.updateWallet(wallet);
      await fetchWallets(repository);
    } catch (e) {
      print('WalletProvider: Error updating wallet: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteWallet(ExpenseRepository repository, String walletId) async {
    try {
      print('WalletProvider: Deleting wallet: $walletId');
      await repository.deleteWallet(walletId);
      await fetchWallets(repository);
    } catch (e) {
      print('WalletProvider: Error deleting wallet: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearWallets() {
    _wallets = [];
    _error = null;
    notifyListeners();
  }

  Wallet? getWalletById(String walletId) {
    try {
      return _wallets.firstWhere((wallet) => wallet.walletId == walletId);
    } catch (e) {
      return null;
    }
  }
} 