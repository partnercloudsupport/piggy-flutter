import 'dart:async';

import 'package:flutter/material.dart';
import 'package:piggy_flutter/bloc/account_bloc.dart';
import 'package:piggy_flutter/bloc/category_bloc.dart';
import 'package:piggy_flutter/bloc/transaction_bloc.dart';
import 'package:piggy_flutter/bloc/user_bloc.dart';
import 'package:piggy_flutter/providers/account_provider.dart';
import 'package:piggy_flutter/providers/category_provider.dart';
import 'package:piggy_flutter/providers/transaction_provider.dart';
import 'package:piggy_flutter/providers/user_provider.dart';
import 'package:piggy_flutter/ui/page/account/account_list.dart';
import 'package:piggy_flutter/ui/page/home/recent.dart';
import 'package:piggy_flutter/ui/page/home/summary.dart';
import 'package:piggy_flutter/ui/widgets/common/common_drawer.dart';
import 'package:connectivity/connectivity.dart';

class NavigationIconView {
  NavigationIconView({
    Widget icon,
    Widget activeIcon,
    String title,
    Color color,
    TickerProvider vsync,
  })  : _icon = icon,
        _color = color,
        _title = title,
        item = new BottomNavigationBarItem(
          icon: icon,
//          activeIcon: activeIcon,
          title: new Text(title),
          backgroundColor: color,
        ),
        controller = new AnimationController(
          duration: kThemeAnimationDuration,
          vsync: vsync,
        ) {
    _animation = new CurvedAnimation(
      parent: controller,
      curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
    );
  }

  final Widget _icon;
  final Color _color;
  final String _title;
  final BottomNavigationBarItem item;
  final AnimationController controller;
  CurvedAnimation _animation;
}

enum StartPage { Recent, Accounts, Summary }

class HomePage extends StatefulWidget {
  final bool isInitialLoading;
  final StartPage startpage;

  HomePage(
      {Key key,
      this.isInitialLoading = false,
      this.startpage = StartPage.Recent})
      : super(key: key);

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  List<NavigationIconView> _navigationViews;

  final Key _keyRecentPage = PageStorageKey('recent');
  final Key _keyAccountsPage = PageStorageKey('accounts');
  final Key _keySummaryPage = PageStorageKey('summary');

  RecentPage _recent;
  SummaryPage _summary;
  AccountListPage _accounts;

  List<Widget> _pages;
  bool _isSyncRequired;

  /// This controller can be used to programmatically
  /// set the current displayed page
  PageController _pageController;
  final Connectivity _connectivity = new Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    _navigationViews = <NavigationIconView>[
      new NavigationIconView(
        icon: const Icon(Icons.format_list_bulleted),
        title: 'Recent',
        color: Colors.deepPurple,
        vsync: this,
      ),
      new NavigationIconView(
        icon: const Icon(Icons.account_circle),
        title: 'Accounts',
        color: Colors.teal,
        vsync: this,
      ),
      new NavigationIconView(
        icon: const Icon(Icons.dashboard),
        title: 'Dashboard',
        color: Colors.indigo,
        vsync: this,
      ),
    ];

    for (NavigationIconView view in _navigationViews)
      view.controller.addListener(_rebuild);

    _summary = new SummaryPage(key: _keySummaryPage);
    _recent = new RecentPage(
      key: _keyRecentPage,
    );
    _accounts = new AccountListPage(
      key: _keyAccountsPage,
    );

    _pageController = new PageController(initialPage: widget.startpage.index);

    _pages = [_recent, _accounts, _summary];
    _isSyncRequired = widget.isInitialLoading ?? false;
    _currentIndex = widget.startpage.index;
    _navigationViews[_currentIndex].controller.value = 1.0;
    super.initState();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        _isSyncRequired = true;
      } else {
        syncData(context);
      }
    });
  }

  syncData(BuildContext context) {
    if (_isSyncRequired) {
      final UserBloc userBloc = UserProvider.of(context);
      final TransactionBloc transactionBloc = TransactionProvider.of(context);
      final AccountBloc accountBloc = AccountProvider.of(context);
      final CategoryBloc categoryBloc = CategoryProvider.of(context);

      // print('##### syncing data');
      _isSyncRequired = false;
      userBloc.userRefresh(true);
      transactionBloc.recentTransactionsRefresh(true);
      transactionBloc.transactionSummaryRefresh('month');
      accountBloc.accountsRefresh(true);
      categoryBloc.refreshCategories(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    syncData(context);

    return new Scaffold(
      key: _scaffoldKey,
      body: new PageView(
          children: _pages,
          controller: _pageController,
          onPageChanged: onPageChanged),
      bottomNavigationBar: new BottomNavigationBar(
        items: _navigationViews
            .map((NavigationIconView navigationView) => navigationView.item)
            .toList(),
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.shifting,
        onTap: navigationTapped,
      ),
      drawer: CommonDrawer(),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    for (NavigationIconView view in _navigationViews) view.controller.dispose();
    super.dispose();
    _pageController.dispose();
  }

  void _rebuild() {
    setState(() {
      // Rebuild in order to animate views.
    });
  }

  /// Called when the user presses on of the
  /// [BottomNavigationBarItem] with corresponding
  /// page index
  void navigationTapped(int page) {
    // Animating to the page.
    // You can use whatever duration and curve you like
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 300), curve: Curves.ease);
  }

  void onPageChanged(int page) {
    setState(() {
      this._currentIndex = page;
    });
  }
}