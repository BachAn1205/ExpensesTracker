import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:expense_repository/expense_repository.dart';
import 'firestore_service.dart';

class FirestoreTestWidget extends StatefulWidget {
  const FirestoreTestWidget({super.key});

  @override
  State<FirestoreTestWidget> createState() => _FirestoreTestWidgetState();
}

class _FirestoreTestWidgetState extends State<FirestoreTestWidget> {
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      _currentUserId = user?.uid;

      if (user != null) {
        print('Loading data for user: ${user.uid}');
        
        // Load transactions
        final firestoreService = FirestoreService();
        final transactionsStream = firestoreService.getTransactionsByDateRange(
          DateTime.now().subtract(const Duration(days: 30)),
          DateTime.now(),
        );
        
        await for (final transactions in transactionsStream) {
          setState(() {
            _transactions = transactions;
          });
        }

        // Load categories
        final categoriesStream = firestoreService.getCategories();
        await for (final categories in categoriesStream) {
          setState(() {
            _categories = categories;
          });
        }
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current User ID: ${_currentUserId ?? 'Not logged in'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    'Categories (${_categories.length}):',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._categories.map((category) => Card(
                    child: ListTile(
                      title: Text(category['name'] ?? 'No name'),
                      subtitle: Text('Type: ${category['type']} | UserId: ${category['userId']}'),
                    ),
                  )),
                  
                  const SizedBox(height: 20),
                  Text(
                    'Transactions (${_transactions.length}):',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._transactions.map((transaction) => Card(
                    child: ListTile(
                      title: Text('${transaction['categoryName']} - ${transaction['amount']}'),
                      subtitle: Text('Type: ${transaction['type']} | UserId: ${transaction['userId']} | Date: ${transaction['date']}'),
                    ),
                  )),
                ],
              ),
            ),
    );
  }
}

