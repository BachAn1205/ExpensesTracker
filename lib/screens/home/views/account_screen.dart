import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:expense_repository/expense_repository.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/expense_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? userName = 'Tên người dùng';
  String? email = 'email@example.com';
  String? avatarPath;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        setState(() {
          userName = doc.data()?['name'] ?? user.displayName ?? 'Tên người dùng';
          email = doc.data()?['email'] ?? user.email ?? 'email@example.com';
          photoUrl = doc.data()?['photoUrl'] ?? user.photoURL;
        });
      });
    }
  }

  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        avatarPath = picked.path;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Upload file lên Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('avatars')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(File(picked.path));
        final downloadUrl = await storageRef.getDownloadURL();

        // Lưu URL vào Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'photoUrl': downloadUrl,
        });

        // Cập nhật UI
        setState(() {
          avatarPath = null; // Để CircleAvatar load lại từ network
        });
        // fetchUserData(); // Reload user info - REMOVED
      }
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
              backgroundImage: avatarPath != null
                  ? FileImage(File(avatarPath!))
                  : (photoUrl != null && photoUrl!.isNotEmpty
                      ? NetworkImage(photoUrl!)
                      : null) as ImageProvider?,
              child: avatarPath == null && (photoUrl == null || photoUrl!.isEmpty)
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
                Navigator.pushNamed(context, '/settings/account_settings');
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
