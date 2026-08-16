import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';

import '../../core/network/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService();

  final TextEditingController memberController =
      TextEditingController(text: '000101020212');

  final TextEditingController passwordController =
      TextEditingController(text: '123123');

  Map<String, dynamic>? customer;
  Map<String, dynamic>? dashboard;

  String? errorMessage;
  bool loading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    memberController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login() async {
    if (loading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final membership = memberController.text.trim();
      final password = passwordController.text;

      if (membership.isEmpty) {
        throw Exception('Please enter your membership card number.');
      }

      if (password.isEmpty) {
        throw Exception('Please enter your password.');
      }

      final response = await api.post(
        '/api/customer/login',
        {
          'membership': membership,
          'password': password,
        },
      );

      if (response['customer'] == null) {
        throw Exception('Login succeeded but customer information was not returned.');
      }

      final customerData =
          Map<String, dynamic>.from(response['customer'] as Map);

      Map<String, dynamic> dashboardData = {};

      try {
        final dashboardResponse =
            await api.get('/api/customer/dashboard');

        if (dashboardResponse is Map) {
          dashboardData =
              Map<String, dynamic>.from(dashboardResponse);
        }
      } catch (_) {
        // Login can still continue if dashboard request fails.
        dashboardData = {};
      }

      if (!mounted) return;

      setState(() {
        customer = customerData;
        dashboard = dashboardData;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = _cleanError(e);
      });
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      await api.post(
        '/api/customer/logout',
        {},
      );
    } catch (_) {
      // Continue with local logout even if API logout fails.
    }

    try {
      await api.clearSession();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      customer = null;
      dashboard = null;
      errorMessage = null;
    });
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }

    return text;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  String _money(dynamic value) {
    return _toDouble(value).toStringAsFixed(2);
  }

  List<dynamic> _getPurchases() {
    final data = dashboard?['purchases'];

    if (data is List) {
      return data;
    }

    return <dynamic>[];
  }

  int _getPoints() {
    return _toInt(customer?['points']);
  }

  double _getTotalSpend(List<dynamic> purchases) {
    double total = 0;

    for (final purchase in purchases) {
      if (purchase is Map) {
        total += _toDouble(purchase['total']);
      }
    }

    return total;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (customer == null) {
      return _buildLoginScreen();
    }

    return _buildDashboardScreen();
  }

  // ============================================================
  // LOGIN SCREEN
  // ============================================================

  Widget _buildLoginScreen() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo / icon
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: const Color(0xff2358d8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Center(
                        child: Text(
                          'Hasani Customer',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Center(
                        child: Text(
                          'Member Login',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      TextField(
                        controller: memberController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Membership Card Number',
                          hintText: 'Enter membership number',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(
                            borderRadius: Border
