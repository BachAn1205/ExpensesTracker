import 'package:flutter/material.dart';
import '../../../services/currency_service.dart';
import '../../../services/firestore_service.dart';
import 'add_wallet_bottom_sheet.dart';

class WalletListScreen extends StatefulWidget {
  const WalletListScreen({super.key});

  @override
  State<WalletListScreen> createState() => _WalletListScreenState();
}

class _WalletListScreenState extends State<WalletListScreen> {




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Ví'),
        backgroundColor: const Color(0xFF1E6F5C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const AddWalletBottomSheet(),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getWallets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Có lỗi xảy ra',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final wallets = snapshot.data ?? [];
          if (wallets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có ví nào',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thêm ví đầu tiên của bạn!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => const AddWalletBottomSheet(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm ví'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: wallets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                    'Số dư: ${CurrencyService.formatCurrency((wallet['balance'] ?? 0.0).toDouble(), wallet['currency'] ?? 'VND')}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        // TODO: Implement edit wallet
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tính năng đang phát triển')),
                        );
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(wallet);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Chỉnh sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Navigate to wallet detail screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã chọn ví: ${wallet['name'] ?? ''}')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> wallet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa ví "${wallet['name'] ?? ''}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
                      TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final firestoreService = FirestoreService();
                await firestoreService.deleteWallet(wallet['walletId'] ?? '');
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
} 