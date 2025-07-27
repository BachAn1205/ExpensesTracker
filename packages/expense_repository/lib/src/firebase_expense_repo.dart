import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_repository/expense_repository.dart';

class FirebaseExpenseRepo implements ExpenseRepository {
  final categoryCollection = FirebaseFirestore.instance.collection('categories');
	final expenseCollection = FirebaseFirestore.instance.collection('transactions'); // Đổi thành transactions
	final FirebaseAuth _auth = FirebaseAuth.instance;

	String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<void> createCategory(Category category) async {
    try {
      if (currentUserId == null) throw Exception('User not logged in.');
      
      print('Creating category with userId: $currentUserId');
      await categoryCollection
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
  Future<List<Category>> getCategory() async {
    try {
      if (currentUserId == null) {
        print('No current user, returning empty category list');
        return [];
      }
      
      print('Fetching categories for userId: $currentUserId');
      return await categoryCollection
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
      await expenseCollection
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
      final querySnapshot = await expenseCollection
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

}