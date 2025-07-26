import 'package:expense_repository/expense_repository.dart';
import 'package:expenses_tracker/screens/home/blocs/get_expenses_bloc/get_expenses_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/home/views/home_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/register/register_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/edit_profile_screen.dart';
import '../screens/settings/account_settings_screen.dart';
import '../screens/settings/change_password_screen.dart';
import '../screens/settings/app_settings_screen.dart';
import 'screens/settings/blocs/currency_bloc/currency_bloc.dart';

class MyAppView extends StatelessWidget {
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ExpenseRepository>(
      create: (context) => FirebaseExpenseRepo(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => GetExpensesBloc(
              context.read<ExpenseRepository>(),
            )..add(GetExpenses()),
          ),
          BlocProvider(
            create: (context) => CurrencyBloc(),
          ),
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
            '/home': (context) => BlocProvider(
              create: (context) => GetExpensesBloc(context.read<ExpenseRepository>())..add(GetExpenses()),
              child: const HomeScreen(),
            ),
            '/main_screen': (context) => BlocProvider(
              create: (context) => GetExpensesBloc(context.read<ExpenseRepository>())..add(GetExpenses()),
              child: const HomeScreen(),
            ),
            '/settings': (context) => const SettingsScreen(),
            '/settings/edit_profile': (context) => const EditProfileScreen(),
            '/settings/account_settings': (context) => const AccountSettingsScreen(),
            '/settings/change_password': (context) => const ChangePasswordScreen(),
            '/settings/app_settings': (context) => const AppSettingsScreen(),
          },
        ),
      ),
    );
  }
}