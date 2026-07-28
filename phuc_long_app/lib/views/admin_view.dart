import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/beverage.dart';
import '../models/user.dart';
import '../state/app_state.dart';
import '../widgets/vector_logo.dart';
import 'login_view.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppState _appState = AppState();

  // Role Permissions Tab Controllers & State
  final TextEditingController _searchEmailController = TextEditingController();
  bool _isSearching = false;
  bool _hasSearched = false;
  UserModel? _foundUser;
  bool _selectedIsAdminRole = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _appState.addListener(_updateState);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchEmailController.dispose();
    _appState.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  void _handleLogout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  void _performUserSearch() async {
    final searchEmail = _searchEmailController.text.trim();
    if (searchEmail.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = false;
      _foundUser = null;
    });

    final user = await _appState.findUserByEmail(searchEmail);

    if (!mounted) return;

    setState(() {
      _isSearching = false;
      _hasSearched = true;
      _foundUser = user;
      _selectedIsAdminRole = user?.isAdmin ?? false;
    });
  }

  void _saveRolePermission() async {
    if (_foundUser == null) return;

    final targetEmail = _foundUser!.email;
    final newRoleIsAdmin = _selectedIsAdminRole;

    await _appState.updateUserRole(targetEmail, newRoleIsAdmin);

    if (!mounted) return;

    setState(() {
      _foundUser!.isAdmin = newRoleIsAdmin;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã cập nhật phân quyền thành công cho $targetEmail!',
          style: GoogleFonts.beVietnamPro(),
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PhucLongLogo(size: 34),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textLight),
            onPressed: _handleLogout,
            tooltip: 'Đăng xuất',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textLight,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Thống Kê'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Đơn Hàng'),
            Tab(icon: Icon(Icons.local_drink_outlined), text: 'Sản Phẩm'),
            Tab(icon: Icon(Icons.admin_panel_settings_outlined), text: 'Phân Quyền'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildDashboardTab(),
          _buildOrdersTab(),
          _buildProductsTab(),
          _buildPermissionsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton(
              onPressed: _showAddProductDialog,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // TAB 1: DASHBOARD & ANALYTICS
  Widget _buildDashboardTab() {
    final completedOrders = _appState.orders.where((o) => o.status == 'Đã hoàn thành').toList();
    final double totalRevenue = completedOrders.fold(0.0, (sum, o) => sum + o.total);
    final pendingOrdersCount = _appState.orders.where((o) => o.status == 'Chờ xử lý' || o.status == 'Đang xử lý').length;
    final totalProducts = _appState.allBeveragesForAdmin.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan cửa hàng',
            style: GoogleFonts.beVietnamPro(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 16),

          // Overview Stats Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildStatCard(
                'Doanh thu (Đã Giao)',
                '${totalRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ',
                Icons.monetization_on_outlined,
                Colors.green,
              ),
              _buildStatCard(
                'Đơn hàng mới',
                '$pendingOrdersCount đơn',
                Icons.hourglass_empty_rounded,
                AppTheme.goldColor,
              ),
              _buildStatCard(
                'Tổng sản phẩm',
                '$totalProducts món',
                Icons.local_cafe_outlined,
                AppTheme.primaryColor,
              ),
              _buildStatCard(
                'Tổng số đơn hàng',
                '${_appState.orders.length} đơn',
                Icons.receipt_long_outlined,
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Custom Sales Chart (Animated)
          Text(
            'Doanh thu tuần này (nghìn đồng)',
            style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBarChartColumn('Th 2', 450, 0.45),
                  _buildBarChartColumn('Th 3', 720, 0.72),
                  _buildBarChartColumn('Th 4', 600, 0.60),
                  _buildBarChartColumn('Th 5', 850, 0.85),
                  _buildBarChartColumn('Th 6', 950, 0.95),
                  _buildBarChartColumn('Th 7', 1200, 1.0),
                  _buildBarChartColumn('CN', 1100, 0.90),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Latest Active Orders
          Text(
            'Đơn hàng gần đây',
            style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _appState.orders.length > 3 ? 3 : _appState.orders.length,
            itemBuilder: (context, index) {
              final order = _appState.orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(order.id, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
                  subtitle: Text('${order.customerName} • ${order.items.length} món', style: GoogleFonts.beVietnamPro(fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: order.status == 'Đã hoàn thành'
                          ? Colors.green.withOpacity(0.1)
                          : order.status == 'Hủy'
                              ? Colors.red.withOpacity(0.1)
                              : AppTheme.goldColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: order.status == 'Đã hoàn thành'
                            ? Colors.green
                            : order.status == 'Hủy'
                                ? Colors.red
                                : AppTheme.goldColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.beVietnamPro(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(val, style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        ],
      ),
    );
  }

  Widget _buildBarChartColumn(String day, int val, double ratio) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$val', style: const TextStyle(fontSize: 9, color: AppTheme.textLight, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: ratio),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.fastOutSlowIn,
          builder: (context, val, child) {
            return Container(
              width: 24,
              height: 120 * val,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF1EA85E)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(day, style: GoogleFonts.beVietnamPro(fontSize: 10, color: AppTheme.textDark, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // TAB 2: ORDERS MANAGEMENT
  Widget _buildOrdersTab() {
    final orders = _appState.orders;
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textLight),
            const SizedBox(height: 12),
            Text('Chưa có đơn hàng nào.', style: GoogleFonts.beVietnamPro(color: AppTheme.textLight)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Row(
              children: [
                Text(order.id, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: order.status == 'Đã hoàn thành'
                        ? Colors.green.withOpacity(0.1)
                        : order.status == 'Hủy'
                            ? Colors.red.withOpacity(0.1)
                            : AppTheme.goldColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.status,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: order.status == 'Đã hoàn thành'
                          ? Colors.green
                          : order.status == 'Hủy'
                              ? Colors.red
                              : AppTheme.goldColor,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'Khách hàng: ${order.customerName} • ${order.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ',
              style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textLight),
            ),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin liên hệ:', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('SĐT: ${order.customerPhone}', style: GoogleFonts.beVietnamPro(fontSize: 13)),
                    Text('Địa chỉ: ${order.customerAddress}', style: GoogleFonts.beVietnamPro(fontSize: 13)),
                    const SizedBox(height: 12),
                    Text('Chi tiết sản phẩm:', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item.quantity}x ${item.beverage.name} (${item.size})', style: GoogleFonts.beVietnamPro(fontSize: 13)),
                              Text(
                                '${item.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ',
                                style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )),
                    const Divider(height: 24, color: AppTheme.dividerColor),
                    
                    // Order status action triggers
                    Text('Cập nhật trạng thái đơn:', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatusButton(order.id, 'Đang chuẩn bị', Colors.orangeAccent),
                        const SizedBox(width: 8),
                        _buildStatusButton(order.id, 'Đã hoàn thành', Colors.green),
                        const SizedBox(width: 8),
                        _buildStatusButton(order.id, 'Hủy', Colors.redAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusButton(String orderId, String status, Color color) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          _appState.updateOrderStatus(orderId, status);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.15),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Text(
          status == 'Đang chuẩn bị' ? 'Chuẩn bị' : status == 'Đã hoàn thành' ? 'Hoàn thành' : 'Hủy đơn',
          style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // TAB 3: PRODUCTS MANAGEMENT
  Widget _buildProductsTab() {
    final beverages = _appState.allBeveragesForAdmin;

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: beverages.length,
      separatorBuilder: (context, index) => const Divider(color: AppTheme.dividerColor, height: 24),
      itemBuilder: (context, index) {
        final beverage = beverages[index];
        return Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                beverage.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  child: const Icon(Icons.coffee_rounded, color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    beverage.name,
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                  ),
                  Text(
                    '${beverage.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ',
                    style: GoogleFonts.beVietnamPro(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    beverage.isAvailable ? 'Đang kinh doanh' : 'Tạm dừng bán',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: beverage.isAvailable ? Colors.green : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Availability Switch
            Switch(
              value: beverage.isAvailable,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) {
                _appState.toggleAvailability(beverage.id);
              },
            ),

            // Edit button
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.textLight),
              onPressed: () => _showEditProductDialog(beverage),
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () {
                _appState.deleteBeverage(beverage.id);
              },
            ),
          ],
        );
      },
    );
  }

  // TAB 4: ROLE PERMISSIONS MANAGEMENT (ADMIN TAB)
  Widget _buildPermissionsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân Quyền Tài Khoản',
            style: GoogleFonts.beVietnamPro(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhập địa chỉ email tài khoản để tìm kiếm và tùy chỉnh quyền sử dụng.',
            style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppTheme.textLight),
          ),
          const SizedBox(height: 20),

          // Search Box Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.beVietnamPro(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Nhập email (ví dụ: user@gmail.com)',
                      hintStyle: GoogleFonts.beVietnamPro(fontSize: 13, color: AppTheme.textLight),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.dividerColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    onSubmitted: (val) => _performUserSearch(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSearching ? null : _performUserSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : Text('Tìm kiếm', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Search Results / Selection Container
          if (!_hasSearched)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    Icon(Icons.manage_accounts_outlined, size: 64, color: AppTheme.textLight.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'Nhập email và bấm Tìm kiếm để phân quyền tài khoản',
                      style: GoogleFonts.beVietnamPro(color: AppTheme.textLight, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else if (_foundUser == null)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 40, color: Colors.redAccent),
                  const SizedBox(height: 10),
                  Text(
                    'Không tìm thấy tài khoản',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Không có tài khoản nào khớp với email "${_searchEmailController.text.trim()}".',
                    style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppTheme.textLight),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header User Info
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _foundUser!.name.isNotEmpty ? _foundUser!.name.substring(0, 1).toUpperCase() : 'U',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.goldColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _foundUser!.name,
                                style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _foundUser!.email,
                                style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppTheme.textLight),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _foundUser!.isAdmin ? AppTheme.goldColor.withOpacity(0.12) : AppTheme.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _foundUser!.isAdmin ? 'Admin' : 'User',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _foundUser!.isAdmin ? AppTheme.goldColor : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 32, color: AppTheme.dividerColor),

                    // Role Options Selection
                    Text(
                      'Tùy chọn phân quyền:',
                      style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 12),

                    RadioListTile<bool>(
                      value: false,
                      groupValue: _selectedIsAdminRole,
                      activeColor: AppTheme.primaryColor,
                      title: Text('Khách hàng (User)', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('Chỉ có quyền xem thực đơn, đặt hàng và xem hồ sơ cá nhân.', style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textLight)),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedIsAdminRole = val;
                          });
                        }
                      },
                    ),

                    RadioListTile<bool>(
                      value: true,
                      groupValue: _selectedIsAdminRole,
                      activeColor: AppTheme.primaryColor,
                      title: Text('Quản trị viên (Admin)', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor)),
                      subtitle: Text('Toàn quyền truy cập quản lý sản phẩm, đơn hàng, thống kê và phân quyền.', style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textLight)),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedIsAdminRole = val;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveRolePermission,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                        label: Text('Lưu Phân Quyền', style: GoogleFonts.beVietnamPro(fontSize: 15, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Dialog to Edit Product details
  void _showEditProductDialog(Beverage beverage) {
    final nameController = TextEditingController(text: beverage.name);
    final priceController = TextEditingController(text: beverage.price.toStringAsFixed(0));
    final descController = TextEditingController(text: beverage.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sửa sản phẩm', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá bán (đ)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Mô tả ngắn'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: AppTheme.textLight)),
          ),
          TextButton(
            onPressed: () {
              final newPrice = double.tryParse(priceController.text) ?? beverage.price;
              final updated = beverage.copyWith(
                name: nameController.text.trim(),
                price: newPrice,
                description: descController.text.trim(),
              );
              _appState.updateBeverage(updated);
              Navigator.pop(context);
            },
            child: Text('Cập nhật', style: GoogleFonts.beVietnamPro(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Dialog to Add New Product
  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    BeverageCategory category = BeverageCategory.tea;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Thêm thức uống mới', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên thức uống'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá bán (đ)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BeverageCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Phân loại'),
                  items: const [
                    DropdownMenuItem(value: BeverageCategory.tea, child: Text('Trà nguyên bản')),
                    DropdownMenuItem(value: BeverageCategory.milkTea, child: Text('Trà sữa')),
                    DropdownMenuItem(value: BeverageCategory.coffee, child: Text('Cà phê')),
                    DropdownMenuItem(value: BeverageCategory.special, child: Text('Đặc biệt')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        category = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Mô tả thành phần'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: AppTheme.textLight)),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty || priceController.text.trim().isEmpty) return;
                
                final price = double.tryParse(priceController.text) ?? 50000;
                final newBeverage = Beverage(
                  id: 'PL-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  category: category,
                  price: price,
                  imageUrl: 'https://images.unsplash.com/photo-1541658016709-82535e94bc69?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
                  description: descController.text.trim().isNotEmpty 
                      ? descController.text.trim() 
                      : 'Thức uống Phúc Long đặc trưng thơm ngon mát lạnh.',
                  rating: 5.0,
                );
                
                _appState.addBeverage(newBeverage);
                Navigator.pop(context);
                
                setState(() {}); // refresh FAB tab index state
              },
              child: Text('Thêm mới', style: GoogleFonts.beVietnamPro(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
