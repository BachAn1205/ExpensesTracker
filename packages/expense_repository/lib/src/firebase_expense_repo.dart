import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_repository/expense_repository.dart';
import 'entities/entities.dart';
import 'models/models.dart';

class FirebaseExpenseRepo implements ExpenseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  String get currentUserId => _auth.currentUser?.uid ?? '';

  @override
  Future<void> createCategory(Category category) async {
    try {
      if (currentUserId == null) throw Exception('User not logged in.');
      
      print('Creating category with userId: $currentUserId');
      await _firestore
        .collection('categories')
        .doc(category.categoryId)
        .set({
          ...category.toEntity().toDocument(),
          'userId': currentUserId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Category>> getCategories() async {
    try {
      if (currentUserId == null) {
        print('No current user, returning empty category list');
        return [];
      }
      
      print('Fetching categories for userId: $currentUserId');
      return await _firestore
        .collection('categories')
        .where('userId', isEqualTo: currentUserId)
        .get()
        .then((value) {
          print('Found ${value.docs.length} categories');
          return value.docs.map((e) => 
            Category.fromEntity(CategoryEntity.fromDocument(e.data()))
          ).toList();
        });
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> createExpense(Expense expense) async {
    try {
      if (currentUserId == null) throw Exception('User not logged in.');
      
      print('Creating expense with userId: $currentUserId');
      await _firestore
        .collection('transactions')
        .doc(expense.expenseId)
        .set({
          ...expense.toEntity().toDocument(),
          'userId': currentUserId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Expense>> getExpenses() async {
    try {
      if (currentUserId == null) {
        print('No current user, returning empty expense list');
        return [];
      }
      
      print('Fetching expenses for userId: $currentUserId');
      final querySnapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('date', descending: true)
        .get();
      
      print('Found ${querySnapshot.docs.length} expenses in Firestore');
      
      final expenses = <Expense>[];
      for (final doc in querySnapshot.docs) {
        try {
          print('Processing document: ${doc.id}');
          print('Document data: ${doc.data()}');
          
          final expense = Expense.fromEntity(ExpenseEntity.fromDocument(doc.data()));
          expenses.add(expense);
          print('Successfully created expense: ${expense.expenseId} - ${expense.category.name} - ${expense.amount}');
        } catch (e) {
          print('Error processing document ${doc.id}: $e');
          print('Document data: ${doc.data()}');
        }
      }
      
      print('Successfully processed ${expenses.length} expenses');
      return expenses;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  // Wallet methods
  Future<List<Wallet>> getWallets() async {
    try {
      print('Fetching wallets for user: $currentUserId');
      final querySnapshot = await _firestore
          .collection('wallets')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      final wallets = querySnapshot.docs.map((doc) {
        print('Processing wallet document: ${doc.id}');
        final data = doc.data();
        print('Wallet data: $data');
        return WalletEntity.fromDocument(doc).toWallet();
      }).toList();

      print('Successfully fetched ${wallets.length} wallets');
      return wallets;
    } catch (e) {
      log('Error fetching wallets: $e');
      rethrow;
    }
  }

  Future<void> createWallet(Wallet wallet) async {
    try {
      print('Creating wallet: ${wallet.name}');
      final walletEntity = WalletEntity(
        walletId: wallet.walletId,
        userId: currentUserId,
        name: wallet.name,
        balance: wallet.balance,
        currency: wallet.currency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('wallets')
          .doc(wallet.walletId)
          .set(walletEntity.toDocument());

      print('Successfully created wallet: ${wallet.name}');
    } catch (e) {
      log('Error creating wallet: $e');
      rethrow;
    }
  }

  Future<void> updateWallet(Wallet wallet) async {
    try {
      print('Updating wallet: ${wallet.name}');
      final walletEntity = WalletEntity(
        walletId: wallet.walletId,
        userId: currentUserId,
        name: wallet.name,
        balance: wallet.balance,
        currency: wallet.currency,
        createdAt: wallet.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('wallets')
          .doc(wallet.walletId)
          .update(walletEntity.toDocument());

      print('Successfully updated wallet: ${wallet.name}');
    } catch (e) {
      log('Error updating wallet: $e');
      rethrow;
    }
  }

  Future<void> deleteWallet(String walletId) async {
    try {
      print('Deleting wallet: $walletId');
      await _firestore.collection('wallets').doc(walletId).delete();
      print('Successfully deleted wallet: $walletId');
    } catch (e) {
      log('Error deleting wallet: $e');
      rethrow;
    }
  }
}