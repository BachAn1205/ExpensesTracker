import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home/providers/expense_provider.dart';
import 'screens/home/views/home_screen.dart';
import 'screens/home/views/main_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/register/register_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/edit_profile_screen.dart';
import '../screens/settings/account_settings_screen.dart';
import '../screens/settings/change_password_screen.dart';
import '../screens/settings/app_settings_screen.dart';
import 'screens/home/views/account_screen.dart';
import 'screens/settings/providers/currency_provider.dart';
import 'screens/add_expense/providers/category_provider.dart';
import 'services/firestore_test_widget.dart';

class MyAppView extends StatefulWidget {
  const MyAppView({super.key});

  @override
  State<MyAppView> createState() => _MyAppViewState();
}

class _MyAppViewState extends State<MyAppView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ExpenseProvider>();
      final repo = FirebaseExpenseRepo();
      await provider.fetchExpenses(repo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(

      providers: [
        Provider<ExpenseRepository>(
          create: (_) => FirebaseExpenseRepo(), // Giả sử đây là implement của bạn
        ),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Quản lý Chi tiêu",
        theme: ThemeData(
          colorScheme: ColorScheme.light(
            background: Colors.grey.shade100,
            onBackground: Colors.black,
            primary: const Color(0xFF00B2E7),
            secondary: const Color(0xFFE064F7),
            tertiary: const Color(0xFFFF8D6C),
            outline: Colors.grey,
          ),
        ),
        initialRoute: '/register',
        routes: {
          '/register': (context) =>  RegisterScreen(),
          '/login': (context) =>  LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/main_screen': (context) => const MainScreen(),
          '/account_screen': (context) => const AccountScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/settings/edit_profile': (context) => const EditProfileScreen(),
          '/settings/account_settings': (context) => const AccountSettingsScreen(),
          '/settings/change_password': (context) => const ChangePasswordScreen(),
          '/settings/app_settings': (context) => const AppSettingsScreen(),
          '/test': (context) => const FirestoreTestWidget(), // Thêm route test
        },
      ),
    );
  }
}
