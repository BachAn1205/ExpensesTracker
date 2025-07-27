import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Để định dạng ngày tháng
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../home/providers/expense_provider.dart';
import '../../add_expense/providers/category_provider.dart';
import '../../../services/firestore_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const AddTransactionScreen({super.key, this.onClose});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _transactionType = 'expense'; // Loại giao dịch mặc định (chi tiêu)
  String? _selectedCategoryId;
  bool _isSaving = false;

  // Hàm chọn ngày
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary, // Màu chính của DatePicker
              onPrimary: Theme.of(context).colorScheme.onPrimary, // Màu chữ trên primary color
              surface: Theme.of(context).colorScheme.surface, // Nền của dialog
              onSurface: Theme.of(context).colorScheme.onSurface, // Màu chữ trên surface
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary, // Màu nút trong DatePicker
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Hàm lưu giao dịch
  void _saveTransaction() async {
    if (_isSaving) return; // Ngăn chặn multiple submissions
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Kiểm tra xem user đã đăng nhập chưa
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để thêm giao dịch.')),
        );
        return;
      }

      final double? amount = double.tryParse(_amountController.text);

      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ.')),
        );
        return;
      }

      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn danh mục.')),
        );
        return;
      }

      // Kiểm tra xem có categories không
      final categoryProvider = context.read<CategoryProvider>();
      if (categoryProvider.categories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có danh mục nào. Vui lòng tạo danh mục trước.')),
        );
        return;
      }

      // Sử dụng FirestoreService để lưu transaction với userId
      final firestoreService = FirestoreService();
      final transactionId = await firestoreService.addTransaction(
        categoryId: _selectedCategoryId!,
        amount: amount,
        type: _transactionType,
        date: _selectedDate,
        description: _descriptionController.text.trim(),
      );

      if (transactionId.isEmpty) {
        throw Exception('Không thể tạo transaction ID');
      }

      // Tạo đối tượng Expense đồng bộ với dự án
      final selectedCategory = categoryProvider.categories.firstWhere(
        (c) => c.categoryId == _selectedCategoryId,
        orElse: () => Category(categoryId: '', name: '', totalExpenses: 0, icon: '', color: 0xFF000000),
      );

      // Kiểm tra xem category có hợp lệ không
      if (selectedCategory.categoryId.isEmpty) {
        throw Exception('Danh mục không hợp lệ');
      }

      final newExpense = Expense(
        expenseId: transactionId,
        category: selectedCategory,
        date: _selectedDate,
        amount: amount.toInt(),
        description: _descriptionController.text.trim(),
        type: _transactionType,
      );

      // Cập nhật ExpenseProvider
      try {
        final provider = context.read<ExpenseProvider>();
        provider.addExpense(newExpense);
      } catch (e) {
        print('Error updating ExpenseProvider: $e');
        // Vẫn hiển thị thông báo thành công vì transaction đã được lưu vào Firestore
      }

      // Sau khi lưu thành công, điều hướng quay lại
      if (widget.onClose != null) widget.onClose!();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giao dịch đã được thêm thành công!')),
      );

      print('Transaction ID: $transactionId');
      print('Amount: $amount');
      print('Category: $_selectedCategoryId');
      print('Date: $_selectedDate');
      print('Description: ${_descriptionController.text}');
      print('Type: $_transactionType');
      print('User ID: ${currentUser.uid}');
    } catch (e) {
      print('Error saving transaction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu giao dịch: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Lấy danh mục từ Provider khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Thêm Giao dịch Mới',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface, // Nền AppBar trắng
        elevation: 0.5, // Bóng đổ nhẹ
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            if (widget.onClose != null) widget.onClose!();
            Navigator.of(context).pop(); // Đóng màn hình
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trường Số tiền
            Text(
              'Số tiền',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Nhập số tiền',
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                prefixIcon: Icon(Icons.attach_money, color: Theme.of(context).colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // Chọn Loại Giao dịch (Thu nhập/Chi tiêu)
            Text(
              'Loại giao dịch',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(10),
                fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.1), // Nền khi chọn
                selectedColor: Theme.of(context).colorScheme.primary, // Màu icon/text khi chọn
                color: Theme.of(context).colorScheme.onSurfaceVariant, // Màu icon/text khi không chọn
                isSelected: [_transactionType == 'income', _transactionType == 'expense'],
                onPressed: (int index) {
                  setState(() {
                    if (index == 0) {
                      _transactionType = 'income';
                    } else {
                      _transactionType = 'expense';
                    }
                  });
                },
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward_rounded),
                        SizedBox(width: 8),
                        Text('Thu nhập'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward_rounded),
                        SizedBox(width: 8),
                        Text('Chi tiêu'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Chọn Danh mục
            Text(
              'Danh mục',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                if (categoryProvider.isLoading) {
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
                          'Đang tải danh mục...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final categories = categoryProvider.categories;
                if (categories.isEmpty) {
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
                                'Chưa có danh mục nào. Vui lòng tạo danh mục trước.',
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
                          onPressed: () async {
                            try {
                              final firestoreService = FirestoreService();
                              await firestoreService.createDefaultCategories();
                              await categoryProvider.fetchCategories();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã tạo danh mục mặc định!')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi khi tạo danh mục: $e')),
                              );
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo danh mục mặc định'),
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
                      value: _selectedCategoryId ?? (categories.isNotEmpty ? categories.first.categoryId : null),
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategoryId = newValue;
                        });
                      },
                      items: categories.map<DropdownMenuItem<String>>((category) {
                        return DropdownMenuItem<String>(
                          value: category.categoryId,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Color(category.color),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(category.name),
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
            const SizedBox(height: 20),

            // Chọn Ngày
            Text(
              'Ngày',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.6)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Mô tả (tùy chọn)
            Text(
              'Mô tả (Tùy chọn)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Thêm mô tả về giao dịch này...',
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 30),

            // Nút Thêm Giao dịch
            Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                final hasCategories = categoryProvider.categories.isNotEmpty;
                final isLoading = categoryProvider.isLoading;
                final canSave = hasCategories && !isLoading && !_isSaving;
                
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: canSave ? _saveTransaction : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canSave 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.outline,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: canSave ? 3 : 0,
                    ),
                    child: (isLoading || _isSaving)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isSaving ? 'Đang lưu...' : 'Đang tải...',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            hasCategories ? 'Thêm Giao dịch' : 'Chưa có danh mục',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: canSave 
                                  ? Theme.of(context).colorScheme.onPrimary 
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}