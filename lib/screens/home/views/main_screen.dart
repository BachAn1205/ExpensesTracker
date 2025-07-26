import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../services/currency_service.dart';
import '../../../screens/settings/blocs/currency_bloc/currency_bloc.dart';
import '../../../screens/settings/blocs/currency_bloc/currency_state.dart';
import '../providers/expense_provider.dart';
import 'account_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final Color bgColor = const Color(0xFF1E6F5C);

  // Thêm các biến để kiểm soát giao diện động
  bool showTransactions = false;
  bool showBudgets = false;

  String? userName;
  String? photoUrl; // Đã thêm để có thể hiển thị ảnh đại diện

  // Sử dụng một List<dynamic> để tránh lỗi khi expenseProvider trả về null ban đầu
  // và để tương thích hơn với dữ liệu từ repository
  List<Expense> get expenses => Provider.of<ExpenseProvider>(context).expenses;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    // Lắng nghe thay đổi người dùng để cập nhật UI
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _fetchUserData();
      }
    });
    // Lắng nghe thay đổi trong tài liệu người dùng Firestore để cập nhật tên/ảnh ngay lập tức
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        setState(() {
          userName = doc.data()?['name'] ?? userName;
          photoUrl = doc.data()?['photoUrl'] ?? photoUrl;
        });
      }
    });
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        setState(() {
          // Ưu tiên dữ liệu từ Firestore, sau đó đến Firebase Auth, cuối cùng là 'User'
          userName = doc.data()?['name'] ?? user.displayName ?? 'Người dùng';
          photoUrl = doc.data()?['photoUrl'] ?? user.photoURL;
        });
      } catch (e) {
        print('Error fetching user data from Firestore: $e');
        setState(() {
          userName = user.displayName ?? 'Người dùng';
          photoUrl = user.photoURL;
        });
      }
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.zoom_in),
              title: const Text('Xem ảnh đại diện'),
              onTap: () {
                Navigator.pop(context);
                if (photoUrl != null && photoUrl!.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: InteractiveViewer(
                        child: Image.network(
                          photoUrl!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không có ảnh đại diện để xem.')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Sửa ảnh đại diện'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/settings/edit_profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                // Điều hướng về màn hình đăng nhập hoặc màn hình chính
                Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalBalance = expenses.fold(0, (sum, e) => sum + (e.type == 'income' ? e.amount : -e.amount));
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('Tổng số dư', style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(Icons.more_vert, color: Colors.white),
          )
        ],
      ),
      body: showTransactions
          ? _buildTransactionsList(context)
          : showBudgets
              ? _buildBudgetsView(context)
              : _selectedIndex == 4
                  ? AccountScreen()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                          child: Text(
                            '${totalBalance.toStringAsFixed(0)} đ',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                            ),
                            child: ListView(
                              padding: const EdgeInsets.only(top: 20),
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.bar_chart, color: Colors.orange),
                                  title: const Text('Biểu đồ tổng'),
                                  trailing: Text(
                                    '${totalBalance.toStringAsFixed(0)} đ',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.receipt, color: Colors.blue),
                                  title: const Text('Tổng chi tiêu'),
                                  trailing: Text(
                                    '${expenses.where((e) => e.type == 'expense').fold(0, (sum, e) => sum + e.amount).toStringAsFixed(0)} đ',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.refresh, color: Colors.green),
                                  title: const Text('Giao dịch gần nhất'),
                                  trailing: Text(
                                    expenses.isNotEmpty ?
                                      '${expenses.last.amount} đ' : '0 đ',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.history, color: Colors.grey),
                                  title: const Text('Thanh toán gần nhất'),
                                  trailing: Text(
                                    expenses.isNotEmpty ?
                                      '${expenses.first.amount} đ' : '0 đ',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            showTransactions = false;
            showBudgets = false;
            // Xoá điều hướng sang trang khác, chỉ set _selectedIndex
            _selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          const BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Sổ giao dịch'),
          BottomNavigationBarItem(
            icon: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            label: '',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Ngân sách'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ giao dịch'),
        backgroundColor: bgColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              showTransactions = false;
              _selectedIndex = 0;
            });
          },
        ),
      ),
      body: ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, i) {
          final e = expenses[i];
          return ListTile(
            leading: Icon(Icons.monetization_on, color: e.type == 'income' ? Colors.green : Colors.red),
            title: Text(e.category.name),
            subtitle: Text(e.description ?? ''),
            trailing: Text(
              (e.type == 'income' ? '+ ' : '- ') + e.amount.toString() + ' đ',
              style: TextStyle(color: e.type == 'income' ? Colors.green : Colors.red),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBudgetsView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ngân sách'),
        backgroundColor: bgColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              showBudgets = false;
              _selectedIndex = 0;
            });
          },
        ),
      ),
      body: Center(
        child: Text('Giao diện quản lý ngân sách', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
