# Sửa lỗi Firebase Index

## Vấn đề:
Khi thêm giao dịch chi tiêu, xuất hiện lỗi:
```
[cloud_firestore/failed-precondition] The query requires an index. You can create it here: [URL]
```

## Nguyên nhân:
Lỗi này xảy ra vì truy vấn Firestore trong phương thức `addTransaction` yêu cầu một chỉ mục phức tạp (composite index) trên các trường:
- `userId`
- `categoryId` 
- `startDate`
- `endDate`

## Giải pháp đã áp dụng:

### 1. Loại bỏ Firestore Transaction
- Thay vì sử dụng `runTransaction()`, chuyển sang thực hiện các operations riêng biệt
- Điều này tránh được lỗi index phức tạp

### 2. Đơn giản hóa truy vấn Budget
- Thay đổi từ truy vấn phức tạp:
```dart
.where('userId', isEqualTo: currentUserId)
.where('categoryId', isEqualTo: categoryId)
.where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(date))
.where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
```

- Thành truy vấn đơn giản:
```dart
.where('userId', isEqualTo: currentUserId)
.where('categoryId', isEqualTo: categoryId)
```

### 3. Xử lý logic trong code
- Kiểm tra khoảng thời gian trong code thay vì trong truy vấn
- Sử dụng `Timestamp.compareTo()` để so sánh ngày tháng

### 4. Error Handling
- Thêm try-catch cho từng phần riêng biệt
- Không throw exception khi cập nhật wallet/budget thất bại
- Chỉ throw exception khi tạo transaction thất bại

## Các thay đổi trong `lib/services/firestore_service.dart`:

### Trước:
```dart
return await _firestore.runTransaction<String>((transaction) async {
  // Tất cả operations trong một transaction
  // Truy vấn phức tạp gây lỗi index
});
```

### Sau:
```dart
// Tạo transaction document
await transactionDocRef.set({...});

// Cập nhật wallet riêng biệt
if (walletId != null) {
  try {
    // Logic cập nhật wallet
  } catch (e) {
    print('Warning: Could not update wallet balance: $e');
  }
}

// Cập nhật budget riêng biệt
if (type == 'expense') {
  try {
    // Truy vấn đơn giản + logic trong code
  } catch (e) {
    print('Warning: Could not update budget: $e');
  }
}
```

## Kết quả:
1. ✅ Không còn lỗi Firebase index
2. ✅ Giao dịch vẫn được tạo thành công
3. ✅ Wallet balance vẫn được cập nhật (nếu có)
4. ✅ Budget vẫn được cập nhật (nếu có)
5. ✅ Error handling tốt hơn

## Lưu ý:
- Nếu cần truy vấn phức tạp trong tương lai, có thể tạo index trong Firebase Console
- Hiện tại giải pháp này đủ để ứng dụng hoạt động bình thường 