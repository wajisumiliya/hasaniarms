import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';

import '../../core/network/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService api = ApiService();

  final TextEditingController memberController =
      TextEditingController(text: '000101020212');

  final TextEditingController passwordController =
      TextEditingController();

  Map<String, dynamic>? customer;
  Map<String, dynamic>? dashboard;

  String? errorMessage;

  bool loading = false;
  bool obscurePassword = true;

  String currentView = 'dashboard';

  static const Color blue = Color(0xff2358d8);
  static const Color darkBlue = Color(0xff153b99);
  static const Color background = Color(0xfff5f7fb);
  static const Color textDark = Color(0xff172033);
  static const Color textGrey = Color(0xff667085);

  static const String logoUrl =
      'https://raw.githubusercontent.com/wajisumiliya/hasaniarms/main/web/assets/hasani-books-logo.jpg';

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
      final response = await api.post(
        '/api/customer/login',
        {
          'membership': memberController.text.trim(),
          'password': passwordController.text,
        },
      );

      final customerData = response['customer'];

      if (customerData is! Map) {
        throw Exception(
          'Customer information was not returned.',
        );
      }

      final dashboardData =
          await api.get('/api/customer/dashboard');

      if (!mounted) return;

      setState(() {
        customer =
            Map<String, dynamic>.from(customerData);

        dashboard = dashboardData;
        errorMessage = null;
        currentView = 'dashboard';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> logout() async {
    try {
      await api.post(
        '/api/customer/logout',
        {},
      );
    } catch (_) {
      await api.clearSession();
    }

    if (!mounted) return;

    setState(() {
      customer = null;
      dashboard = null;
      errorMessage = null;
      currentView = 'dashboard';
      passwordController.clear();
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (customer == null) {
      return _buildLoginScreen();
    }

    return _buildApplication();
  }

  // ============================================================
  // LOGIN SCREEN
  // ============================================================

  Widget _buildLoginScreen() {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 28,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 460,
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        _buildLoginLogo(),

                        const SizedBox(height: 24),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'CUSTOMER PORTAL',
                            style: TextStyle(
                              color: blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Member Login',
                            style: TextStyle(
                              color: textDark,
                              fontSize: 32,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Sign in to view your Hasani Books '
                            'membership, points and purchase history.',
                            style: TextStyle(
                              color: textGrey,
                              fontSize: 14,
                              height: 1.55,
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              children: [
                                const Align(
                                  alignment:
                                      Alignment.centerLeft,
                                  child: Text(
                                    'Membership Card No.',
                                    style: TextStyle(
                                      color: textDark,
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                TextField(
                                  controller:
                                      memberController,
                                  keyboardType:
                                      TextInputType.number,
                                  textInputAction:
                                      TextInputAction.next,
                                  decoration:
                                      const InputDecoration(
                                    hintText:
                                        'Enter membership card number',
                                    prefixIcon: Icon(
                                      Icons.badge_outlined,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 18),

                                const Align(
                                  alignment:
                                      Alignment.centerLeft,
                                  child: Text(
                                    'Password',
                                    style: TextStyle(
                                      color: textDark,
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                TextField(
                                  controller:
                                      passwordController,
                                  obscureText:
                                      obscurePassword,
                                  textInputAction:
                                      TextInputAction.done,
                                  onSubmitted: (_) {
                                    if (!loading) {
                                      login();
                                    }
                                  },
                                  decoration:
                                      InputDecoration(
                                    hintText:
                                        'Enter your password',
                                    prefixIcon:
                                        const Icon(
                                      Icons.lock_outline,
                                    ),
                                    suffixIcon:
                                        IconButton(
                                      onPressed: () {
                                        setState(() {
                                          obscurePassword =
                                              !obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons
                                                .visibility_outlined
                                            : Icons
                                                .visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 22),

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: FilledButton(
                                    onPressed:
                                        loading
                                            ? null
                                            : login,
                                    child: loading
                                        ? const SizedBox(
                                            width: 23,
                                            height: 23,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color:
                                                  Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),

                                if (errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  _buildLoginError(),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: blue.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color: blue.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: blue,
                                size: 19,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'For testing, use your existing '
                                  'test membership and password.',
                                  style: TextStyle(
                                    color: theme
                                        .colorScheme
                                        .onSurface
                                        .withValues(
                                          alpha: 0.7,
                                        ),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'HASANI BOOKS',
                          style: TextStyle(
                            color: Color(0xff98a2b3),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginLogo() {
    return Container(
      width: 108,
      height: 108,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xffe4e7ec),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.07,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Image.network(
          logoUrl,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) {
            return Container(
              color: blue,
              alignment: Alignment.center,
              child: const Text(
                'HASANI\nBOOKS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APPLICATION SHELL
  // ============================================================

  Widget _buildApplication() {
    return Scaffold(
      backgroundColor: background,
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: _buildCurrentView(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          _smallLogo(),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'CUSTOMER PORTAL',
                style: TextStyle(
                  color: blue,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                _pageTitle(),
                style: const TextStyle(
                  color: textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 6),
          child: IconButton(
            tooltip: 'Logout',
            onPressed: logout,
            icon: const Icon(
              Icons.logout_outlined,
            ),
          ),
        ),
      ],
    );
  }

  String _pageTitle() {
    switch (currentView) {
      case 'purchases':
        return 'Purchase History';
      case 'points':
        return 'Member Points';
      case 'personal':
        return 'Personal Information';
      case 'rewards':
        return 'Rewards';
      case 'offers':
        return 'Offers';
      case 'store':
        return 'Online Store';
      case 'locations':
        return 'Locations';
      default:
        return 'Dashboard';
    }
  }

  // ============================================================
  // DRAWER
  // ============================================================

  Widget _buildDrawer() {
    final name =
        customer?['name']?.toString() ?? 'ARMS Customer';

    final membership =
        customer?['membership']?.toString() ?? '—';

    final initial = name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : 'A';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      _drawerLogo(),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'HASANI BOOKS',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: blue,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w700,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                membership,
                                style: const TextStyle(
                                  color: textGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                children: [
                  _drawerItem(
                    Icons.dashboard_outlined,
                    'Dashboard',
                    'dashboard',
                  ),
                  _drawerItem(
                    Icons.receipt_long_outlined,
                    'Purchase History',
                    'purchases',
                  ),
                  _drawerItem(
                    Icons.stars_outlined,
                    'Member Points',
                    'points',
                  ),
                  _drawerItem(
                    Icons.person_outline,
                    'Personal Information',
                    'personal',
                  ),
                  _drawerItem(
                    Icons.card_giftcard_outlined,
                    'Rewards',
                    'rewards',
                  ),
                  _drawerItem(
                    Icons.local_offer_outlined,
                    'Offers',
                    'offers',
                  ),
                  _drawerItem(
                    Icons.shopping_cart_outlined,
                    'Online Store',
                    'store',
                  ),
                  _drawerItem(
                    Icons.location_on_outlined,
                    'Locations',
                    'locations',
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.all(10),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                leading: const Icon(
                  Icons.logout_outlined,
                  color: Colors.red,
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title,
    String view,
  ) {
    final selected = currentView == view;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 2,
      ),
      child: ListTile(
        selected: selected,
        selectedTileColor:
            blue.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          icon,
          color: selected ? blue : textGrey,
        ),
        title: Text(
          title,
          style: TextStyle(
            color:
                selected ? blue : textDark,
            fontWeight: selected
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.pop(context);

          setState(() {
            currentView = view;
          });
        },
      ),
    );
  }

  Widget _drawerLogo() {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xffe4e7ec),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.network(
          logoUrl,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) {
            return const Icon(
              Icons.menu_book_rounded,
              color: blue,
            );
          },
        ),
      ),
    );
  }

  Widget _smallLogo() {
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xffe4e7ec),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.network(
          logoUrl,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) {
            return const Icon(
              Icons.menu_book_rounded,
              color: blue,
              size: 22,
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // CURRENT VIEW
  // ============================================================

  Widget _buildCurrentView() {
    switch (currentView) {
      case 'purchases':
        return _buildPurchasesPage();

      case 'points':
        return _buildPointsPage();

      case 'personal':
        return _buildPersonalPage();

      case 'rewards':
        return _buildRewardsPage();

      case 'offers':
        return _buildOffersPage();

      case 'store':
        return _buildStorePage();

      case 'locations':
        return _buildLocationsPage();

      default:
        return _buildDashboardPage();
    }
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Widget _buildDashboardPage() {
    final purchases =
        dashboard?['purchases'] as List? ?? [];

    final points = _numberValue(
      customer?['points'],
    );

    final totalSpend =
        _calculateTotalSpend(purchases);

    final name =
        customer?['name']?.toString() ??
            'ARMS Customer';

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          32,
        ),
        children: [
          // --------------------------------------------------------
          // WELCOME
          // --------------------------------------------------------

          const Text(
            'WELCOME BACK',
            style: TextStyle(
              color: blue,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            name,
            style: const TextStyle(
              color: textDark,
              fontSize: 29,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Your membership, points and purchases '
            'in one place.',
            style: TextStyle(
              color: textGrey,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // --------------------------------------------------------
          // MEMBER CARD
          // --------------------------------------------------------

          _memberCard(customer!),

          const SizedBox(height: 16),

          // --------------------------------------------------------
          // STATISTICS
          // --------------------------------------------------------

          _buildStats(
            points,
            totalSpend,
            purchases.length,
          ),

          const SizedBox(height: 26),

          // --------------------------------------------------------
          // QUICK ACCESS
          // --------------------------------------------------------

          const Text(
            'Quick Access',
            style: TextStyle(
              color: textDark,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 11),

          _buildQuickAccessGrid(),
        ],
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    try {
      final data =
          await api.get('/api/customer/dashboard');

      if (!mounted) return;

      setState(() {
        dashboard = data;
      });
    } catch (_) {
      // Keep existing dashboard data if refresh fails.
    }
  }

  // ============================================================
  // MEMBER CARD
  // ============================================================

  Widget _memberCard(
    Map<String, dynamic> data,
  ) {
    final name =
        data['name']?.toString() ?? 'Member';

    final membership =
        data['membership']?.toString() ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            blue,
            darkBlue,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: blue.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HASANI MEMBER',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      membership,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.14,
                  ),
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.18,
                    ),
                  ),
                ),
                child: const Text(
                  'MEMBER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 360;

              if (compact) {
                return Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _qrBox(membership),
                    const SizedBox(height: 14),
                    _barcodeBox(membership),
                  ],
                );
              }

              return Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  _qrBox(membership),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _barcodeBox(
                      membership,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _qrBox(String membership) {
    return Container(
      width: 104,
      height: 104,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: QrImageView(
        data: 'HASANI-MEMBER:$membership',
        size: 90,
      ),
    );
  }

  Widget _barcodeBox(String membership) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: BarcodeWidget(
        barcode: Barcode.code128(),
        data: membership.isEmpty
            ? 'HASANI'
            : membership,
        drawText: true,
        height: 60,
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStats(
    int points,
    double spend,
    int transactions,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _statCard(
            'Available Points',
            '$points',
            'Member points',
            Icons.stars_outlined,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _statCard(
            'Total Purchase',
            'RM ${spend.toStringAsFixed(2)}',
            'Verified data',
            Icons.payments_outlined,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _statCard(
            'Transactions',
            '$transactions',
            'Purchase records',
            Icons.receipt_long_outlined,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 145,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffeaecf0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.08),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: blue,
            ),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff98a2b3),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACCESS
  // ============================================================

  Widget _buildQuickAccessGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 11,
      mainAxisSpacing: 11,
      childAspectRatio: 1.55,
      children: [
        _featureCard(
          Icons.stars_outlined,
          'Member Points',
          'See points earned from purchases.',
          'points',
        ),
        _featureCard(
          Icons.card_giftcard_outlined,
          'Rewards',
          'View available member rewards.',
          'rewards',
        ),
        _featureCard(
          Icons.local_offer_outlined,
          'Offers',
          'Explore member offers.',
          'offers',
        ),
        _featureCard(
          Icons.shopping_cart_outlined,
          'Online Store',
          'Continue to online shopping.',
          'store',
        ),
        _featureCard(
          Icons.location_on_outlined,
          'Locations',
          'Find Hasani Books branches.',
          'locations',
        ),
        _featureCard(
          Icons.receipt_long_outlined,
          'Purchases',
          'View your purchase history.',
          'purchases',
        ),
      ],
    );
  }

  Widget _featureCard(
    IconData icon,
    String title,
    String subtitle,
    String view,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            currentView = view;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xffeaecf0),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      blue.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: blue,
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _pageHeader(
    String eyebrow,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        16,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: const TextStyle(
              color: blue,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 29,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            style: const TextStyle(
              color: textGrey,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PURCHASE HISTORY
  // ============================================================

  Widget _buildPurchasesPage() {
    final purchases =
        dashboard?['purchases'] as List? ?? [];

    return ListView(
      padding: const EdgeInsets.only(
        bottom: 30,
      ),
      children: [
        _pageHeader(
          'MEMBER ACTIVITY',
          'Purchase History',
          'Transactions associated with your membership.',
        ),
        if (purchases.isEmpty)
          _emptyState(
            Icons.receipt_long_outlined,
            'No purchases found',
            'There are currently no purchase records '
                'available for this membership.',
          ),
        ...purchases.map(
          (purchase) {
            if (purchase is! Map) {
              return const SizedBox.shrink();
            }

            final p =
                Map<String, dynamic>.from(
              purchase,
            );

            return _purchaseCard(p);
          },
        ),
      ],
    );
  }

  Widget _purchaseCard(
    Map<String, dynamic> purchase,
  ) {
    final total =
        _doubleValue(purchase['total']);

    final receipt =
        purchase['receiptNo']?.toString() ?? '-';

    final date =
        purchase['date']?.toString() ?? '-';

    final points =
        purchase['points']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 5,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffeaecf0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.08),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Receipt #$receipt',
                  style: const TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date · +$points points',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'RM ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // POINTS
  // ============================================================

  Widget _buildPointsPage() {
    final purchases =
        dashboard?['purchases'] as List? ?? [];

    final points =
        _numberValue(customer?['points']);

    final spend =
        _calculateTotalSpend(purchases);

    return ListView(
      padding: const EdgeInsets.only(
        bottom: 30,
      ),
      children: [
        _pageHeader(
          'LOYALTY',
          'Member Points',
          'Track purchase value and points earned.',
        ),

        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                blue,
                darkBlue,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'CURRENT POINTS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$points',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _whiteMetric(
                      'Purchase Value',
                      'RM ${spend.toStringAsFixed(2)}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _whiteMetric(
                      'Points Earned',
                      '$points',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 18,
          ),
          child: Text(
            'Purchase Points',
            style: TextStyle(
              color: textDark,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(height: 8),

        if (purchases.isEmpty)
          _emptyState(
            Icons.stars_outlined,
            'No points activity',
            'Purchase activity will appear here.',
          ),

        ...purchases.map(
          (purchase) {
            if (purchase is! Map) {
              return const SizedBox.shrink();
            }

            final p =
                Map<String, dynamic>.from(
              purchase,
            );

            return _pointsRow(p);
          },
        ),
      ],
    );
  }

  Widget _whiteMetric(
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _pointsRow(
    Map<String, dynamic> purchase,
  ) {
    final points =
        purchase['points']?.toString() ?? '0';

    final receipt =
        purchase['receiptNo']?.toString() ?? '-';

    final date =
        purchase['date']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 5,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xffeaecf0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.stars_outlined,
            color: blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Receipt #$receipt',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+$points',
            style: const TextStyle(
              color: blue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERSONAL INFORMATION
  // ============================================================

  Widget _buildPersonalPage() {
    final data = customer ?? {};

    final fields = <Map<String, String>>[
      {
        'label': 'Member Name',
        'value': _displayValue(
          data['name'],
        ),
      },
      {
        'label': 'Membership Card No.',
        'value': _displayValue(
          data['membership'],
        ),
      },
      {
        'label': 'Points',
        'value': _displayValue(
          data['points'],
        ),
      },
      {
        'label': 'Email',
        'value': _displayValue(
          data['email'],
        ),
      },
      {
        'label': 'Phone',
        'value': _displayValue(
          data['phone'],
        ),
      },
      {
        'label': 'Branch',
        'value': _displayValue(
          data['branch'],
        ),
      },
    ];

    return ListView(
      padding: const EdgeInsets.only(
        bottom: 30,
      ),
      children: [
        _pageHeader(
          'ARMS MEMBER',
          'Personal Information',
          'Member information returned from ARMS.',
        ),
        ...fields.map(
          (field) => _infoRow(
            field['label']!,
            field['value']!,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    String label,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 5,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xffeaecf0),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REWARDS
  // ============================================================

  Widget _buildRewardsPage() {
    return ListView(
      padding: const EdgeInsets.only(
        bottom: 30,
      ),
      children: [
        _pageHeader(
          'MEMBERSHIP BENEFITS',
          'Rewards',
          'Rewards available for your membership.',
        ),
        _benefitCard(
          Icons.card_giftcard_outlined,
          'Member Rewards',
          'Your available rewards will appear here '
              'when provided by the membership system.',
        ),
        _benefitCard(
          Icons.stars_outlined,
          'Earn More Points',
          'Continue shopping and earning points '
              'with your Hasani membership.',
        ),
      ],
    );
  }

  // ============================================================
  // OFFERS
  // ============================================================

  Widget _buildOffersPage() {
    return ListView(
      padding: const EdgeInsets.only(
        bottom: 30,
      ),
      children: [
        _pageHeader(
          'SPECIAL OFFERS',
          'Offers',
          'Member offers and promotions.',
        ),
        _benefitCard(
          Icons.local_offer_outlined,
          'Member Offers',
          'Special offers and promotions will '
              'appear here when available.',
        ),
        _benefitCard(
          Icons.campaign_outlined,
          'Latest Promotions',
          'Check back for the latest Hasani Books '
              'member promotions.',
        ),
      ],
    );
  }

  Widget _benefitCard(
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 6,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xffeaecf0),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.08),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: blue,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ONLINE STORE
  // ============================================================

  Widget _buildStorePage() {
    return ListView(
      padding: const EdgeInsets.only(
        bottom: 30,
      ),
      children: [
        _pageHeader(
          'SHOP ONLINE',
          'Online Store',
          'Online shopping access.',
        ),
        _emptyFeature(
          Icons.shopping_cart_outlined,
          'Hasani Books Online Store',
          'Continue shopping at the official '
              'Hasani Books online store.',
          'Shop Online',
        ),
      ],
    );
  }

  // ============================================================
  // LOCATIONS
  // ============================================================

  Widget _buildLocationsPage() {
    return ListView(
      padding: const EdgeInsets.only(
        bottom: 30,
      ),
      children: [
        _pageHeader(
          'FIND US',
          'Locations',
          'Find Hasani Books branches.',
        ),
        _emptyFeature(
          Icons.location_on_outlined,
          'Hasani Books Locations',
          'Find Hasani Books stores and branches.',
          'Find a Store',
        ),
      ],
    );
  }

  Widget _emptyFeature(
    IconData icon,
    String title,
    String description,
    String buttonText,
  ) {
    return Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xffeaecf0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: blue,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () {
                _showComingSoon(buttonText);
              },
              icon: Icon(
                buttonText == 'Shop Online'
                    ? Icons.open_in_new
                    : Icons.location_on_outlined,
              ),
              label: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: const Text(
            'This feature will be connected to the '
            'Hasani Books service in the next step.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState(
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        18,
        8,
        18,
        12,
      ),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xffeaecf0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xff98a2b3),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _displayValue(dynamic value) {
    if (value == null) return '—';

    final text = value.toString().trim();

    if (text.isEmpty) return '—';

    return text;
  }

  double _calculateTotalSpend(List purchases) {
    double total = 0;

    for (final item in purchases) {
      if (item is Map) {
        total += _doubleValue(
          item['total'],
        );
      }
    }

    return total;
  }

  int _numberValue(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double _doubleValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}
