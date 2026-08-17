import 'package:flutter/material.dart';
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
      TextEditingController();

  Map<String, dynamic>? customer;
  Map<String, dynamic>? dashboard;

  String? errorMessage;

  bool loading = false;
  bool obscurePassword = true;

  String currentView = 'dashboard';

  // ============================================================
  // HASANI BOOKS COLORS
  // ============================================================

  static const Color blue = Color(0xff263d92);
  static const Color blue2 = Color(0xff30479e);
  static const Color blue3 = Color(0xff24377f);
  static const Color red = Color(0xffed2634);
  static const Color darkText = Color(0xff172033);
  static const Color mutedText = Color(0xff748096);
  static const Color pageBackground = Color(0xfff5f7fb);

  static const String logoAsset =
      'web/assets/hasani-books-logo.jpg';

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
        currentView = 'dashboard';
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '');
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
      backgroundColor: pageBackground,
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
                              color: Color(0xff2358d8),
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
                              color: darkText,
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
                              color: mutedText,
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
                                      color: darkText,
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
                                      color: darkText,
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
                                        loading ? null : login,
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(
                                        milliseconds: 180,
                                      ),
                                      child: loading
                                          ? const SizedBox(
                                              key: ValueKey(
                                                'loading',
                                              ),
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
                                              key: ValueKey(
                                                'login',
                                              ),
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
                            color:
                                const Color(0xff2358d8)
                                    .withValues(alpha: .06),
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  const Color(0xff2358d8)
                                      .withValues(alpha: .12),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xff2358d8),
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
                                        .withValues(alpha: .7),
                                    fontSize: 12,
                                    height: 1.4,
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

  // ============================================================
  // LOGIN LOGO
  // ============================================================

  Widget _buildLoginLogo() {
    return Container(
      width: 250,
      height: 100,
      padding: const EdgeInsets.all(8),
      child: Image.asset(
        logoAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return const Text(
            'hasani BOOKS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: blue,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // LOGIN ERROR
  // ============================================================

  Widget _buildLoginError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: .18),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage ?? '',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APPLICATION
  // ============================================================

  Widget _buildApplication() {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: _buildCurrentView(),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      titleSpacing: 18,
      title: SizedBox(
        width: 110,
        height: 42,
        child: Image.asset(
          logoAsset,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          errorBuilder: (_, __, ___) {
            return const Text(
              'HASANI BOOKS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: blue,
                fontSize: 15,
              ),
            );
          },
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Logout',
          onPressed: logout,
          icon: const Icon(
            Icons.logout,
            color: darkText,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================

  Widget _buildDrawer() {
    final name =
        customer?['name']?.toString() ?? 'Member';

    final membership = _membershipNumber();

    return Drawer(
      backgroundColor: Colors.white,
      width: 360,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // LOGO ONLY
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      22,
                      20,
                      18,
                    ),
                    child: SizedBox(
                      height: 60,
                      width: double.infinity,
                      child: Image.asset(
                        logoAsset,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        errorBuilder:
                            (_, __, ___) {
                          return const Icon(
                            Icons.menu_book,
                            color: blue,
                            size: 35,
                          );
                        },
                      ),
                    ),
                  ),

                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xfff4f6fb),
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: blue,
                            child: Text(
                              _initial(name),
                              style:
                                  const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
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
                                  style:
                                      const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w800,
                                    color: darkText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  membership,
                                  style:
                                      const TextStyle(
                                    color: mutedText,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  _drawerItem(
                    icon: Icons.grid_view_rounded,
                    title: 'Dashboard',
                    view: 'dashboard',
                  ),

                  _drawerItem(
                    icon:
                        Icons.receipt_long_outlined,
                    title: 'Purchase History',
                    view: 'purchases',
                  ),

                  _drawerItem(
                    icon: Icons.stars_outlined,
                    title: 'Member Points',
                    view: 'points',
                  ),

                  _drawerItem(
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    view: 'personal',
                  ),

                  _drawerItem(
                    icon:
                        Icons.card_giftcard_outlined,
                    title: 'Rewards',
                    view: 'rewards',
                  ),

                  _drawerItem(
                    icon:
                        Icons.local_offer_outlined,
                    title: 'Offers',
                    view: 'offers',
                  ),

                  _drawerItem(
                    icon:
                        Icons.shopping_cart_outlined,
                    title: 'Online Store',
                    view: 'store',
                  ),

                  _drawerItem(
                    icon:
                        Icons.location_on_outlined,
                    title: 'Locations',
                    view: 'locations',
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 10,
              ),
              leading: const Icon(
                Icons.logout,
                color: Color(0xffe3483e),
                size: 30,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xffe3483e),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required String view,
  }) {
    final active = currentView == view;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 3,
      ),
      child: Material(
        color: active
            ? const Color(0xffeef3ff)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(18),
          onTap: () {
            Navigator.pop(context);

            setState(() {
              currentView = view;
            });
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 19,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: active
                      ? const Color(0xff315ec9)
                      : const Color(0xff687386),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: active
                          ? const Color(0xff315ec9)
                          : darkText,
                      fontSize: 17,
                      fontWeight: active
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

      case 'dashboard':
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

    final points =
        _numberValue(customer?['points']);

    double totalSpend = 0;

    for (final item in purchases) {
      if (item is Map) {
        totalSpend +=
            _doubleValue(item['total']);
      }
    }

    final name =
        customer?['name']?.toString() ??
            'Member';

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          20,
          16,
          40,
        ),
        children: [
          const Text(
            'HASANI BOOKS MEMBER',
            style: TextStyle(
              color: Color(0xff7c879c),
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Welcome Back, $name',
            style: const TextStyle(
              color: darkText,
              fontSize: 29,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Your membership, points and purchases in one place.',
            style: TextStyle(
              color: mutedText,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          _buildFrontMembershipCard(),

          const SizedBox(height: 8),

          _cardLabel('FRONT'),

          const SizedBox(height: 22),

          _buildBackMembershipCard(),

          const SizedBox(height: 8),

          _cardLabel('BACK'),

          const SizedBox(height: 22),

          _buildBarcodeSection(),

          const SizedBox(height: 22),

          _buildStatistics(
            points: points,
            totalSpend: totalSpend,
            transactionCount: purchases.length,
          ),

          const SizedBox(height: 28),

          const Text(
            'Quick Access',
            style: TextStyle(
              color: darkText,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 12),

          _quickAccessTile(
            icon: Icons.receipt_long_outlined,
            title: 'Purchase History',
            subtitle: 'View your purchases',
            onTap: () {
              setState(() {
                currentView = 'purchases';
              });
            },
          ),

          _quickAccessTile(
            icon: Icons.stars_outlined,
            title: 'Member Points',
            subtitle: 'Points earned from purchases',
            onTap: () {
              setState(() {
                currentView = 'points';
              });
            },
          ),

          _quickAccessTile(
            icon: Icons.person_outline,
            title: 'Personal Information',
            subtitle: 'View your member details',
            onTap: () {
              setState(() {
                currentView = 'personal';
              });
            },
          ),

          _quickAccessTile(
            icon:
                Icons.card_giftcard_outlined,
            title: 'Rewards',
            subtitle: 'Member rewards',
            onTap: () {
              setState(() {
                currentView = 'rewards';
              });
            },
          ),

          _quickAccessTile(
            icon:
                Icons.local_offer_outlined,
            title: 'Offers',
            subtitle: 'Special offers',
            onTap: () {
              setState(() {
                currentView = 'offers';
              });
            },
          ),

          _quickAccessTile(
            icon:
                Icons.shopping_cart_outlined,
            title: 'Online Store',
            subtitle: 'Shop online',
            onTap: () {
              setState(() {
                currentView = 'store';
              });
            },
          ),

          _quickAccessTile(
            icon:
                Icons.location_on_outlined,
            title: 'Locations',
            subtitle: 'Find Hasani Books branches',
            onTap: () {
              setState(() {
                currentView = 'locations';
              });
            },
          ),
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
    } catch (_) {}
  }

  // ============================================================
  // FRONT MEMBERSHIP CARD
  // ============================================================

  Widget _buildFrontMembershipCard() {
    final name =
        customer?['name']?.toString() ??
            'ARMS Customer';

    final membership =
        _membershipNumber();

    final expiry =
        _firstValue([
      customer?['expiry'],
      customer?['expiryDate'],
      customer?['cardExpiry'],
      customer?['membershipExpiry'],
    ]) ??
        '—';

    final branch =
        _firstValue([
      customer?['issueBranch'],
      customer?['branch'],
      customer?['issue_branch'],
      customer?['branchName'],
    ]) ??
        '—';

    return _cardFrame(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = width * 53.98 / 85.60;

          return SizedBox(
            height: height,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // BLUE HEADER
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: height * .43,
                  child: Container(
                    decoration:
                        const BoxDecoration(
                      gradient: LinearGradient(
                        begin:
                            Alignment.centerLeft,
                        end:
                            Alignment.centerRight,
                        colors: [
                          blue,
                          blue2,
                          blue3,
                        ],
                      ),
                    ),
                  ),
                ),

                // LOGO
                Positioned(
                  left: width * .05,
                  top: height * .035,
                  width: width * .67,
                  height: height * .23,
                  child: Image.asset(
                    logoAsset,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    errorBuilder:
                        (_, __, ___) {
                      return const Text(
                        'hasani BOOKS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.w900,
                          fontSize: 18,
                        ),
                      );
                    },
                  ),
                ),

                // DISCOUNT CARD
                Positioned(
                  left: width * .055,
                  bottom: height * .045,
                  child: Text(
                    'DISCOUNT CARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize:
                          (height * .105)
                              .clamp(8.0, 20.0),
                      height: 1,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: .25,
                    ),
                  ),
                ),

                // SMALL % DECORATION
                Positioned(
                  right: width * .055,
                  top: height * .035,
                  child: Text(
                    '%',
                    style: TextStyle(
                      color:
                          Colors.white.withValues(
                        alpha: .10,
                      ),
                      fontSize:
                          height * .22,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),

                // RED DIVIDER
                Positioned(
                  left: 0,
                  right: 0,
                  top: height * .43,
                  height: 4,
                  child: Container(
                    color: red,
                  ),
                ),

                // WHITE BODY
                Positioned(
                  left: 0,
                  right: 0,
                  top: height * .43 + 4,
                  bottom: 0,
                  child: Container(
                    color: Colors.white,
                  ),
                ),

                // MEMBER INFORMATION
                Positioned(
                  left: width * .055,
                  top: height * .485,
                  width: width * .56,
                  bottom: height * .045,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _cardField(
                        'MEMBER NAME',
                        name,
                        height,
                        allowFullName: true,
                      ),
                      _cardField(
                        'MEMBER ID',
                        membership,
                        height,
                      ),
                      _cardField(
                        'EXPIRY DATE',
                        expiry,
                        height,
                      ),
                      _cardField(
                        'ISSUE BRANCH',
                        branch,
                        height,
                      ),
                    ],
                  ),
                ),

                // BARCODE ON CARD
                Positioned(
                  right: width * .035,
                  bottom: height * .065,
                  width: width * .36,
                  height: height * .27,
                  child: _membershipBarcode(
                    membership,
                    showText: true,
                    border: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // BACK MEMBERSHIP CARD
  // ============================================================

  Widget _buildBackMembershipCard() {
    return _cardFrame(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = width * 53.98 / 85.60;

          return SizedBox(
            height: height,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // WHITE BASE
                Positioned.fill(
                  child: Container(
                    color: Colors.white,
                  ),
                ),

                // BLUE HEADER
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: height * .21,
                  child: Container(
                    decoration:
                        const BoxDecoration(
                      gradient: LinearGradient(
                        begin:
                            Alignment.centerLeft,
                        end:
                            Alignment.centerRight,
                        colors: [
                          blue,
                          blue2,
                          blue3,
                        ],
                      ),
                    ),
                  ),
                ),

                // SOCIAL ICONS
                Positioned(
                  left: width * .035,
                  top: height * .045,
                  child: Row(
                    children: [
                      _socialCircle(Icons.facebook),
                      const SizedBox(width: 4),
                      _socialCircle(
                        Icons.camera_alt_outlined,
                      ),
                      const SizedBox(width: 4),
                      _socialCircle(Icons.music_note),
                      const SizedBox(width: 4),
                      _socialCircle(Icons.chat),
                    ],
                  ),
                ),

                // HASANI BOOKS + PHONE
                Positioned(
                  left: width * .205,
                  right: width * .035,
                  top: height * .038,
                  height: height * .10,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'hasaniBOOKS  |  +60 19-475 7733',
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            height * .058,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                // SMALL LOGO ON RIGHT
                Positioned(
                  right: width * .035,
                  top: height * .025,
                  width: width * .20,
                  height: height * .14,
                  child: Image.asset(
                    logoAsset,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                    errorBuilder:
                        (_, __, ___) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),

                // RED LINE
                Positioned(
                  left: 0,
                  right: 0,
                  top: height * .21,
                  height: 3,
                  child: Container(
                    color: red,
                  ),
                ),

                // HORIZONTAL MEMBER DISCOUNT CARD
                Positioned(
                  left: width * .055,
                  right: width * .055,
                  top: height * .235,
                  height: height * .08,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'MEMBER DISCOUNT CARD',
                      maxLines: 1,
                      style: TextStyle(
                        color: blue,
                        fontSize:
                            height * .060,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: .2,
                      ),
                    ),
                  ),
                ),

                // TERMS
                Positioned(
                  left: width * .055,
                  right: width * .055,
                  top: height * .315,
                  bottom: height * .155,
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _backRule(
                        'Kad ini bukan kad kredit.',
                        height,
                      ),
                      _backRule(
                        'Kad ini tidak boleh ditunaikan.',
                        height,
                      ),
                      _backRule(
                        'Pemilik kad ini boleh mendapat diskaun bagi '
                        'buku dan alat tulis yang terpilih sahaja.',
                        height,
                      ),
                      _backRule(
                        'Sila gunakan kad ini di semua cawangan '
                        'Hasani Books untuk menikmati potongan diskaun.',
                        height,
                      ),
                      _backRule(
                        'Kad ini hak milik Hasani Books.',
                        height,
                      ),
                      _backRule(
                        'Kegunaannya adalah tertakluk kepada syarat '
                        '& peraturan yang lazim digunakan. Jika terjumpa, '
                        'sila kembalikan kad ini kepada Hasani Books.',
                        height,
                      ),
                    ],
                  ),
                ),

                // FOOTER
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: height * .145,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: width * .045,
                      vertical: 3,
                    ),
                    decoration:
                        const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xff353d99),
                          Color(0xff3d3ca0),
                        ],
                      ),
                      border: Border(
                        top: BorderSide(
                          color: red,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _fitFooterText(
                          'Hasani Edar Sdn. Bhd.',
                          height * .045,
                        ),
                        _fitFooterText(
                          '41A–47A, Jalan Pengkalan, Taman Pekan Baru,',
                          height * .034,
                        ),
                        _fitFooterText(
                          '08000 Sungai Petani, Kedah Darul Aman.',
                          height * .034,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _fitFooterText(
    String text,
    double fontSize,
  ) {
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize.clamp(6.0, 14.0),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARD HELPERS
  // ============================================================

  Widget _cardFrame({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xffdfe4ee),
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xff14203c)
                    .withValues(alpha: .16),
            blurRadius: 32,
            offset:
                const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _cardLabel(String text) {
    return Center(
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: const Color(0xffeef1f6),
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xff59657a),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _cardField(
    String label,
    String value,
    double cardHeight, {
    bool allowFullName = false,
  }) {
    final valueSize =
        allowFullName
            ? (cardHeight * .052).clamp(7.0, 16.0)
            : (cardHeight * .052).clamp(7.0, 16.0);

    return Padding(
      padding:
          EdgeInsets.only(
        bottom: cardHeight * .018,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: blue,
              fontSize:
                  (cardHeight * .032)
                      .clamp(6.0, 11.0),
              height: 1,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color:
                      const Color(0xff111111),
                  fontSize: valueSize,
                  height: 1.1,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backRule(
    String text,
    double cardHeight,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: const Color(0xff101010),
          fontSize:
              (cardHeight * .030)
                  .clamp(5.5, 9.5),
          height: 1.05,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  Widget _socialCircle(
    IconData icon,
  ) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xff181818),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: Colors.white,
        size: 9,
      ),
    );
  }

  // ============================================================
  // MEMBERSHIP BARCODE
  // ============================================================

  Widget _membershipBarcode(
    String membership, {
    bool showText = true,
    bool border = false,
  }) {
    final barcode = BarcodeWidget(
      barcode: Barcode.code128(),
      data: membership.isEmpty
          ? '000000000000'
          : membership,
      drawText: showText,
      style: const TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
      errorBuilder:
          (context, error) {
        return Center(
          child: Text(
            membership,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );

    if (!border) {
      return barcode;
    }

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        5,
        5,
        5,
        3,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xff8994a8),
          width: 1.2,
        ),
        borderRadius:
            BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: .14,
            ),
            blurRadius: 7,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: barcode,
    );
  }

  // ============================================================
  // BARCODE SECTION
  // ============================================================

  Widget _buildBarcodeSection() {
    final membership =
        _membershipNumber();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xffe8ebf2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Membership Barcode',
              style: TextStyle(
                color: darkText,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Show this barcode when your membership '
              'needs to be verified.',
              style: TextStyle(
                color: mutedText,
                fontSize: 12,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              height: 105,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(10),
                border: Border.all(
                  color:
                      const Color(0xffdfe4ee),
                ),
              ),
              child: _membershipBarcode(
                membership,
                showText: true,
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: Text(
                membership,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics({
    required int points,
    required double totalSpend,
    required int transactionCount,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'Available Points',
                value: '$points',
                subtitle: 'Member points',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                title: 'Total Purchase',
                value:
                    'RM ${totalSpend.toStringAsFixed(2)}',
                subtitle:
                    'Verified transaction data',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _statCard(
          title: 'Transactions',
          value: '$transactionCount',
          subtitle: 'Purchase records',
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffe8ebf2),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff788398),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: darkText,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xff8b94a6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACCESS
  // ============================================================

  Widget _quickAccessTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xffe8ebf2),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 5,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: blue.withValues(
              alpha: .08,
            ),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: blue,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: mutedText,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xff687386),
        ),
        onTap: onTap,
      ),
    );
  }

  // ============================================================
  // PURCHASE HISTORY
  // ============================================================

  Widget _buildPurchasesPage() {
    final purchases =
        dashboard?['purchases'] as List? ?? [];

    return _pageScroll(
      children: [
        _pageHeading(
          eyebrow: 'MEMBER ACTIVITY',
          title: 'Purchase History',
          description:
              'Your Hasani Books purchase records.',
        ),

        if (purchases.isEmpty)
          _emptyFeature(
            icon: Icons.receipt_long_outlined,
            title: 'No purchases found',
            description:
                'There are no purchase records available.',
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

            final total =
                _doubleValue(p['total']);

            return Card(
              elevation: 0,
              margin:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
                side: const BorderSide(
                  color: Color(0xffe8ebf2),
                ),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor:
                      blue.withValues(
                    alpha: .08,
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: blue,
                  ),
                ),
                title: Text(
                  'Receipt #${p['receiptNo'] ?? '-'}',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w800,
                    color: darkText,
                  ),
                ),
                subtitle: Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 5,
                  ),
                  child: Text(
                    '${p['date'] ?? '-'}  •  '
                    '+${p['points'] ?? 0} points',
                    style:
                        const TextStyle(
                      color: mutedText,
                      fontSize: 12,
                    ),
                  ),
                ),
                trailing: Text(
                  'RM ${total.toStringAsFixed(2)}',
                  style:
                      const TextStyle(
                    color: darkText,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // POINTS PAGE
  // ============================================================

  Widget _buildPointsPage() {
    final points =
        _numberValue(customer?['points']);

    final purchases =
        dashboard?['purchases'] as List? ?? [];

    double spend = 0;

    for (final item in purchases) {
      if (item is Map) {
        spend +=
            _doubleValue(item['total']);
      }
    }

    return _pageScroll(
      children: [
        _pageHeading(
          eyebrow: 'MEMBERSHIP BENEFITS',
          title: 'Member Points',
          description:
              'Your available Hasani Books member points.',
        ),

        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'Available Points',
                value: '$points',
                subtitle: 'Current balance',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                title: 'Purchase Value',
                value:
                    'RM ${spend.toStringAsFixed(2)}',
                subtitle: 'Verified purchases',
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        _simpleInformationCard(
          icon: Icons.stars_outlined,
          title: 'Points Earned',
          description:
              'Points are calculated from your recorded purchases.',
          value: '$points points',
        ),
      ],
    );
  }

  // ============================================================
  // PERSONAL INFORMATION
  // ============================================================

  Widget _buildPersonalPage() {
    final data = customer ?? {};

    final fields = <Map<String, String>>[
      {
        'label': 'Full Name',
        'value':
            data['name']?.toString() ?? '—',
      },
      {
        'label': 'Membership Card',
        'value': _membershipNumber(),
      },
      {
        'label': 'Points',
        'value':
            '${_numberValue(data['points'])}',
      },
      {
        'label': 'Expiry Date',
        'value':
            _firstValue([
                  data['expiry'],
                  data['expiryDate'],
                  data['cardExpiry'],
                ]) ??
                '—',
      },
      {
        'label': 'Issue Branch',
        'value':
            _firstValue([
                  data['issueBranch'],
                  data['branch'],
                  data['branchName'],
                ]) ??
                '—',
      },
      {
        'label': 'Email',
        'value':
            _firstValue([
                  data['email'],
                  data['emailAddress'],
                ]) ??
                '—',
      },
      {
        'label': 'Phone',
        'value':
            _firstValue([
                  data['phone'],
                  data['mobile'],
                  data['mobilePhone'],
                ]) ??
                '—',
      },
      {
        'label': 'Address',
        'value':
            _firstValue([
                  data['address'],
                  data['addressLine1'],
                ]) ??
                '—',
      },
    ];

    return _pageScroll(
      children: [
        _pageHeading(
          eyebrow: 'HASANI MEMBER',
          title: 'Personal Information',
          description:
              'Member information returned from the customer account.',
        ),

        ...fields.map(
          (field) => Container(
            width: double.infinity,
            margin:
                const EdgeInsets.only(
              bottom: 10,
            ),
            padding:
                const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color:
                    const Color(0xffe8ebf2),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  field['label']!,
                  style:
                      const TextStyle(
                    color: Color(0xff788398),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  field['value']!,
                  style:
                      const TextStyle(
                    color: darkText,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REWARDS
  // ============================================================

  Widget _buildRewardsPage() {
    return _featurePage(
      eyebrow: 'MEMBERSHIP BENEFITS',
      title: 'Rewards',
      description:
          'Rewards available for your membership.',
      icon: Icons.card_giftcard_outlined,
      featureTitle: 'Member Rewards',
      featureDescription:
          'Your Hasani Books membership rewards will appear here.',
    );
  }

  // ============================================================
  // OFFERS
  // ============================================================

  Widget _buildOffersPage() {
    return _featurePage(
      eyebrow: 'SPECIAL OFFERS',
      title: 'Offers',
      description:
          'Member offers and promotions.',
      icon: Icons.local_offer_outlined,
      featureTitle: 'Hasani Books Offers',
      featureDescription:
          'Special member offers and promotions will appear here.',
    );
  }

  // ============================================================
  // ONLINE STORE
  // ============================================================

  Widget _buildStorePage() {
    return _featurePage(
      eyebrow: 'SHOP ONLINE',
      title: 'Online Store',
      description:
          'Hasani Books online store.',
      icon: Icons.shopping_cart_outlined,
      featureTitle:
          'Hasani Books Online Store',
      featureDescription:
          'Continue to the official Hasani Books online store.',
    );
  }

  // ============================================================
  // LOCATIONS
  // ============================================================

  Widget _buildLocationsPage() {
    return _featurePage(
      eyebrow: 'FIND US',
      title: 'Locations',
      description:
          'Find Hasani Books branches.',
      icon: Icons.location_on_outlined,
      featureTitle:
          'Hasani Books Store Locations',
      featureDescription:
          'Open the official Hasani Books store locator.',
    );
  }

  // ============================================================
  // GENERIC FEATURE PAGE
  // ============================================================

  Widget _featurePage({
    required String eyebrow,
    required String title,
    required String description,
    required IconData icon,
    required String featureTitle,
    required String featureDescription,
  }) {
    return _pageScroll(
      children: [
        _pageHeading(
          eyebrow: eyebrow,
          title: title,
          description: description,
        ),
        _emptyFeature(
          icon: icon,
          title: featureTitle,
          description: featureDescription,
        ),
      ],
    );
  }

  // ============================================================
  // PAGE HELPERS
  // ============================================================

  Widget _pageScroll({
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        22,
        16,
        40,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _pageHeading({
    required String eyebrow,
    required String title,
    required String description,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: const TextStyle(
              color: Color(0xff7c879c),
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: darkText,
              fontSize: 29,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(
              color: mutedText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffe8ebf2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color:
                  blue.withValues(alpha: .08),
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
              color: darkText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: mutedText,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleInformationCard({
    required IconData icon,
    required String title,
    required String description,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffe8ebf2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color:
                  blue.withValues(alpha: .08),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: blue,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color: darkText,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style:
                      const TextStyle(
                    color: mutedText,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: blue,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATA HELPERS
  // ============================================================

  String _membershipNumber() {
    return _firstValue([
          customer?['membership'],
          customer?['membershipNo'],
          customer?['membershipNumber'],
          customer?['memberId'],
          customer?['cardNo'],
          customer?['cardNumber'],
        ]) ??
        memberController.text.trim();
  }

  String _initial(String name) {
    final clean = name.trim();

    if (clean.isEmpty) {
      return 'M';
    }

    return clean
        .substring(0, 1)
        .toUpperCase();
  }

  String? _firstValue(
    List<dynamic> values,
  ) {
    for (final value in values) {
      if (value == null) continue;

      final text =
          value.toString().trim();

      if (text.isNotEmpty &&
          text != 'null') {
        return text;
      }
    }

    return null;
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
