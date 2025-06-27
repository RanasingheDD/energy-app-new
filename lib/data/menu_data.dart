import 'package:flutter/material.dart';
import 'package:myapp/models/menu_model.dart';
import 'package:myapp/pages/analytics.dart';
import 'package:myapp/pages/home_page.dart';
import 'package:myapp/pages/settings_page.dart';
import 'package:myapp/pages/table.dart';
import 'package:myapp/report/fetch_report.dart';

class SideMenuData {
  final menu = <MenuModel>[
    MenuModel(icon: Icons.home, title: 'Dashboard', page: const HomePage(title: '',)),
    MenuModel(
      icon: Icons.devices,
      title: 'Analytics',
      page:  SensorDataPage()),
    //MenuModel(icon: Icons.receipt, title: 'History', page: ReportListPage()),
    MenuModel(
      icon: Icons.settings,
      title: 'Settings',
      page: const SettingsPage(),
    ),
  ];
}
