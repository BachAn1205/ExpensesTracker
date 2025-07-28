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

  // Tạo categories mặc định cho user mới
  Future<void> createDefaultCategories() async {
    if (currentUserId == null) throw Exception('User not logged in.');
    
    // Kiểm tra xem user đã có categories chưa
    final existingCategories = await _firestore.collection('categories')
        .where('userId', isEqualTo: currentUserId)
        .get();
    
    if (existingCategories.docs.isNotEmpty) return; // Đã có categories
    
    // Tạo categories mặc định
    final defaultCategories = [
      {'name': 'Ăn uống', 'type': 'expense', 'icon': 'restaurant', 'color': 0xFFFF5722},
      {'name': 'Di chuyển', 'type': 'expense', 'icon': 'directions_car', 'color': 0xFF2196F3},
      {'name': 'Mua sắm', 'type': 'expense', 'icon': 'shopping_cart', 'color': 0xFF9C27B0},
      {'name': 'Giải trí', 'type': 'expense', 'icon': 'movie', 'color': 0xFFFF9800},
      {'name': 'Sức khỏe', 'type': 'expense', 'icon': 'local_hospital', 'color': 0xFF4CAF50},
      {'name': 'Giáo dục', 'type': 'expense', 'icon': 'school', 'color': 0xFF607D8B},
      {'name': 'Lương', 'type': 'income', 'icon': 'account_balance_wallet', 'color': 0xFF4CAF50},
      {'name': 'Thưởng', 'type': 'income', 'icon': 'card_giftcard', 'color': 0xFFFF9800},
      {'name': 'Đầu tư', 'type': 'income', 'icon': 'trending_up', 'color': 0xFF2196F3},
    ];
    
    for (final category in defaultCategories) {
      await addCategory(
        category['name'] as String,
        category['type'] as String,
        category['icon'] as String,
        category['color'] as int,
        isDefault: true,
      );
    }
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
  Future<String> addWallet(String name, double initialBalance, String currency) async {
    if (currentUserId == null) throw Exception('User not logged in.');
    final walletDocRef = _firestore.collection('wallets').doc();
    await walletDocRef.set({
      'walletId': walletDocRef.id,
      'userId': currentUserId,
      'name': name,
      'balance': initialBalance,
      'currency': currency,
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

  Future<void> deleteWallet(String walletId) async {
    if (currentUserId == null) throw Exception('User not logged in.');
    await _firestore.collection('wallets').doc(walletId).delete();
  }

  // 4. TRANSACTION OPERATIONS
  Future<String> addTransaction({
    required String categoryId,
    required double amount,
    required String type, // 'income' or 'expense'
    required DateTime date,
    String? walletId,
    String? description,
    String currency = 'VND',
  }) async {
    if (currentUserId == null) throw Exception('User not logged in.');
    
    try {
      // Lấy thông tin category
      final categoryDoc = await _firestore.collection('categories').doc(categoryId).get();
      if (!categoryDoc.exists) throw Exception('Category not found!');
      final categoryData = categoryDoc.data()!;
      
      // Lấy thông tin wallet nếu có
      Map<String, dynamic>? walletData;
      if (walletId != null) {
        final walletDoc = await _firestore.collection('wallets').doc(walletId).get();
        if (!walletDoc.exists) throw Exception('Wallet not found!');
        walletData = walletDoc.data()!;
      }
      
      // Tạo transaction document
      final transactionDocRef = _firestore.collection('transactions').doc();
      await transactionDocRef.set({
        'transactionId': transactionDocRef.id,
        'userId': currentUserId,
        'categoryId': categoryId,
        'walletId': walletId,
        'amount': amount.toDouble(), // Đảm bảo amount là double
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
        'currency': currency,
      });
      
      // Cập nhật wallet balance nếu có (riêng biệt để tránh lỗi transaction)
      if (walletId != null) {
        try {
          final walletRef = _firestore.collection('wallets').doc(walletId);
          final currentWalletDoc = await walletRef.get();
          if (currentWalletDoc.exists) {
            final currentBalance = (currentWalletDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
            final newBalance = (type == 'income') ? (currentBalance + amount) : (currentBalance - amount);
            await walletRef.update({'balance': newBalance, 'updatedAt': FieldValue.serverTimestamp()});
          }
        } catch (e) {
          print('Warning: Could not update wallet balance: $e');
        }
      }
      
      // Cập nhật budget nếu là expense (riêng biệt để tránh lỗi index)
      if (type == 'expense') {
        try {
          // Lấy tất cả budgets của user và category này
          final budgetsQuery = await _firestore.collection('budgets')
              .where('userId', isEqualTo: currentUserId)
              .where('categoryId', isEqualTo: categoryId)
              .get();
          
          final transactionDate = Timestamp.fromDate(date);
          
          for (var budgetDoc in budgetsQuery.docs) {
            final budgetData = budgetDoc.data();
            final startDate = budgetData['startDate'] as Timestamp?;
            final endDate = budgetData['endDate'] as Timestamp?;
            final budgetWalletId = budgetData['walletId'] as String?;
            
            // Kiểm tra xem transaction có trong khoảng thời gian của budget không
            if (startDate != null && endDate != null) {
              if (transactionDate.compareTo(startDate) >= 0 && transactionDate.compareTo(endDate) <= 0) {
                // Kiểm tra xem budget có áp dụng cho ví cụ thể hay không
                bool shouldUpdateBudget = false;
                
                if (budgetWalletId == null) {
                  // Budget áp dụng cho tất cả ví
                  shouldUpdateBudget = true;
                } else if (walletId != null && budgetWalletId == walletId) {
                  // Budget áp dụng cho ví cụ thể và transaction thuộc ví đó
                  shouldUpdateBudget = true;
                }
                
                if (shouldUpdateBudget) {
                  final budgetRef = _firestore.collection('budgets').doc(budgetDoc.id);
                  final currentBudgetDoc = await budgetRef.get();
                  if (currentBudgetDoc.exists) {
                    final currentSpentAmount = (currentBudgetDoc.data()?['spentAmount'] as num?)?.toDouble() ?? 0.0;
                    final newSpentAmount = currentSpentAmount + amount;
                    await budgetRef.update({'spentAmount': newSpentAmount, 'updatedAt': FieldValue.serverTimestamp()});
                  }
                }
              }
            }
          }
        } catch (e) {
          print('Warning: Could not update budget: $e');
        }
      }
      
      return transactionDocRef.id;
    } catch (e) {
      print('Error in addTransaction: $e');
      rethrow;
    }
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
  Future<void> addBudget({
    required String categoryId,
    String? walletId, // Thêm walletId (tùy chọn)
    required double limit,
    required String currency,
    required DateTime startDate,
    required DateTime endDate,
    double initialSpentAmount = 0.0, // Thêm số tiền đã chi ban đầu
  }) async {
    if (currentUserId == null) throw Exception('User not logged in.');
    final budgetDocRef = _firestore.collection('budgets').doc();
    await budgetDocRef.set({
      'budgetId': budgetDocRef.id,
      'userId': currentUserId,
      'categoryId': categoryId,
      'walletId': walletId, // Thêm walletId
      'limit': limit,
      'currency': currency,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'spentAmount': initialSpentAmount, // Sử dụng số tiền đã chi ban đầu
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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

