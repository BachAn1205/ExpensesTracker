import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../services/currency_service.dart';
import '../providers/expense_provider.dart';
import 'account_screen.dart';
import '../../add_expense/views/add_transaction_screen.dart'; // Import màn hình thêm giao dịch mới
import '../../settings/providers/currency_provider.dart';

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
  bool showAddExpense = false;

  String? userName;
  String? photoUrl; // Đã thêm để có thể hiển thị ảnh đại diện

  // Sử dụng một List<dynamic> để tránh lỗi khi expenseProvider trả về null ban đầu
  // và để tương thích hơn với dữ liệu từ repository
  List<Expense> get expenses => Provider.of<ExpenseProvider>(context).expenses;

  int? _addTransactionTabIndex; // Lưu index tab khi mở giao diện thêm giao dịch

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    // Lắng nghe thay đổi người dùng để cập nhật UI
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        print('User changed in MainScreen: ${user.uid}');
        _fetchUserData();
        // Tự động fetch expenses khi user đăng nhập
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
          expenseProvider.refreshExpenses();
        });
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
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: bgColor,
              elevation: 0,
              title: const Text('Tổng số dư', style: TextStyle(color: Colors.white)),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(Icons.more_vert, color: Colors.white),
                )
              ],
            )
          : null,
      body: (_addTransactionTabIndex == _selectedIndex && _addTransactionTabIndex != null)
          ? AddTransactionScreen(
              onClose: () {
                setState(() {
                  _addTransactionTabIndex = null;
                  // Khi đóng, luôn chuyển về tab Sổ giao dịch
                  _selectedIndex = 1;
                  showTransactions = true;
                });
              },
            )
          : showTransactions
              ? _buildTransactionsList(context)
              : showBudgets
                  ? _buildBudgetsView(context)
                  : _selectedIndex == 4
                      ? AccountScreen()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedIndex == 0)
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
        selectedItemColor: Theme.of(context).colorScheme.primary, // Màu khi item được chọn
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant, // Màu khi item không được chọn
        onTap: (index) {
          setState(() {
            showTransactions = false;
            showBudgets = false;
            _selectedIndex = index; // Cập nhật index đã chọn

            // Nếu người dùng nhấn vào tab "Thêm Giao dịch" (index 2)
            if (index == 2) {
              // Mở màn hình thêm giao dịch
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
              ).then((_) {
                // Sau khi màn hình thêm giao dịch đóng, chúng ta có thể chuyển về tab Sổ giao dịch (index 1)
                // Hoặc giữ nguyên tab hiện tại nếu đó không phải tab thêm giao dịch
                setState(() {
                  if (_selectedIndex == 2) { // Chỉ thay đổi nếu vẫn ở tab thêm giao dịch
                    _selectedIndex = 1; // Chuyển về tab Sổ giao dịch
                    showTransactions = true; // Đảm bảo hiển thị danh sách giao dịch
                  }
                });
              });
            } else if (index == 1) { // Nếu bấm vào tab Sổ giao dịch (index == 1)
              showTransactions = true;
            } else if (index == 3) { // Nếu bấm vào tab Ngân sách (index == 3)
              showBudgets = true;
            }
          });
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          const BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Sổ giao dịch'),
          // Tab "Thêm Giao dịch" đã chỉnh sửa
          // Tab "Thêm Giao dịch"
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_circle, // Icon thêm giao dịch
              size: 30,
              // Đổi màu icon thành màu xanh cố định hoặc xanh của primary color
              color: _selectedIndex == 2 ? Theme.of(context).colorScheme.primary : Colors.blue.shade600, // Hoặc chỉ Colors.blue
            ),
            label: 'Thêm', // Nhãn cho tab
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Ngân sách'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),

    );
  }

  Widget _buildTransactionsList(BuildContext context) {
    final expenses = Provider.of<ExpenseProvider>(context).expenses;
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final currency = Provider.of<CurrencyProvider>(context).currency;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // Đảm bảo nền là màu trắng
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề danh sách và nút tùy chọn (đã di chuyển lên trên)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Tăng vertical padding một chút
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tất cả Giao dịch', // Tiêu đề
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.sort_rounded, size: 28, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    onPressed: () {
                      // Logic sắp xếp hoặc bộ lọc
                    },
                  ),
                ],
              ),
            ),
            // Thanh tìm kiếm (đã di chuyển xuống dưới)
            Container(
              color: Theme.of(context).colorScheme.background, // Nền search bar trùng với nền màn hình
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Chỉ padding ngang
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Tìm kiếm giao dịch...',
                          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          prefixIcon: Icon(Icons.search, size: 24, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        ),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16), // Khoảng cách giữa search bar và danh sách

            // Danh sách giao dịch (giữ nguyên)
            Expanded(
              child: expenseProvider.isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Đang tải giao dịch...',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : expenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có giao dịch nào.',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Thêm giao dịch đầu tiên của bạn!',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: expenses.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final e = expenses[i];
                            final isIncome = e.type == 'income';

                            Color iconBgColor;
                            IconData iconData;

                            if (e.category.name.toLowerCase().contains('settings')) {
                              iconBgColor = Colors.orange.shade100;
                              iconData = Icons.settings;
                            } else if (e.category.name.toLowerCase().contains('refund')) {
                              iconBgColor = Colors.blue.shade100;
                              iconData = Icons.refresh;
                            } else if (e.type == 'income') {
                              iconBgColor = Theme.of(context).colorScheme.tertiary.withOpacity(0.1);
                              iconData = Icons.arrow_upward_rounded;
                            } else { // expense
                              iconBgColor = Theme.of(context).colorScheme.error.withOpacity(0.1);
                              iconData = Icons.arrow_downward_rounded;
                            }

                            return Card(
                              elevation: 1.5,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: iconBgColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(iconData, color: Color(e.category.color), size: 28),
                                ),
                                title: Text(
                                  e.category.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: (e.description != null && e.description!.isNotEmpty)
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          e.description!,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      )
                                    : null,
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyService.formatCurrency(
                                        CurrencyService.convertFromVND(
                                          double.parse(e.amount.toString()),
                                          currency
                                        ),
                                        currency
                                      ),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isIncome
                                            ? Theme.of(context).colorScheme.tertiary
                                            : Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}/${e.date.year}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
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
