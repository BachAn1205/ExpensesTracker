import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../services/currency_service.dart';
import '../../../services/firestore_service.dart';
import '../providers/expense_provider.dart';
import '../providers/wallet_provider.dart';
import 'account_screen.dart';
import '../../add_expense/views/add_transaction_screen.dart'; // Import màn hình thêm giao dịch mới
import '../../settings/providers/currency_provider.dart';
import 'add_budget_bottom_sheet.dart';
import '../../add_expense/providers/category_provider.dart';
import 'wallet_list_screen.dart';

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
  String? _selectedWalletFilter; // Thêm biến lọc theo ví
  String? _selectedBudgetWalletFilter; // Thêm biến lọc ngân sách theo ví
  
  // Thêm các biến cho tìm kiếm
  String _searchQuery = '';
  String? _selectedCategoryFilter;
  String? _selectedTypeFilter; // 'income' hoặc 'expense'
  DateTime? _selectedDateFilter;
  double? _minAmountFilter;
  double? _maxAmountFilter;
  bool _showSearchFilters = false;

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
        // Tự động fetch expenses và wallets khi user đăng nhập
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
          final walletProvider = Provider.of<WalletProvider>(context, listen: false);
          final repo = FirebaseExpenseRepo();
          expenseProvider.refreshExpenses();
          walletProvider.fetchWallets(repo);
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
    
    // Fetch wallets khi component được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final repo = FirebaseExpenseRepo();
      walletProvider.fetchWallets(repo);
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



  Widget _buildHomeScreen(BuildContext context, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tổng số dư từ các ví
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService().getWallets(),
          builder: (context, snapshot) {
            double totalWalletBalance = 0.0;
            List<Map<String, dynamic>> wallets = [];
            
            if (snapshot.hasData) {
              wallets = snapshot.data!;
              // Tính tổng số dư từ tất cả các ví (chuyển về VND)
              for (var wallet in wallets) {
                final balance = (wallet['balance'] ?? 0.0).toDouble();
                final walletCurrency = wallet['currency'] ?? 'VND';
                
                if (walletCurrency == 'VND') {
                  totalWalletBalance += balance;
                } else {
                  // Chuyển đổi về VND
                  totalWalletBalance += CurrencyService.convertToVND(balance, walletCurrency);
                }
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyService.formatCurrency(
                      CurrencyService.convertFromVND(totalWalletBalance, currency),
                      currency
                    ),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tổng số dư từ ${wallets.length} ví',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            );
          },
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
                // Danh sách 3 ví đầu tiên
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService().getWallets(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final wallets = snapshot.data ?? [];
                    if (wallets.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có ví nào',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Thêm ví đầu tiên để bắt đầu quản lý tài chính!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/wallet_list');
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm ví'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Hiển thị 3 ví đầu tiên
                    final displayWallets = wallets.take(3).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ví của tôi',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (wallets.length > 3)
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/wallet_list');
                                  },
                                  child: Text(
                                    'Xem tất cả (${wallets.length})',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ...displayWallets.map((wallet) => _buildWalletCard(wallet, currency)),
                        if (wallets.length > 3)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/wallet_list');
                                },
                                child: Text(
                                  'Xem thêm ${wallets.length - 3} ví khác',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
                // Các thống kê khác
                _buildStatisticsSection(currency),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCard(Map<String, dynamic> wallet, String currency) {
    final balance = (wallet['balance'] ?? 0.0).toDouble();
    final walletCurrency = wallet['currency'] ?? 'VND';
    final displayBalance = walletCurrency == 'VND' 
        ? CurrencyService.convertFromVND(balance, currency)
        : CurrencyService.convertFromVND(
            CurrencyService.convertToVND(balance, walletCurrency), 
            currency
          );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.account_balance_wallet,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          wallet['name'] ?? '',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${CurrencyService.formatCurrency(balance, walletCurrency)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          CurrencyService.formatCurrency(displayBalance, currency),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onTap: () {
          Navigator.pushNamed(context, '/wallet_list');
        },
      ),
    );
  }

  Widget _buildStatisticsSection(String currency) {
    double totalBalance = expenses.fold(0, (sum, e) => sum + (e.type == 'income' ? e.amount : -e.amount));
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Text(
            'Thống kê giao dịch',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.bar_chart, color: Colors.orange),
          title: const Text('Biểu đồ tổng'),
          trailing: Text(
            CurrencyService.formatCurrency(
              CurrencyService.convertFromVND(totalBalance.toDouble(), currency),
              currency
            ),
            style: const TextStyle(color: Colors.red),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.receipt, color: Colors.blue),
          title: const Text('Tổng chi tiêu'),
          trailing: Text(
            CurrencyService.formatCurrency(
              CurrencyService.convertFromVND(
                expenses.where((e) => e.type == 'expense').fold(0, (sum, e) => sum + e.amount).toDouble(),
                currency
              ),
              currency
            ),
            style: const TextStyle(color: Colors.red),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.refresh, color: Colors.green),
          title: const Text('Giao dịch gần nhất'),
          trailing: Text(
            expenses.isNotEmpty ?
              CurrencyService.formatCurrency(
                CurrencyService.convertFromVND(expenses.last.amount.toDouble(), currency),
                currency
              ) : CurrencyService.formatCurrency(0, currency),
            style: const TextStyle(color: Colors.green),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.history, color: Colors.grey),
          title: const Text('Thanh toán gần nhất'),
          trailing: Text(
            expenses.isNotEmpty ?
              CurrencyService.formatCurrency(
                CurrencyService.convertFromVND(expenses.first.amount.toDouble(), currency),
                currency
              ) : CurrencyService.formatCurrency(0, currency),
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = Provider.of<CurrencyProvider>(context).currency;
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
                      : _buildHomeScreen(context, currency),
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
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề danh sách và nút tùy chọn
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedWalletFilter != null ? 'Giao dịch của ví' : 'Tất cả Giao dịch',
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

            // Danh sách ví để chọn
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getWallets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final wallets = snapshot.data ?? [];
                if (wallets.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có ví nào',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Thêm ví để xem giao dịch!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Nút "Tất cả ví"
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedWalletFilter = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedWalletFilter == null 
                                ? Theme.of(context).colorScheme.primary 
                                : Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedWalletFilter == null 
                                  ? Theme.of(context).colorScheme.primary 
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: _selectedWalletFilter == null 
                                    ? Colors.white 
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Tất cả ví',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _selectedWalletFilter == null 
                                      ? Colors.white 
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: _selectedWalletFilter == null 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Dropdown chọn ví
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.6)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedWalletFilter,
                            isExpanded: true,
                            hint: Text(
                              'Chọn ví để xem giao dịch',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedWalletFilter = newValue;
                              });
                            },
                            items: wallets.map<DropdownMenuItem<String>>((wallet) {
                              final walletName = wallet['name'] ?? 'Không tên';
                              final balance = (wallet['balance'] ?? 0.0).toDouble();
                              final currency = wallet['currency'] ?? 'VND';
                              final formattedBalance = CurrencyService.formatCurrency(balance, currency);
                              
                              return DropdownMenuItem<String>(
                                value: wallet['walletId'],
                                child: Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(walletName),
                                          Text(
                                            formattedBalance,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Thanh tìm kiếm
            Container(
              color: Theme.of(context).colorScheme.background,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
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
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showSearchFilters = !_showSearchFilters;
                          });
                        },
                        icon: Icon(
                          _showSearchFilters ? Icons.filter_list : Icons.filter_list_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      IconButton(
                        onPressed: _resetAllFilters,
                        icon: Icon(
                          Icons.clear,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  
                  // Bộ lọc nâng cao
                  if (_showSearchFilters)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          // Lọc theo danh mục
                          Consumer<CategoryProvider>(
                            builder: (context, categoryProvider, child) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.6)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCategoryFilter,
                                    isExpanded: true,
                                    hint: Text(
                                      'Tất cả danh mục',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedCategoryFilter = newValue;
                                      });
                                    },
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('Tất cả danh mục'),
                                      ),
                                      ...categoryProvider.categories.map<DropdownMenuItem<String>>((category) {
                                        return DropdownMenuItem<String>(
                                          value: category.categoryId,
                                          child: Row(
                                            children: [
                                              Icon(Icons.category, color: Color(category.color)),
                                              const SizedBox(width: 8),
                                              Text(category.name),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          
                          // Lọc theo loại giao dịch
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.6)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedTypeFilter,
                                isExpanded: true,
                                hint: Text(
                                  'Tất cả loại giao dịch',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedTypeFilter = newValue;
                                  });
                                },
                                items: [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Tất cả loại giao dịch'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'income',
                                    child: Row(
                                      children: [
                                        Icon(Icons.arrow_upward, color: Colors.green),
                                        const SizedBox(width: 8),
                                        Text('Thu nhập'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'expense',
                                    child: Row(
                                      children: [
                                        Icon(Icons.arrow_downward, color: Colors.red),
                                        const SizedBox(width: 8),
                                        Text('Chi tiêu'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Lọc theo ngày
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDateFilter ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDateFilter = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.6)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedDateFilter != null
                                          ? '${_selectedDateFilter!.day}/${_selectedDateFilter!.month}/${_selectedDateFilter!.year}'
                                          : 'Chọn ngày',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: _selectedDateFilter != null
                                            ? Theme.of(context).colorScheme.onSurface
                                            : Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  if (_selectedDateFilter != null)
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedDateFilter = null;
                                        });
                                      },
                                      icon: Icon(Icons.clear, size: 16),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Lọc theo khoảng tiền
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _minAmountFilter = value.isNotEmpty ? double.tryParse(value) : null;
                                    });
                                  },
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Số tiền tối thiểu',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _maxAmountFilter = value.isNotEmpty ? double.tryParse(value) : null;
                                    });
                                  },
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Số tiền tối đa',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Danh sách giao dịch
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
                  : _getFilteredExpenses(expenses).isEmpty
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
                                _hasActiveFilters()
                                    ? 'Không tìm thấy giao dịch phù hợp.'
                                    : (_selectedWalletFilter != null 
                                        ? 'Không có giao dịch nào trong ví này.'
                                        : 'Chưa có giao dịch nào.'),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _hasActiveFilters()
                                    ? 'Thử thay đổi bộ lọc tìm kiếm.'
                                    : (_selectedWalletFilter != null 
                                        ? 'Thêm giao dịch cho ví này!'
                                        : 'Thêm giao dịch đầu tiên của bạn!'),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Thông tin kết quả tìm kiếm
                            if (_hasActiveFilters())
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Tìm thấy ${_getFilteredExpenses(expenses).length} giao dịch',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _resetAllFilters,
                                      child: Text(
                                        'Xóa bộ lọc',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Danh sách giao dịch
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _getFilteredExpenses(expenses).length,
                                separatorBuilder: (context, index) => const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final e = _getFilteredExpenses(expenses)[i];
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
                                      onTap: () => _showTransactionDetails(context, e),
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
                                            _formatTransactionAmount(e),
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
          ],
        ),
      ),
    );
  }

  // Thêm phương thức lọc giao dịch theo ví
  List<Expense> _getFilteredExpenses(List<Expense> allExpenses) {
    List<Expense> filteredExpenses = allExpenses;
    
    // Lọc theo ví
    if (_selectedWalletFilter != null) {
      filteredExpenses = filteredExpenses.where((expense) {
        return expense.walletId == _selectedWalletFilter;
      }).toList();
    }
    
    // Lọc theo từ khóa tìm kiếm
    if (_searchQuery.isNotEmpty) {
      filteredExpenses = filteredExpenses.where((expense) {
        final query = _searchQuery.toLowerCase();
        return expense.category.name.toLowerCase().contains(query) ||
               (expense.description?.toLowerCase().contains(query) ?? false) ||
               expense.amount.toString().contains(query);
      }).toList();
    }
    
    // Lọc theo danh mục
    if (_selectedCategoryFilter != null) {
      filteredExpenses = filteredExpenses.where((expense) {
        return expense.category.categoryId == _selectedCategoryFilter;
      }).toList();
    }
    
    // Lọc theo loại giao dịch
    if (_selectedTypeFilter != null) {
      filteredExpenses = filteredExpenses.where((expense) {
        return expense.type == _selectedTypeFilter;
      }).toList();
    }
    
    // Lọc theo ngày
    if (_selectedDateFilter != null) {
      filteredExpenses = filteredExpenses.where((expense) {
        return expense.date.year == _selectedDateFilter!.year &&
               expense.date.month == _selectedDateFilter!.month &&
               expense.date.day == _selectedDateFilter!.day;
      }).toList();
    }
    
    // Lọc theo khoảng tiền
    if (_minAmountFilter != null) {
      filteredExpenses = filteredExpenses.where((expense) {
        return expense.amount >= _minAmountFilter!;
      }).toList();
    }
    
    if (_maxAmountFilter != null) {
      filteredExpenses = filteredExpenses.where((expense) {
        return expense.amount <= _maxAmountFilter!;
      }).toList();
    }
    
    return filteredExpenses;
  }

  String _formatTransactionAmount(Expense expense) {
    final currency = expense.currency ?? 'VND';
    final amount = expense.amount.toDouble();
    return CurrencyService.formatCurrency(amount, currency);
  }

  void _resetAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategoryFilter = null;
      _selectedTypeFilter = null;
      _selectedDateFilter = null;
      _minAmountFilter = null;
      _maxAmountFilter = null;
      _showSearchFilters = false;
    });
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
           _selectedCategoryFilter != null ||
           _selectedTypeFilter != null ||
           _selectedDateFilter != null ||
           _minAmountFilter != null ||
           _maxAmountFilter != null;
  }

  Widget _buildBudgetsView(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);
    final categoryMap = {for (var c in categoryProvider.categories) c.categoryId: c.name};
    final walletMap = {for (var w in walletProvider.wallets) w.walletId: w.name};
    
    print('[BUDGET_VIEW] userId: ' + (userId ?? 'null'));
    print('[BUDGET_VIEW] categoryMap: ' + categoryMap.toString());
    
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const AddBudgetBottomSheet(),
              );
            },
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text('Vui lòng đăng nhập để xem ngân sách.'))
          : Column(
              children: [
                // Wallet filter
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Text('Lọc theo ví: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedBudgetWalletFilter,
                          hint: const Text('Tất cả ví'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Tất cả ví'),
                            ),
                            ...walletProvider.wallets.map((wallet) => DropdownMenuItem(
                              value: wallet.walletId,
                              child: Text('${wallet.name} (${wallet.currency})'),
                            )).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedBudgetWalletFilter = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('budgets')
                        .where('userId', isEqualTo: userId)
                        .orderBy('startDate', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      print('[BUDGET_VIEW] snapshot.connectionState: ' + snapshot.connectionState.toString());
                      print('[BUDGET_VIEW] snapshot.hasData: ' + snapshot.hasData.toString());
                      print('[BUDGET_VIEW] snapshot.data: ' + (snapshot.data?.docs.length.toString() ?? 'null'));
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        print('[BUDGET_VIEW] Không có ngân sách nào!');
                        return const Center(child: Text('Chưa có ngân sách nào.'));
                      }
                      
                      // Lọc budgets theo ví được chọn
                      List<QueryDocumentSnapshot> budgets = snapshot.data!.docs;
                      if (_selectedBudgetWalletFilter != null) {
                        budgets = budgets.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['walletId'] == _selectedBudgetWalletFilter;
                        }).toList();
                      }
                      
                      print('[BUDGET_VIEW] budgets count after filter: ' + budgets.length.toString());
                      
                      if (budgets.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _selectedBudgetWalletFilter != null 
                                    ? 'Không có ngân sách nào cho ví này.'
                                    : 'Chưa có ngân sách nào.',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: budgets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final b = budgets[i].data() as Map<String, dynamic>;
                          final catName = categoryMap[b['categoryId']] ?? b['categoryId'] ?? '';
                          final walletId = b['walletId'];
                          final walletName = walletId != null ? walletMap[walletId] ?? 'Không tên' : 'Tất cả ví';
                          
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                              title: Text('Danh mục: $catName'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ví: $walletName'),
                                  Text('Giới hạn: ${b['limit']} ${b['currency']}'),
                                  Text('Đã chi: ${b['spentAmount'] ?? 0} ${b['currency']}'),
                                  Text('Từ: ${_formatDate(b['startDate'])}  Đến: ${_formatDate(b['endDate'])}'),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String _formatDate(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day}/${d.month}/${d.year}';
    }
    return '';
  }

  void _showTransactionDetails(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header với nút đóng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chi tiết giao dịch',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Icon và loại giao dịch
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: expense.type == 'income' 
                            ? Theme.of(context).colorScheme.tertiary.withOpacity(0.1)
                            : Theme.of(context).colorScheme.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        expense.type == 'income' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: expense.type == 'income' 
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.error,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.type == 'income' ? 'Thu nhập' : 'Chi tiêu',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: expense.type == 'income' 
                                  ? Theme.of(context).colorScheme.tertiary
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                          Text(
                            _formatTransactionAmount(expense),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: expense.type == 'income' 
                                  ? Theme.of(context).colorScheme.tertiary
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Thông tin chi tiết
                _buildDetailRow('Danh mục', expense.category.name, Icons.category, Color(expense.category.color)),
                const SizedBox(height: 16),
                
                _buildDetailRow('Ngày giao dịch', _formatFullDate(expense.date), Icons.calendar_today),
                const SizedBox(height: 16),

                // Hiển thị ví nếu có
                if (expense.walletId != null) ...[
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('wallets').doc(expense.walletId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildDetailRow('Ví', 'Đang tải...', Icons.account_balance_wallet);
                      }
                      
                      final walletData = snapshot.data?.data() as Map<String, dynamic>?;
                      final walletName = walletData?['name'] ?? 'Không tên';
                      
                      return _buildDetailRow('Ví', walletName, Icons.account_balance_wallet);
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Hiển thị mô tả nếu có
                if (expense.description != null && expense.description!.isNotEmpty) ...[
                  _buildDetailRow('Mô tả', expense.description!, Icons.description),
                  const SizedBox(height: 16),
                ],

                // Thông tin bổ sung
                _buildDetailRow('ID giao dịch', expense.expenseId, Icons.receipt),
                const SizedBox(height: 16),
                _buildDetailRow('Loại tiền', expense.currency ?? 'VND', Icons.attach_money),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, [Color? iconColor]) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (iconColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
      'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
