
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Chỉnh sửa Hồ sơ'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.of(context).pushNamed('/settings/edit_profile'),
          ),
          ListTile(
            title: const Text('Cài đặt Tài khoản'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.of(context).pushNamed('/settings/account_settings'),
          ),
          ListTile(
            title: const Text('Cài đặt Ứng dụng'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.of(context).pushNamed('/settings/app_settings'),
          ),
          ListTile(
            title: const Text('Đăng xuất'),
            trailing: const Icon(Icons.logout),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

