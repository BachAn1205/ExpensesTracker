import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_repository/expense_repository.dart';
import '../../add_expense/providers/category_provider.dart';
import '../../../services/firestore_service.dart';
import '../../settings/providers/currency_provider.dart';
import '../providers/wallet_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddBudgetBottomSheet extends StatefulWidget {
  final VoidCallback? onBudgetAdded;
  const AddBudgetBottomSheet({Key? key, this.onBudgetAdded}) : super(key: key);

  @override
  State<AddBudgetBottomSheet> createState() => _AddBudgetBottomSheetState();
}

class _AddBudgetBottomSheetState extends State<AddBudgetBottomSheet> {
  String? _selectedCategoryId;
  String? _selectedWalletId;
  String? _selectedWalletName;
  String? _selectedWalletCurrency;
  final TextEditingController _limitController = TextEditingController();
  DateTime _startDate = DateTime.now();
  String _periodType = 'month'; // 'week', 'month', 'year'
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Tự động fetch wallets nếu chưa có
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final repo = Provider.of<ExpenseRepository>(context, listen: false);
      if (walletProvider.wallets.isEmpty) {
        walletProvider.fetchWallets(repo);
      }
    });
  }

  DateTime get _endDate {
    switch (_periodType) {
      case 'week':
        return _startDate.add(const Duration(days: 6));
      case 'month':
        return DateTime(_startDate.year, _startDate.month + 1, _startDate.day).subtract(const Duration(days: 1));
      case 'year':
        return DateTime(_startDate.year + 1, _startDate.month, _startDate.day).subtract(const Duration(days: 1));
      default:
        return _startDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);
    final currency = Provider.of<CurrencyProvider>(context).currency;
    
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thêm ngân sách mới', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Chọn ví
              Text(
                'Chọn ví',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService().getWallets(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.6)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Đang tải danh sách ví...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.error),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Lỗi khi tải danh sách ví:  {snapshot.error}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final wallets = snapshot.data ?? [];
                  if (wallets.isEmpty) {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.6)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 20,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Chưa có ví nào. Vui lòng tạo ví trước.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/wallet_list');
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Tạo ví mới'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.6)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWalletId ?? (wallets.isNotEmpty ? wallets.first['walletId'] : null),
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedWalletId = newValue;
                            if (newValue != null) {
                              final selectedWallet = wallets.firstWhere((w) => w['walletId'] == newValue);
                              _selectedWalletName = selectedWallet['name'];
                              _selectedWalletCurrency = selectedWallet['currency'];
                            } else {
                              _selectedWalletName = null;
                              _selectedWalletCurrency = null;
                            }
                          });
                        },
                        items: wallets.map<DropdownMenuItem<String>>((wallet) {
                          final walletName = wallet['name'] ?? 'Không tên';
                          final balance = (wallet['balance'] ?? 0.0).toDouble();
                          final currency = wallet['currency'] ?? 'VND';
                          final formattedBalance = formatCurrency(balance, currency);
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
                  );
                },
              ),
              const SizedBox(height: 12),
              
              // Chọn danh mục
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                items: categoryProvider.categories.map((cat) => DropdownMenuItem(
                  value: cat.categoryId,
                  child: Text(cat.name),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
                decoration: const InputDecoration(labelText: 'Danh mục'),
              ),
              const SizedBox(height: 12),
              
              TextField(
                controller: _limitController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Giới hạn chi tiêu (${_selectedWalletCurrency ?? currency})',
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  const Text('Thời gian:'),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _periodType,
                    items: const [
                      DropdownMenuItem(value: 'week', child: Text('Tuần')),
                      DropdownMenuItem(value: 'month', child: Text('Tháng')),
                      DropdownMenuItem(value: 'year', child: Text('Năm')),
                    ],
                    onChanged: (val) => setState(() => _periodType = val!),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  const Text('Bắt đầu:'),
                  const SizedBox(width: 8),
                  TextButton(
                    child: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                  ),
                  const SizedBox(width: 16),
                  const Text('Kết thúc:'),
                  const SizedBox(width: 8),
                  Text('${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                ],
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveBudget,
                  child: _isSaving ? const CircularProgressIndicator() : const Text('Lưu ngân sách'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Utility to format currency
  String formatCurrency(num amount, String currency) {
    return '${amount.toStringAsFixed(0)} $currency';
  }

  Future<void> _saveBudget() async {
    if (_selectedCategoryId == null || _limitController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ thông tin.')));
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final limit = double.tryParse(_limitController.text) ?? 0;
      final currency = _selectedWalletCurrency ?? Provider.of<CurrencyProvider>(context, listen: false).currency;
      
      // Tính toán số tiền đã chi trong khoảng thời gian này
      double spentAmount = 0.0;
      if (_selectedWalletId != null) {
        // Nếu chọn ví cụ thể, chỉ tính giao dịch của ví đó
        spentAmount = await _calculateSpentAmountForWallet(_selectedCategoryId!, _selectedWalletId!, _startDate, _endDate);
      } else {
        // Nếu không chọn ví, tính tất cả giao dịch
        spentAmount = await _calculateSpentAmountForAllWallets(_selectedCategoryId!, _startDate, _endDate);
      }
      
      await FirestoreService().addBudget(
        categoryId: _selectedCategoryId!,
        walletId: _selectedWalletId, // Thêm walletId
        limit: limit,
        currency: currency,
        startDate: _startDate,
        endDate: _endDate,
        initialSpentAmount: spentAmount, // Thêm số tiền đã chi
      );
      
      if (widget.onBudgetAdded != null) widget.onBudgetAdded!();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm ngân sách!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Tính số tiền đã chi cho ví cụ thể
  Future<double> _calculateSpentAmountForWallet(String categoryId, String walletId, DateTime startDate, DateTime endDate) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return 0.0;

      final query = FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('categoryId', isEqualTo: categoryId)
          .where('walletId', isEqualTo: walletId)
          .where('type', isEqualTo: 'expense')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      final snapshot = await query.get();
      double totalSpent = 0.0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalSpent += (data['amount'] as num?)?.toDouble() ?? 0.0;
      }
      
      return totalSpent;
    } catch (e) {
      print('Error calculating spent amount for wallet: $e');
      return 0.0;
    }
  }

  // Tính số tiền đã chi cho tất cả ví
  Future<double> _calculateSpentAmountForAllWallets(String categoryId, DateTime startDate, DateTime endDate) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return 0.0;

      final query = FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('categoryId', isEqualTo: categoryId)
          .where('type', isEqualTo: 'expense')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      final snapshot = await query.get();
      double totalSpent = 0.0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalSpent += (data['amount'] as num?)?.toDouble() ?? 0.0;
      }
      
      return totalSpent;
    } catch (e) {
      print('Error calculating spent amount for all wallets: $e');
      return 0.0;
    }
  }
}
