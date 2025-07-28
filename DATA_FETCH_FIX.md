# Sửa lỗi Fetch Dữ liệu khi Đăng nhập lại

## Vấn đề:
Khi đăng xuất và đăng nhập lại cùng một tài khoản, dữ liệu hiển thị trên màn hình trở về 0 mặc dù dữ liệu vẫn còn trong database.

## Nguyên nhân:
1. **Timing issue:** Firebase Auth có thể chưa sẵn sàng khi ExpenseProvider cố gắng fetch dữ liệu
2. **Mapping issue:** Có thể có vấn đề khi mapping dữ liệu từ Firestore sang Expense object
3. **Provider state:** ExpenseProvider có thể không được cập nhật đúng cách

## Giải pháp đã áp dụng:

### 1. Cải thiện ExpenseProvider
- Thêm delay 500ms trước khi fetch để đảm bảo Firebase Auth đã sẵn sàng
- Thêm logging chi tiết để debug
- Thêm phương thức `refreshExpenses()` để force refresh

### 2. Cải thiện FirebaseExpenseRepo
- Thêm logging chi tiết cho từng document được xử lý
- Xử lý từng document riêng biệt thay vì batch processing
- Hiển thị thông tin chi tiết về dữ liệu được fetch

### 3. Cải thiện MainScreen
- Sử dụng `refreshExpenses()` thay vì `fetchExpenses()` trực tiếp
- Đảm bảo Provider đã sẵn sàng trước khi gọi

### 4. Cải thiện FirestoreTestWidget
- Hiển thị thông tin chi tiết về dữ liệu trong Firestore
- Hiển thị userId để kiểm tra filter
- Thêm nút refresh để test

## Các thay đổi chi tiết:

### 1. packages/expense_repository/lib/src/firebase_expense_repo.dart
```dart
// Thêm logging chi tiết
print('Processing document: ${doc.id}');
print('Document data: ${doc.data()}');
print('Successfully created expense: ${expense.expenseId} - ${expense.category.name} - ${expense.amount}');
```

### 2. lib/screens/home/providers/expense_provider.dart
```dart
// Thêm delay để đảm bảo Firebase Auth sẵn sàng
Future.delayed(const Duration(milliseconds: 500), () {
  fetchExpenses(FirebaseExpenseRepo());
});

// Thêm phương thức refresh
Future<void> refreshExpenses() async {
  print('Force refreshing expenses...');
  await fetchExpenses(FirebaseExpenseRepo());
}
```

### 3. lib/screens/home/views/main_screen.dart
```dart
// Sử dụng refreshExpenses thay vì fetchExpenses trực tiếp
final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
expenseProvider.refreshExpenses();
```

## Cách test:

### 1. Sử dụng FirestoreTestWidget
- Truy cập route `/test` trong ứng dụng
- Kiểm tra xem dữ liệu có được load từ Firestore không
- Kiểm tra userId có đúng không

### 2. Kiểm tra logs
- Mở console để xem các log messages
- Tìm các message như:
  - "User logged in, fetching expenses for user: [userId]"
  - "Found X expenses in Firestore"
  - "Successfully processed X expenses"

### 3. Test đăng xuất/đăng nhập
- Đăng xuất
- Đăng nhập lại
- Kiểm tra xem dữ liệu có hiển thị không

## Kết quả mong đợi:
1. ✅ Dữ liệu được fetch đúng cách khi đăng nhập
2. ✅ Logging chi tiết để debug
3. ✅ Không có timing issues
4. ✅ Mapping dữ liệu chính xác

## Lưu ý:
- Nếu vẫn có vấn đề, kiểm tra logs để xem chi tiết
- Sử dụng FirestoreTestWidget để kiểm tra dữ liệu trực tiếp
- Đảm bảo userId trong database khớp với user đang đăng nhập 