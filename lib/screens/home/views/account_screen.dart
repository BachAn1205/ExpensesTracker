import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:expense_repository/expense_repository.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/expense_provider.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? userName = 'Tên người dùng';
  String? email = 'email@example.com';
  String? avatarPath;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    // TODO: Replace with actual Firestore user fetching logic
    // Example:
    // final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    // setState(() {
    //   userName = userDoc['name'];
    //   email = userDoc['email'];
    // });
  }

  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        avatarPath = picked.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Mở rộng', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          GestureDetector(
            onTap: pickAvatar,
            child: CircleAvatar(
              radius: width / 5 / 2,
              backgroundColor: Colors.yellow[700],
              backgroundImage: avatarPath != null ? AssetImage(avatarPath!) : null,
              child: avatarPath == null
                  ? const Icon(Icons.person, size: 60, color: Colors.black)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName ?? '',
            style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            email ?? '',
            style: const TextStyle(color: Colors.black, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.black),
              title: const Text('Quản lý tài khoản', style: TextStyle(color: Colors.black)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.pushNamed(context, '/account_setting');
              },
            ),
          ),
          const Divider(color: Colors.grey, height: 1),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet, color: Colors.black),
                  title: const Text('Ví của tôi', style: TextStyle(color: Colors.black)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pushNamed(context, '/add_wallet');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.card_giftcard, color: Colors.black),
                  title: const Text('Danh mục', style: TextStyle(color: Colors.black)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: () {
                          // TODO: Add category logic
                        },
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/category_list');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.black),
                  title: const Text('Cài đặt', style: TextStyle(color: Colors.black)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
