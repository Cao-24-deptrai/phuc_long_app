import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/beverage.dart';
import '../models/promotion.dart';
import '../models/review.dart';
import '../state/app_state.dart';
import '../widgets/vector_logo.dart';
import '../widgets/shimmer_banner.dart';
import 'login_view.dart';

class StoreView extends StatefulWidget {
  const StoreView({super.key});

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> with SingleTickerProviderStateMixin {
  BeverageCategory _selectedCategory = BeverageCategory.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_updateState);
  }

  @override
  void dispose() {
    _appState.removeListener(_updateState);
    _searchController.dispose();
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  List<Beverage> get _filteredBeverages {
    return _appState.beverages.where((b) {
      final matchesCategory = _selectedCategory == BeverageCategory.all || b.category == _selectedCategory;
      final matchesSearch = b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _showBeverageDetails(Beverage beverage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => _BeverageDetailsSheet(beverage: beverage),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => const _CartSheet(),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đăng xuất', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?', style: GoogleFonts.beVietnamPro()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: AppTheme.textLight)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginView()),
              );
            },
            child: Text('Đồng ý', style: GoogleFonts.beVietnamPro(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = _appState.cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Custom Header Bar
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: Colors.white,
                elevation: 0,
                automaticallyImplyLeading: false,
                titleSpacing: 20,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const PhucLongLogo(size: 34),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: AppTheme.textLight),
                      onPressed: _handleLogout,
                      tooltip: 'Đăng xuất',
                    ),
                  ],
                ),
              ),

              // Search Box & Banner Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Greeting Card Header (Xin chào, <username/họ tên>)
                      Builder(
                        builder: (context) {
                          final user = _appState.currentUser;
                          final displayName = user?.name.isNotEmpty == true 
                              ? user!.name 
                              : (user?.username.isNotEmpty == true ? user!.username : 'Khách hàng');
                          final usernameTag = user?.username.isNotEmpty == true ? '@${user!.username}' : '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 20.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor.withOpacity(0.08),
                                  AppTheme.goldColor.withOpacity(0.12),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Xin chào, ',
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 15,
                                              color: AppTheme.textLight,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              displayName,
                                              style: GoogleFonts.beVietnamPro(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Text(' 👋'),
                                        ],
                                      ),
                                      if (usernameTag.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Tên tài khoản: $usernameTag',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textDark.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Search Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: GoogleFonts.beVietnamPro(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm trà, trà sữa, cà phê...',
                            hintStyle: GoogleFonts.beVietnamPro(color: AppTheme.textLight, fontSize: 13),
                            icon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Shimmer Carousel Banner
                      ShimmerBanner(
                        title: 'ƯU ĐÃI THÀNH VIÊN',
                        subtitle: 'Thưởng thức Trà & Cà phê Phúc Long với ưu đãi đặc biệt hôm nay',
                        buttonText: 'Khám phá ngay',
                        onTap: () {},
                      ),
                      const SizedBox(height: 24),

                      // Category Tabs
                      Text(
                        'Danh Mục Thực Đơn',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildCategoryChip(BeverageCategory.all, 'Tất cả 🍃'),
                            _buildCategoryChip(BeverageCategory.tea, 'Trà Trứ Danh 🍵'),
                            _buildCategoryChip(BeverageCategory.milkTea, 'Trà Sữa 🧋'),
                            _buildCategoryChip(BeverageCategory.coffee, 'Cà Phê ☕'),
                            _buildCategoryChip(BeverageCategory.special, 'Đặc Sản 🌟'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Beverage Grid List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: _filteredBeverages.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              children: [
                                const Icon(Icons.no_drinks_outlined, size: 48, color: AppTheme.textLight),
                                const SizedBox(height: 12),
                                Text(
                                  'Không tìm thấy thức uống phù hợp',
                                  style: GoogleFonts.beVietnamPro(color: AppTheme.textLight),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final beverage = _filteredBeverages[index];
                            return _buildBeverageCard(beverage);
                          },
                          childCount: _filteredBeverages.length,
                        ),
                      ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),

          // Floating Cart Button Bar
          if (cartItemCount > 0)
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: ElevatedButton(
                  onPressed: _showCartSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.goldColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$cartItemCount',
                              style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Xem giỏ hàng',
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_appState.cartSubtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} đ',
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.goldColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BeverageCategory category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: GoogleFonts.beVietnamPro(
          color: isSelected ? Colors.white : AppTheme.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        backgroundColor: AppTheme.backgroundColor,
        selectedColor: AppTheme.primaryColor,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ),
        onSelected: (bool selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
      ),
    );
  }

  Widget _buildBeverageCard(Beverage beverage) {
    return GestureDetector(
      onTap: () => _showBeverageDetails(beverage),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Beverage Image
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        beverage.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppTheme.primaryColor.withOpacity(0.05),
                          child: const Icon(Icons.coffee_rounded, color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                  ),
                  if (beverage.isPopular)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Bán chạy 🔥',
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            beverage.rating.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Text Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    beverage.name,
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    beverage.description,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: AppTheme.textLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${beverage.price.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} đ',
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Beverage Customizer Sheet
class _BeverageDetailsSheet extends StatefulWidget {
  final Beverage beverage;
  final int? cartItemIndex;
  final CartItem? cartItem;

  const _BeverageDetailsSheet({
    required this.beverage,
    this.cartItemIndex,
    this.cartItem,
  });

  @override
  State<_BeverageDetailsSheet> createState() => _BeverageDetailsSheetState();
}

class _BeverageDetailsSheetState extends State<_BeverageDetailsSheet> {
  int _quantity = 1;
  String _selectedSize = 'M';
  double _sugarLevel = 1.0;
  double _iceLevel = 1.0;

  String _reviewFilter = 'all';
  double _userRating = 5.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    if (widget.cartItem != null) {
      _quantity = widget.cartItem!.quantity;
      _selectedSize = widget.cartItem!.size;
      _sugarLevel = widget.cartItem!.sugar;
      _iceLevel = widget.cartItem!.ice;
    }
  }

  double get _currentUnitPrice {
    double price = widget.beverage.price;
    if (_selectedSize == 'L') price += 10000;
    if (_selectedSize == 'S') price -= 5000;
    return price;
  }

  double get _totalPrice => _currentUnitPrice * _quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Image / Top header section
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.beverage.imageUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 90,
                      height: 90,
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
                        widget.beverage.name,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            widget.beverage.rating.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.beverage.category == BeverageCategory.tea
                                  ? 'Trà'
                                  : widget.beverage.category == BeverageCategory.milkTea
                                      ? 'Trà Sữa'
                                      : widget.beverage.category == BeverageCategory.coffee
                                          ? 'Cà phê'
                                          : 'Đặc sản',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.beverage.price.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} đ',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.dividerColor),

          // Scrollable options
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mô tả sản phẩm',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.beverage.description,
                    style: GoogleFonts.beVietnamPro(color: AppTheme.textLight, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // SIZE SELECTION
                  Text(
                    'Chọn Kích Thước (Size)',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildSizeOption('S', 'Nhỏ (-5k)'),
                      _buildSizeOption('M', 'Vừa (Chuẩn)'),
                      _buildSizeOption('L', 'Lớn (+10k)'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // SUGAR SELECTION
                  Text(
                    'Lượng Đường',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildSugarOption('0%', 0.0),
                      _buildSugarOption('30%', 0.3),
                      _buildSugarOption('50%', 0.5),
                      _buildSugarOption('70%', 0.7),
                      _buildSugarOption('100%', 1.0),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ICE SELECTION
                  Text(
                    'Lượng Đá',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildIceOption('Không đá', 0.0),
                      _buildIceOption('50% đá', 0.5),
                      _buildIceOption('100% đá', 1.0),
                    ],
                  ),

                  const Divider(height: 36, color: AppTheme.dividerColor),

                  // REVIEWS & RATINGS SECTION
                  Builder(
                    builder: (context) {
                      final appState = AppState();
                      final allProductReviews = appState.getReviewsForProduct(widget.beverage.id);
                      List<Review> filteredReviews = List.from(allProductReviews);

                      if (_reviewFilter == 'newest') {
                        filteredReviews.sort((a, b) => b.date.compareTo(a.date));
                      } else if (_reviewFilter == '5') {
                        filteredReviews = filteredReviews.where((r) => r.rating == 5.0).toList();
                      } else if (_reviewFilter == '4') {
                        filteredReviews = filteredReviews.where((r) => r.rating == 4.0).toList();
                      } else if (_reviewFilter == '3') {
                        filteredReviews = filteredReviews.where((r) => r.rating == 3.0).toList();
                      } else if (_reviewFilter == '2') {
                        filteredReviews = filteredReviews.where((r) => r.rating == 2.0).toList();
                      } else if (_reviewFilter == '1') {
                        filteredReviews = filteredReviews.where((r) => r.rating == 1.0).toList();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Đánh Giá Từ Khách Hàng ⭐',
                                style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: AppTheme.goldColor, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.beverage.rating} / 5.0 (${allProductReviews.length})',
                                      style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textDark),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // FILTER CHIPS
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildReviewFilterChip('all', 'Tất cả (${allProductReviews.length})'),
                                _buildReviewFilterChip('newest', 'Mới nhất 🕒'),
                                _buildReviewFilterChip('5', '5 ⭐ (${allProductReviews.where((r) => r.rating == 5.0).length})'),
                                _buildReviewFilterChip('4', '4 ⭐ (${allProductReviews.where((r) => r.rating == 4.0).length})'),
                                _buildReviewFilterChip('3', '3 ⭐ (${allProductReviews.where((r) => r.rating == 3.0).length})'),
                                _buildReviewFilterChip('2', '2 ⭐ (${allProductReviews.where((r) => r.rating == 2.0).length})'),
                                _buildReviewFilterChip('1', '1 ⭐ (${allProductReviews.where((r) => r.rating == 1.0).length})'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // REVIEWS LIST
                          if (filteredReviews.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              width: double.infinity,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.dividerColor),
                              ),
                              child: Text(
                                'Chưa có đánh giá nào phù hợp với bộ lọc này.',
                                style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textLight),
                              ),
                            )
                          else
                            ...filteredReviews.map((rev) => _buildReviewItem(rev)),

                          const SizedBox(height: 16),

                          // ADD REVIEW FORM
                          _buildAddReviewSection(),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: AppTheme.dividerColor),

          // Bottom Action Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // Quantity selector
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: () {
                            if (_quantity > 1) {
                              setState(() {
                                _quantity--;
                              });
                            }
                          },
                        ),
                        Text(
                          '$_quantity',
                          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: () {
                            setState(() {
                              _quantity++;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Add to Cart / Update Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final appState = AppState();
                        if (widget.cartItemIndex != null) {
                          appState.updateCartItem(
                            widget.cartItemIndex!,
                            quantity: _quantity,
                            size: _selectedSize,
                            sugar: _sugarLevel,
                            ice: _iceLevel,
                          );
                        } else {
                          appState.addToCart(
                            widget.beverage,
                            quantity: _quantity,
                            size: _selectedSize,
                            sugar: _sugarLevel,
                            ice: _iceLevel,
                          );
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.cartItemIndex != null
                            ? 'Cập nhật • ${_totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} đ'
                            : 'Thêm vào giỏ • ${_totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} đ',
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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

  Widget _buildSizeOption(String size, String label) {
    final isSelected = _selectedSize == size;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedSize = size;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  size,
                  style: GoogleFonts.beVietnamPro(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSugarOption(String text, double level) {
    final isSelected = _sugarLevel == level;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _sugarLevel = level;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: GoogleFonts.beVietnamPro(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textDark,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIceOption(String text, double level) {
    final isSelected = _iceLevel == level;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _iceLevel = level;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: GoogleFonts.beVietnamPro(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textDark,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewFilterChip(String key, String label) {
    final isSelected = _reviewFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: GoogleFonts.beVietnamPro(
          color: isSelected ? Colors.white : AppTheme.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryColor,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ),
        onSelected: (bool selected) {
          setState(() {
            _reviewFilter = key;
          });
        },
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    final appState = AppState();
    String currentAvatarUrl = review.userAvatar.trim();

    // Look up real-time live user avatar
    final uKey = review.userEmail.trim().toLowerCase();
    final liveUser = appState.users[uKey];
    if (liveUser != null && liveUser.avatarUrl.trim().isNotEmpty) {
      currentAvatarUrl = liveUser.avatarUrl.trim();
    } else if (appState.currentUser != null &&
        appState.currentUser!.email.trim().toLowerCase() == uKey &&
        appState.currentUser!.avatarUrl.trim().isNotEmpty) {
      currentAvatarUrl = appState.currentUser!.avatarUrl.trim();
    }

    final dateStr = '${review.date.day.toString().padLeft(2, '0')}/${review.date.month.toString().padLeft(2, '0')}/${review.date.year} ${review.date.hour.toString().padLeft(2, '0')}:${review.date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: currentAvatarUrl.isNotEmpty
                    ? Image.network(
                        currentAvatarUrl,
                        headers: const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'},
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 36,
                          height: 36,
                          color: AppTheme.primaryColor,
                          child: Center(
                            child: Text(
                              review.userName.isNotEmpty ? review.userName.substring(0, 1).toUpperCase() : 'U',
                              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: 36,
                        height: 36,
                        color: AppTheme.primaryColor,
                        child: Center(
                          child: Text(
                            review.userName.isNotEmpty ? review.userName.substring(0, 1).toUpperCase() : 'U',
                            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 14,
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(
                          dateStr,
                          style: GoogleFonts.beVietnamPro(fontSize: 10, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textDark, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddReviewSection() {
    final appState = AppState();
    final canReview = appState.canUserReviewProduct(widget.beverage.id);

    if (!canReview) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_clock_rounded, color: AppTheme.primaryColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đánh giá bị khóa',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bạn chỉ có thể viết bình luận và đánh giá sau khi đã mua món này và đơn hàng được giao thành công.',
                    style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textDark, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Viết Bình Luận & Đánh Giá ✍️',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          
          // Star selector
          Row(
            children: [
              Text('Đánh giá số sao:', style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Row(
                children: List.generate(5, (index) {
                  final starVal = index + 1.0;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(
                      starVal <= _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _userRating = starVal;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(width: 6),
              Text(
                '${_userRating.toStringAsFixed(0)} ⭐',
                style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Comment TextField
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Hãy chia sẻ cảm nhận của bạn về hương vị món này...',
              hintStyle: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textLight),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmittingReview
                  ? null
                  : () async {
                      final comment = _commentController.text.trim();
                      if (comment.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Vui lòng viết cảm nhận trước khi gửi!', style: GoogleFonts.beVietnamPro()),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _isSubmittingReview = true;
                      });

                      await appState.addReview(
                        productId: widget.beverage.id,
                        rating: _userRating,
                        comment: comment,
                      );

                      if (!mounted) return;
                      setState(() {
                        _isSubmittingReview = false;
                        _commentController.clear();
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã gửi đánh giá thành công! Cảm ơn phản hồi của bạn.', style: GoogleFonts.beVietnamPro()),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text('Gửi Đánh Giá', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Shopping Cart Sheet widget with Promotion Voucher Support
class _CartSheet extends StatefulWidget {
  const _CartSheet();

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  final AppState _appState = AppState();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'Nguyễn Văn Hải');
  final _phoneController = TextEditingController(text: '0912345678');
  final _addressController = TextEditingController(text: '7/2 Thành Thái, Quận 10, TP. Hồ Chí Minh');
  final _promoCodeController = TextEditingController();

  bool _isCheckoutMode = false;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _appState.addListener(_updateState);
    if (_appState.currentUser != null) {
      _nameController.text = _appState.currentUser!.name;
      _phoneController.text = _appState.currentUser!.phone;
      _addressController.text = _appState.currentUser!.address;
    }
  }

  @override
  void dispose() {
    _appState.removeListener(_updateState);
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  void _applyPromoCode() {
    final code = _promoCodeController.text.trim();
    final error = _appState.applyPromotionCode(code);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.beVietnamPro()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Áp dụng mã khuyến mãi thành công!', style: GoogleFonts.beVietnamPro()),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      _promoCodeController.clear();
    }
  }

  void _confirmDeleteCartItem(BuildContext context, int index, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Xác nhận xóa',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa sản phẩm "$itemName" khỏi giỏ hàng không?',
          style: GoogleFonts.beVietnamPro(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.beVietnamPro(
                color: AppTheme.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _appState.removeFromCart(index);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Xóa',
              style: GoogleFonts.beVietnamPro(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditBeverageDetails(BuildContext context, Beverage beverage, int index, CartItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => _BeverageDetailsSheet(
        beverage: beverage,
        cartItemIndex: index,
        cartItem: item,
      ),
    );
  }

  void _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isPlacingOrder = true;
      });

      await Future.delayed(const Duration(milliseconds: 1200));

      if (!mounted) return;

      await _appState.placeOrder(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _addressController.text.trim(),
      );

      setState(() {
        _isPlacingOrder = false;
      });

      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                'Đặt hàng thành công!',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đơn hàng của bạn đã được ghi nhận trực tiếp vào Cloud Firestore và đang được cửa hàng chế biến.',
                style: GoogleFonts.beVietnamPro(color: AppTheme.textLight, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Đóng', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isCheckoutMode ? 'Thông tin giao hàng' : 'Giỏ hàng của bạn',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                if (!_isCheckoutMode && _appState.cartItems.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      _appState.clearCart();
                    },
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                    label: Text(
                      'Xóa hết',
                      style: GoogleFonts.beVietnamPro(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.dividerColor),

          // Content section
          Expanded(
            child: _appState.cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 64, color: AppTheme.textLight),
                        const SizedBox(height: 12),
                        Text(
                          'Giỏ hàng của bạn đang trống.',
                          style: GoogleFonts.beVietnamPro(color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  )
                : _isCheckoutMode
                    ? _buildCheckoutForm()
                    : _buildCartItemsList(),
          ),

          const Divider(height: 1, color: AppTheme.dividerColor),

          // Footer Total Breakdown & Action Buttons
          if (_appState.cartItems.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tạm tính', style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppTheme.textLight)),
                        Text(
                          '${_appState.cartSubtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} đ',
                          style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                        ),
                      ],
                    ),

                    // Discount row (if applied)
                    if (_appState.appliedPromotion != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_offer, size: 14, color: Colors.deepOrangeAccent),
                              const SizedBox(width: 4),
                              Text(
                                'Giảm giá (${_appState.appliedPromotion!.code})',
                                style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.deepOrangeAccent, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            '-${_appState.discountAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} đ',
                            style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Final Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng thanh toán',
                          style: GoogleFonts.beVietnamPro(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        Text(
                          '${_appState.cartFinalTotal.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} đ',
                          style: GoogleFonts.beVietnamPro(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _isPlacingOrder
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                        : Row(
                            children: [
                              if (_isCheckoutMode) ...[
                                Expanded(
                                  flex: 4,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isCheckoutMode = false;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor,
                                      side: const BorderSide(color: AppTheme.primaryColor),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text('Quay lại', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                flex: 6,
                                child: ElevatedButton(
                                  onPressed: _isCheckoutMode
                                      ? _submitOrder
                                      : () {
                                          setState(() {
                                            _isCheckoutMode = true;
                                          });
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    _isCheckoutMode ? 'Đặt Hàng Ngay' : 'Tiếp Tục Thanh Toán',
                                    style: GoogleFonts.beVietnamPro(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartItemsList() {
    final availablePromos = _appState.promotions;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Cart items
        ...List.generate(_appState.cartItems.length, (index) {
          final item = _appState.cartItems[index];
          final sugarText = (item.sugar * 100).toInt().toString();
          final iceText = (item.ice * 100).toInt().toString();

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.beverage.imageUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 64,
                      height: 64,
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
                        item.beverage.name,
                        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Size: ${item.size} • Đường: $sugarText% • Đá: $iceText%',
                        style: GoogleFonts.beVietnamPro(color: AppTheme.textLight, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} đ',
                        style: GoogleFonts.beVietnamPro(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Quantity controls
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (item.quantity > 1) {
                              _appState.updateCartQuantity(index, -1);
                            } else {
                              _confirmDeleteCartItem(context, index, item.beverage.name);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              border: Border.all(color: AppTheme.dividerColor),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.remove, size: 14, color: AppTheme.textDark),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            '${item.quantity}',
                            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _appState.updateCartQuantity(index, 1),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              border: Border.all(color: AppTheme.dividerColor),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, size: 14, color: AppTheme.textDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _showEditBeverageDetails(context, item.beverage, index, item);
                          },
                          child: Text(
                            'Sửa',
                            style: GoogleFonts.beVietnamPro(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _confirmDeleteCartItem(context, index, item.beverage.name),
                          child: Text(
                            'Xóa',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const Divider(height: 32, color: AppTheme.dividerColor),

        // PROMOTION VOUCHER INPUT CARD
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined, color: AppTheme.goldColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Mã Khuyến Mãi / Voucher Phúc Long',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // If voucher applied
              if (_appState.appliedPromotion != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đã áp dụng: ${_appState.appliedPromotion!.code}',
                              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                            ),
                            Text(
                              _appState.appliedPromotion!.title,
                              style: GoogleFonts.beVietnamPro(fontSize: 11, color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                        onPressed: () {
                          _appState.removeAppliedPromotion();
                        },
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoCodeController,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Nhập mã (ví dụ: PHUCLONG10)',
                          hintStyle: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.normal),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.dividerColor),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applyPromoCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        elevation: 0,
                      ),
                      child: Text('Áp dụng', style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

              // Available Vouchers Quick Picker Cards (Horizontal Scroll)
              if (availablePromos.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text('Mã giảm giá khả dụng (Vuốt ngang ➔):', style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: availablePromos.map((p) {
                      final isApplied = _appState.appliedPromotion?.code == p.code;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: InkWell(
                          onTap: () {
                            _promoCodeController.text = p.code;
                            _applyPromoCode();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isApplied ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isApplied ? AppTheme.primaryColor : AppTheme.dividerColor,
                                width: isApplied ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.card_giftcard_rounded, size: 16, color: AppTheme.goldColor),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.code,
                                      style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                    ),
                                    Text(
                                      p.discountType == "percent" ? "Giảm ${p.discountValue.toInt()}%" : "Giảm ${(p.discountValue / 1000).toInt()}k",
                                      style: GoogleFonts.beVietnamPro(fontSize: 10, color: AppTheme.textLight),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Vui lòng xác nhận thông tin nhận hàng của bạn dưới đây.',
              style: GoogleFonts.beVietnamPro(color: AppTheme.textLight, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Họ và tên người nhận',
                prefixIcon: const Icon(Icons.person_outline, color: AppTheme.textLight),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập họ tên';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Field
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.textLight),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address Field
            TextFormField(
              controller: _addressController,
              keyboardType: TextInputType.multiline,
              minLines: 2,
              maxLines: null,
              decoration: InputDecoration(
                labelText: 'Địa chỉ giao hàng',
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.textLight),
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập địa chỉ';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Order Summary mini-card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đơn hàng bao gồm:',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 8),
                  ..._appState.cartItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.quantity}x ${item.beverage.name} (${item.size})',
                              style: GoogleFonts.beVietnamPro(fontSize: 13, color: AppTheme.textDark),
                            ),
                            Text(
                              '${item.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} đ',
                              style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                      )),
                  if (_appState.appliedPromotion != null) ...[
                    const Divider(height: 16, color: AppTheme.dividerColor),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mã giảm giá (${_appState.appliedPromotion!.code})',
                            style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.deepOrangeAccent, fontWeight: FontWeight.bold)),
                        Text(
                          '-${_appState.discountAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} đ',
                          style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
