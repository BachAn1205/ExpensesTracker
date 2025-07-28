import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../../../services/firestore_service.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý danh mục'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context),
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          final categories = provider.categories;
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (categories.isEmpty) {
            return const Center(child: Text('Chưa có danh mục nào.')); 
          }
          return ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final cat = categories[i];
              return ListTile(
                leading: Icon(_iconFromString(cat.icon), color: Color(cat.color)),
                title: Text(cat.name),
                // trailing: IconButton(
                //   icon: Icon(Icons.delete, color: Colors.red),
                //   onPressed: () {},
                // ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final _nameController = TextEditingController();
    String selectedIcon = 'category';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm danh mục mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên danh mục'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _iconList.map((iconName) {
                  return ChoiceChip(
                    label: Icon(_iconFromString(iconName)),
                    selected: selectedIcon == iconName,
                    onSelected: (_) {
                      selectedIcon = iconName;
                      (context as Element).markNeedsBuild();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Thêm'),
              onPressed: () async {
                final name = _nameController.text.trim();
                if (name.isEmpty) return;
                final provider = Provider.of<CategoryProvider>(context, listen: false);
                await provider.addCategoryByName(name, selectedIcon);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}

// Danh sách icon cho phép chọn
const _iconList = [
  'category',
  'shopping_cart',
  'directions_car',
  'movie',
  'account_balance_wallet',
  'card_giftcard',
  'home',
  'pets',
  'flight',
  'restaurant',
];

IconData _iconFromString(String iconName) {
  switch (iconName) {
    case 'shopping_cart': return Icons.shopping_cart;
    case 'directions_car': return Icons.directions_car;
    case 'movie': return Icons.movie;
    case 'account_balance_wallet': return Icons.account_balance_wallet;
    case 'card_giftcard': return Icons.card_giftcard;
    case 'home': return Icons.home;
    case 'pets': return Icons.pets;
    case 'flight': return Icons.flight;
    case 'restaurant': return Icons.restaurant;
    default: return Icons.category;
  }
}
