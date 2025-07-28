import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_repository/expense_repository.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  List<Category> get categories => _categories;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? get currentUserId => _auth.currentUser?.uid;

  CategoryProvider() {
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        // User mới đăng nhập, fetch lại danh mục
        fetchCategories();
      } else {
        // User đăng xuất, clear danh mục
        _categories = [];
        notifyListeners();
      }
    });
  }

  Future<void> fetchCategories() async {
    if (currentUserId == null) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      final snapshot = await FirebaseFirestore.instance
          .collection('categories') // Sử dụng chữ thường
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      _categories = snapshot.docs.map((doc) {
        final data = doc.data();
        return Category(
          categoryId: doc.id,
          name: data['name'] ?? '',
          totalExpenses: data['totalExpenses'] ?? 0,
          icon: data['icon'] ?? '',
          color: data['color'] ?? 0xFF000000,
        );
      }).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error fetching categories: $e');
    }
  }

  Future<void> addCategory(Category category) async {
    if (currentUserId == null) return;
    
    try {
      final docRef = await FirebaseFirestore.instance.collection('categories').add({
        'userId': currentUserId,
        'name': category.name,
        'totalExpenses': category.totalExpenses,
        'icon': category.icon,
        'color': category.color,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final newCategory = category.copyWith(categoryId: docRef.id);
      _categories.add(newCategory);
      notifyListeners();
    } catch (e) {
      print('Error adding category: $e');
    }
  }

  Future<void> addCategoryByName(String name, String icon) async {
    final colorList = [
      0xFF2196F3, // blue
      0xFFFFC107, // amber
      0xFF4CAF50, // green
      0xFFF44336, // red
      0xFF9C27B0, // purple
      0xFFFF9800, // orange
      0xFF009688, // teal
      0xFF795548, // brown
      0xFF607D8B, // blue grey
    ];
    final color = colorList[_categories.length % colorList.length];
    final category = Category(
      categoryId: '',
      name: name,
      totalExpenses: 0,
      icon: icon,
      color: color,
    );
    await addCategory(category);
    await fetchCategories(); // Đảm bảo cập nhật lại danh sách
  }

  Future<void> updateCategory(Category category) async {
    try {
      await FirebaseFirestore.instance.collection('categories').doc(category.categoryId).update({
        'name': category.name,
        'totalExpenses': category.totalExpenses,
        'icon': category.icon,
        'color': category.color,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final idx = _categories.indexWhere((c) => c.categoryId == category.categoryId);
      if (idx != -1) {
        _categories[idx] = category;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating category: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await FirebaseFirestore.instance.collection('categories').doc(categoryId).delete();
      _categories.removeWhere((c) => c.categoryId == categoryId);
      notifyListeners();
    } catch (e) {
      print('Error deleting category: $e');
    }
  }
}
