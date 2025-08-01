import 'dart:math';

import 'package:expense_repository/expense_repository.dart';
import 'package:expenses_tracker/screens/add_expense/blocs/create_categorybloc/create_category_bloc.dart';
import 'package:expenses_tracker/screens/add_expense/blocs/get_categories_bloc/get_categories_bloc.dart';
import 'package:expenses_tracker/screens/add_expense/views/add_expense.dart';
import 'package:expenses_tracker/screens/home/blocs/get_expenses_bloc/get_expenses_bloc.dart';
import 'package:expenses_tracker/screens/home/views/main_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../add_expense/blocs/create_expense_bloc/create_expense_bloc.dart';
import '../../home/providers/expense_provider.dart';
import '../../stats/stats.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  late Color selectedItem = Colors.blue;
  Color unselectedItem = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final expenses = provider.expenses;
        if (expenses.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text('Không có dữ liệu giao dịch!', style: TextStyle(fontSize: 18)),
            ),
          );
        }
        return Scaffold(
          bottomNavigationBar: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BottomNavigationBar(
              currentIndex: index,
              onTap: (value) {
                setState(() {
                  index = value;
                });
              },
              showSelectedLabels: false,
              showUnselectedLabels: false,
              elevation: 3,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(CupertinoIcons.home),
                  label: 'Trang chủ',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(CupertinoIcons.graph_square),
                  label: 'Thống kê',
                )
              ]
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              Expense? newExpense = await Navigator.push(
                context,
                MaterialPageRoute<Expense>(
                  builder: (BuildContext context) => MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (context) => CreateCategoryBloc(FirebaseExpenseRepo()),
                      ),
                      BlocProvider(
                        create: (context) => GetCategoriesBloc(FirebaseExpenseRepo())..add(GetCategories()),
                      ),
                      BlocProvider(
                        create: (context) => CreateExpenseBloc(FirebaseExpenseRepo()),
                      ),
                    ],
                    child: const AddExpense(),
                  ),
                ),
              );

              if(newExpense != null) {
                setState(() {
                  expenses.insert(0, newExpense);
                });
                final provider = context.read<ExpenseProvider>();
                final repo = FirebaseExpenseRepo();
                await provider.fetchExpenses(repo);
              }
            },
            shape: const CircleBorder(),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.tertiary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.primary,
                  ],
                  transform: const GradientRotation(pi / 4),
                )
              ),
              child: const Icon(CupertinoIcons.add),
            ),
          ),
          body: index == 0 
            ? const MainScreen()
            : const StatScreen()
        );
      }
    );
  }
}
