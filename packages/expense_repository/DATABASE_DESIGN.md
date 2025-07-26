# Thiết kế Cơ sở dữ liệu Firebase Firestore

## Tổng quan

Ứng dụng quản lý chi tiêu sử dụng Firebase Firestore với các quan hệ 1-n (one-to-many) giữa các entities chính.

## Collections và Quan hệ

### 1. Collection: `users`
**Mô tả**: Quản lý thông tin người dùng
**Fields**:
- `userId` (String): ID duy nhất của người dùng
- `email` (String): Email đăng nhập
- `name` (String): Tên người dùng
- `photoUrl` (String?): URL ảnh đại diện
- `createdAt` (Timestamp): Thời gian tạo
- `updatedAt` (Timestamp): Thời gian cập nhật

### 2. Collection: `categories`
**Mô tả**: Danh mục chi tiêu/thu nhập của người dùng
**Quan hệ**: 1-n với `users` (mỗi người dùng có nhiều danh mục)
**Fields**:
- `categoryId` (String): ID duy nhất của danh mục
- `userId` (String): ID của người dùng sở hữu (quan hệ 1-n)
- `name` (String): Tên danh mục
- `totalExpenses` (Number): Tổng số giao dịch
- `icon` (String): Icon của danh mục
- `color` (Number): Màu sắc của danh mục
- `createdAt` (Timestamp): Thời gian tạo
- `updatedAt` (Timestamp): Thời gian cập nhật

### 3. Collection: `transactions`
**Mô tả**: Giao dịch chi tiêu/thu nhập
**Quan hệ**: 
- 1-n với `users` (mỗi người dùng có nhiều giao dịch)
- 1-n với `categories` (mỗi danh mục có nhiều giao dịch)
- 1-n với `wallet` (optional, mỗi ví có nhiều giao dịch)
**Fields**:
- `transactionId` (String): ID duy nhất của giao dịch
- `userId` (String): ID của người dùng sở hữu (quan hệ 1-n)
- `categoryId` (String): ID của danh mục (quan hệ 1-n)
- `walletId` (String?): ID của tài khoản ngân hàng (quan hệ 1-n, optional)
- `amount` (Number): Số tiền
- `type` (String): Loại giao dịch ('income' hoặc 'expense')
- `description` (String): Mô tả giao dịch
- `date` (Timestamp): Ngày giao dịch
- `createdAt` (Timestamp): Thời gian tạo
- `updatedAt` (Timestamp): Thời gian cập nhật

**Denormalized Fields** (để tối ưu hiệu suất):
- `categoryName` (String): Tên danh mục (denormalized)
- `categoryIcon` (String): Icon danh mục (denormalized)
- `categoryColor` (Number): Màu danh mục (denormalized)
- `walletName` (String?): Tên ví (denormalized)

4. Collection: `Wallets`
mô tả: Quản lý ví tiền của người dùng
**Quan hệ**:
- 1-n với `users` (mỗi người dùng có nhiều ví)
- 1-n với `transactions` (mỗi ví có nhiều giao dịch)"
**Fields**:
- `walletId` (String): ID duy nhất của ví
- `userId` (String): ID của người dùng sở hữu (quan hệ 1-n)
- `name` (String): Tên ví
- `balance` (Number): Số dư hiện tại
- `currency` (String): Mã tiền tệ (ví dụ: 'USD', 'VND')
- `createdAt` (Timestamp): Thời gian tạo
- `updatedAt` (Timestamp): Thời gian cập nhật
- `icon` (String): Icon của ví (ví dụ: 'wallet_icon.png')
- `color` (Number): Màu sắc của ví (ví dụ: 0xFF0000 cho màu đỏ)
- `description` (String?): Mô tả ngắn về ví (tuỳ chọn)

### 5. Collection: `budgets`
**Mô tả**: Ngân sách chi tiêu theo danh mục
**Quan hệ**: 
- 1-n với `users` (mỗi người dùng có nhiều ngân sách)
- 1-n với `categories` (mỗi danh mục có nhiều ngân sách)
**Fields**:
- `budgetId` (String): ID duy nhất của ngân sách
- `userId` (String): ID của người dùng sở hữu (quan hệ 1-n)
- `categoryId` (String): ID của danh mục (quan hệ 1-n)
- `amount` (Number): Số tiền ngân sách
- `startDate` (Timestamp): Ngày bắt đầu
- `endDate` (Timestamp): Ngày kết thúc
- `createdAt` (Timestamp): Thời gian tạo
- `updatedAt` (Timestamp): Thời gian cập nhật

**Denormalized Fields**:
- `categoryName` (String): Tên danh mục (denormalized)
- `categoryIcon` (String): Icon danh mục (denormalized)
- `categoryColor` (Number): Màu danh mục (denormalized)

## Cách thức Truy vấn

### Truy vấn theo User
```dart
// Lấy tất cả giao dịch của một người dùng
.where('userId', isEqualTo: currentUserId)

// Lấy tất cả danh mục của một người dùng
.where('userId', isEqualTo: currentUserId)

// Lấy tất cả tài khoản ngân hàng của một người dùng
.where('userId', isEqualTo: currentUserId)
```
// Lấy tất cả ví/tài khoản ngân hàng của một người dùng
.collection('wallets')
.where('userId', isEqualTo: currentUserId)
.orderBy('name', descending: false); // Sắp xếp theo tên cho dễ nhìn
### Truy vấn theo Category
```dart
// Lấy tất cả giao dịch của một danh mục
.where('userId', isEqualTo: currentUserId)
.where('categoryId', isEqualTo: categoryId)

// Lấy tất cả ngân sách của một danh mục
.where('userId', isEqualTo: currentUserId)
.where('categoryId', isEqualTo: categoryId)
```

### Truy vấn theo Date Range
```dart
// Lấy giao dịch trong khoảng thời gian
.where('userId', isEqualTo: currentUserId)
.where('date', isGreaterThanOrEqualTo: startDate)
.where('date', isLessThanOrEqualTo: endDate)
```

## Denormalization Strategy

Để tối ưu hiệu suất truy vấn và giảm số lần đọc từ Firestore, chúng ta sử dụng denormalization:

1. **Transaction Document**: Lưu trực tiếp `categoryName`, `categoryIcon`, `categoryColor` thay vì chỉ `categoryId`
2. **Budget Document**: Lưu trực tiếp `categoryName`, `categoryIcon`, `categoryColor` thay vì chỉ `categoryId`
3. **Transaction Document**: Lưu trực tiếp `bankAccountName` thay vì chỉ `bankAccountId`

## Security Rules

```javascript
// Ví dụ Security Rules cho Firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users chỉ có thể đọc/ghi dữ liệu của chính mình
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Categories chỉ có thể đọc/ghi bởi người dùng sở hữu
    match /categories/{categoryId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Transactions chỉ có thể đọc/ghi bởi người dùng sở hữu
    match /transactions/{transactionId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
  
    
    // Budgets chỉ có thể đọc/ghi bởi người dùng sở hữu
    match /budgets/{budgetId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
  }
}
```

## Indexes cần thiết

Để hỗ trợ các truy vấn phức tạp, cần tạo các composite indexes:

1. `transactions` collection:
   - `userId` + `date` (descending)
   - `userId` + `categoryId` + `date` (descending)
   - `userId` + `type` + `date` (descending)

2. `budgets` collection:
   - `userId` + `startDate` (descending)
   - `userId` + `categoryId` + `startDate` (descending)

3. `categories` collection:
   - `userId` + `name` (ascending)

