import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../settings/providers/currency_provider.dart';
import '../../../services/currency_service.dart';
import '../../../services/firestore_service.dart';

class AddWalletBottomSheet extends StatefulWidget {
  const AddWalletBottomSheet({super.key});

  @override
  State<AddWalletBottomSheet> createState() => _AddWalletBottomSheetState();
}

class _AddWalletBottomSheetState extends State<AddWalletBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedCurrency = 'VND';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Lấy currency hiện tại từ CurrencyProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      setState(() {
        _selectedCurrency = currencyProvider.currency;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveWallet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final walletId = DateTime.now().millisecondsSinceEpoch.toString();
      final firestoreService = FirestoreService();
      await firestoreService.addWallet(
        _nameController.text.trim(),
        double.parse(_balanceController.text),
        _selectedCurrency,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm ví: ${_nameController.text.trim()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thêm ví mới',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên ví',
                  hintText: 'Ví tiền mặt, Ví ngân hàng...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên ví';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: 'Số dư hiện tại',
                  hintText: '0',
                  border: const OutlineInputBorder(),
                  suffixText: _selectedCurrency,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số dư';
                  }
                  final balance = double.tryParse(value);
                  if (balance == null) {
                    return 'Vui lòng nhập số hợp lệ';
                  }
                  if (balance < 0) {
                    return 'Số dư không được âm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Loại tiền tệ',
                  border: OutlineInputBorder(),
                ),
                items: CurrencyService.supportedCurrencies.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text('$currency - ${CurrencyService.getCurrencySymbol(currency)}'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCurrency = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveWallet,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Thêm ví',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 