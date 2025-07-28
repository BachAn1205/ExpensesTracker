import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:expense_repository/expense_repository.dart';
import '../home/providers/expense_provider.dart';
import '../../services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Kiểm tra user profile trên Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).get();
      if (!userDoc.exists) {
        // Nếu chưa có profile, tạo mới
        await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
          'userId': credential.user!.uid,
          'email': credential.user!.email ?? '',
          'name': credential.user!.displayName ?? 'Người dùng mới',
          'photoUrl': credential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Tạo categories mặc định cho user mới
        final firestoreService = FirestoreService();
        await firestoreService.createDefaultCategories();
      }
      if (mounted) {
        // Gọi fetchExpenses từ Provider sau khi đăng nhập thành công
        final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
        final repo = Provider.of<ExpenseRepository>(context, listen: false);
        await expenseProvider.fetchExpenses(repo);
        Navigator.of(context).pushReplacementNamed('/main_screen');
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Sai tên đăng nhập hoặc mật khẩu';
      if (e.code == 'user-not-found') {
        msg = 'Không tìm thấy tài khoản';
      } else if (e.code == 'wrong-password') {
        msg = 'Sai mật khẩu';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      _emailController.clear();
      _passwordController.clear();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập thất bại: $e')),
      );
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
        title: Text('Đăng nhập'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _login,
              child: const Text('Đăng nhập'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/register');
              },
              child: const Text('Bạn chưa có tài khoản? Đăng ký'),
            ),
          ],
        ),
      ),
    );
  }
}