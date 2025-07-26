import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // 1. USER OPERATIONS
  Future<void> createUserProfile(User userAuth) async {
    final userDocRef = _firestore.collection('users').doc(userAuth.uid);
    await userDocRef.set({
      'userId': userAuth.uid,
      'email': userAuth.email ?? '',
      'name': userAuth.displayName ?? 'Người dùng mới',
      'photoUrl': userAuth.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot> getUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // 2. CATEGORY OPERATIONS
  Future<String> addCategory(String name, String type, String? icon, int? color, {bool isDefault = false}) async {
    if (currentUserId == null) throw Exception('User not logged in.');
    final categoryDocRef = _firestore.collection('categories').doc();
    await categoryDocRef.set({
      'categoryId': categoryDocRef.id,
      'userId': currentUserId,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return categoryDocRef.id;
  }

  Stream<List<Map<String, dynamic>>> getCategories() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore.collection('categories')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('name', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // 3. WALLET OPERATIONS
  Future<String> addWallet(String name, double initialBalance, String type, String currency, String? icon, int? color) async {
    if (currentUserId == null) throw Exception('User not logged in.');
    final walletDocRef = _firestore.collection('wallets').doc();
    await walletDocRef.set({
      'walletId': walletDocRef.id,
      'userId': currentUserId,
      'name': name,
      'balance': initialBalance,
      'type': type,
      'currency': currency,
      'icon': icon,
      'color': color,
      'description': null,
      'initialBalance': initialBalance,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return walletDocRef.id;
  }

  Stream<List<Map<String, dynamic>>> getWallets() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore.collection('wallets')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('name', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // 4. TRANSACTION OPERATIONS
  Future<String> addTransaction({
    required String categoryId,
    required double amount,
    required String type, // 'income' or 'expense'
    required DateTime date,
    String? walletId,
    String? description,
  }) async {
    if (currentUserId == null) throw Exception('User not logged in.');
    final categoryDoc = await _firestore.collection('categories').doc(categoryId).get();
    if (!categoryDoc.exists) throw Exception('Category not found!');
    final categoryData = categoryDoc.data()!;
    Map<String, dynamic>? walletData;
    if (walletId != null) {
      final walletDoc = await _firestore.collection('wallets').doc(walletId).get();
      if (!walletDoc.exists) throw Exception('Wallet not found!');
      walletData = walletDoc.data()!;
    }
    return await _firestore.runTransaction<String>((transaction) async {
      final transactionDocRef = _firestore.collection('transactions').doc();
      transaction.set(transactionDocRef, {
        'transactionId': transactionDocRef.id,
        'userId': currentUserId,
        'categoryId': categoryId,
        'walletId': walletId,
        'amount': amount,
        'type': type,
        'description': description,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'categoryName': categoryData['name'],
        'categoryIcon': categoryData['icon'],
        'categoryColor': categoryData['color'],
        'walletName': walletData?['name'],
        'walletType': walletData?['type'],
      });
      if (walletId != null) {
        final walletRef = _firestore.collection('wallets').doc(walletId);
        final currentWalletSnapshot = await transaction.get(walletRef);
        final currentBalance = (currentWalletSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;
        final newBalance = (type == 'income') ? (currentBalance + amount) : (currentBalance - amount);
        transaction.update(walletRef, {'balance': newBalance, 'updatedAt': FieldValue.serverTimestamp()});
      }
      if (type == 'expense') {
        final budgetsQuery = await _firestore.collection('budgets')
            .where('userId', isEqualTo: currentUserId)
            .where('categoryId', isEqualTo: categoryId)
            .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(date))
            .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
            .get();
        for (var budgetDoc in budgetsQuery.docs) {
          final budgetRef = _firestore.collection('budgets').doc(budgetDoc.id);
          final currentBudgetSnapshot = await transaction.get(budgetRef);
          final currentSpentAmount = (currentBudgetSnapshot.data()?['spentAmount'] as num?)?.toDouble() ?? 0.0;
          final newSpentAmount = currentSpentAmount + amount;
          transaction.update(budgetRef, {'spentAmount': newSpentAmount, 'updatedAt': FieldValue.serverTimestamp()});
        }
      }
      return transactionDocRef.id;
    });
  }

  Stream<List<Map<String, dynamic>>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) {
    if (currentUserId == null) return Stream.value([]);
    return _firestore.collection('transactions')
        .where('userId', isEqualTo: currentUserId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // 5. BUDGET OPERATIONS
  Future<String> addBudget({
    required String categoryId,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (currentUserId == null) throw Exception('User not logged in.');
    final categoryDoc = await _firestore.collection('categories').doc(categoryId).get();
    if (!categoryDoc.exists) throw Exception('Category not found!');
    final categoryData = categoryDoc.data()!;
    final budgetDocRef = _firestore.collection('budgets').doc();
    await budgetDocRef.set({
      'budgetId': budgetDocRef.id,
      'userId': currentUserId,
      'categoryId': categoryId,
      'amount': amount,
      'spentAmount': 0.0,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'categoryName': categoryData['name'],
      'categoryIcon': categoryData['icon'],
      'categoryColor': categoryData['color'],
    });
    return budgetDocRef.id;
  }

  Stream<List<Map<String, dynamic>>> getBudgets() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore.collection('budgets')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}

