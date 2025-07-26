import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTestWidget extends StatefulWidget {
  const FirestoreTestWidget({super.key});

  @override
  State<FirestoreTestWidget> createState() => _FirestoreTestWidgetState();
}

class _FirestoreTestWidgetState extends State<FirestoreTestWidget> {
  String _result = 'Chưa kiểm tra';

  Future<void> _testFirestore() async {
    setState(() {
      _result = 'Đang kiểm tra...';
    });
    try {
      final docRef = FirebaseFirestore.instance.collection('test_connection').doc('test');
      await docRef.set({'timestamp': FieldValue.serverTimestamp()});
      final doc = await docRef.get();
      if (doc.exists) {
        setState(() {
          _result = 'Kết nối Firestore thành công!';
        });
      } else {
        setState(() {
          _result = 'Không thể đọc document vừa ghi.';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Lỗi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kiểm tra Firestore')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_result, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _testFirestore,
              child: const Text('Kiểm tra kết nối Firestore'),
            ),
          ],
        ),
      ),
    );
  }
}

