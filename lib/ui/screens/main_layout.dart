import 'package:flutter/material.dart';

import '../widgets/bottom_nav_bar.dart';
import 'expenses_screen.dart';
import 'home_screen.dart';
import 'inventory_screen.dart';
import 'profile_screen.dart';
import 'sell_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _pageController = PageController(initialPage: _currentIndex);
  }

  late final List<Widget> _screens = [
    HomeScreen(
      onQuickSell: () => _onTabTapped(1),
      onOpenSettings: _openSettings,
    ),
    SellScreen(
      onSaleComplete: () => _onTabTapped(0),
    ),
    const InventoryScreen(),
    const ExpensesScreen(),
    const ProfileScreen(),
  ];

  void _openSettings() {
    Navigator.of(context).pushNamed('/settings');
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
