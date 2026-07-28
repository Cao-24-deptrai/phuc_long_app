import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/beverage.dart';
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
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Custom AppBar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const PhucLongLogo(size: 40),
                        Row(
                          children: [
                            // Cart button
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor, size: 28),
                                  onPressed: _showCartSheet,
                                ),
                                if (cartItemCount > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(milliseconds: 300),
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.goldColor,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 18,
                                              minHeight: 18,
                                            ),
                                            child: Text(
                                              '$cartItemCount',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            // Log out / Role switcher
                            IconButton(
                              icon: const Icon(Icons.logout_rounded, color: AppTheme.textLight),
                              onPressed: _handleLogout,
                              tooltip: 'Đăng xuất',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Welcome message & Search
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.beVietnamPro(fontSize: 24, color: AppTheme.textDark),
                            children: [
                              const TextSpan(text: 'Chào bạn, '),
                              TextSpan(
                                text: _appState.currentUser != null
                                    ? '${_appState.currentUser!.name}! 👋'
                                    : 'Thưởng thức trà ngay! 👋',
                                style: GoogleFonts.beVietnamPro(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.dividerColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm thức uống yêu thích...',
                              hintStyle: GoogleFonts.beVietnamPro(color: AppTheme.textLight, fontSize: 14),
                              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textLight),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, color: AppTheme.textLight),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Shimmer Glowing Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                    child: ShimmerBanner(
                      title: 'Ủ Vị Tâm Giao',
                      subtitle: 'Ưu đãi trà đào tươi mát giảm ngay 20%',
                      buttonText: 'Thử ngay',
                      onTap: () {
                        // Find Peach tea (id: '1') and open its details
                        final peachTea = _appState.beverages.firstWhere((b) => b.id == '1');
                        _showBeverageDetails(peachTea);
                      },
                    ),
                  ),
                ),

                // Categories Selector Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Danh mục sản phẩm',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ),

                // Categories Selector Chips (Animated Sliding Indicator behavior)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _buildCategoryChip(BeverageCategory.all, 'Tất cả'),
                        _buildCategoryChip(BeverageCategory.tea, 'Trà Đậm Vị'),
                        _buildCategoryChip(BeverageCategory.milkTea, 'Trà Sữa Béo'),
                        _buildCategoryChip(BeverageCategory.coffee, 'Cà Phê Nguyên Bản'),
                        _buildCategoryChip(BeverageCategory.special, 'Món Đặc Biệt'),
                      ],
                    ),
                  ),
                ),

                // Beverage Grid List with entrance animation
                _filteredBeverages.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.coffee_rounded, size: 64, color: AppTheme.textLight),
                              const SizedBox(height: 12),
                              Text(
                                'Không tìm thấy thức uống nào phù hợp.',
                                style: GoogleFonts.beVietnamPro(color: AppTheme.textLight),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final beverage = _filteredBeverages[index];
                              return _BeverageCard(
                                beverage: beverage,
                                onTap: () => _showBeverageDetails(beverage),
                              );
                            },
                            childCount: _filteredBeverages.length,
                          ),
                        ),
                      ),
                
                // Extra bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 90),
                )
              ],
            ),
          ),

          // Custom Bottom Cart Indicator (Floating bar at the bottom)
          if (cartItemCount > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: TweenAnimationBuilder<Offset>(
                tween: Tween(begin: const Offset(0, 1.2), end: Offset.zero),
                duration: const Duration(milliseconds: 500),
                curve: Curves.fastOutSlowIn,
                builder: (context, offset, child) {
                  return FractionalTranslation(
                    translation: offset,
                    child: Material(
                      elevation: 8,
                      shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: _showCartSheet,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 24),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$cartItemCount sản phẩm',
                                        style: GoogleFonts.beVietnamPro(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Xem chi tiết giỏ hàng',
                                        style: GoogleFonts.beVietnamPro(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${_appState.cartSubtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} đ',
                                    style: GoogleFonts.beVietnamPro(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                                ],
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
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BeverageCategory category, String label) {
    final isSelected = _selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.beVietnamPro(
                color: isSelected ? Colors.white : AppTheme.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Minimalist Item Card with Hover-press effect
class _BeverageCard extends StatelessWidget {
  final Beverage beverage;
  final VoidCallback onTap;

  const _BeverageCard({required this.beverage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
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
  double _sugarLevel = 1.0; // 0.0, 0.3, 0.5, 0.7, 1.0
  double _iceLevel = 1.0;   // 0.0, 0.5, 1.0

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
                    'Chọn kích cỡ',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildSizeOption('S', 'Nhỏ (-5.000 đ)'),
                      const SizedBox(width: 10),
                      _buildSizeOption('M', 'Vừa (Mặc định)'),
                      const SizedBox(width: 10),
                      _buildSizeOption('L', 'Lớn (+10.000 đ)'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // SUGAR SELECTION
                  Text(
                    'Mức đường',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSugarOption(0.0, '0%'),
                      _buildSugarOption(0.3, '30%'),
                      _buildSugarOption(0.5, '50%'),
                      _buildSugarOption(0.7, '70%'),
                      _buildSugarOption(1.0, '100%'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ICE SELECTION
                  Text(
                    'Mức đá',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIceOption(0.0, '0% đá'),
                      _buildIceOption(0.5, '50% đá'),
                      _buildIceOption(1.0, '100% đá'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // QUANTITY SELECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Số lượng',
                        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_quantity > 1) {
                                setState(() {
                                  _quantity--;
                                });
                              }
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                border: Border.all(color: AppTheme.dividerColor),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.remove_rounded, color: AppTheme.textDark),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              '$_quantity',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _quantity++;
                              });
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                border: Border.all(color: AppTheme.dividerColor),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_rounded, color: AppTheme.textDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const Divider(height: 1, color: AppTheme.dividerColor),

          // Bottom Bar containing Total price and ADD button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tổng tiền',
                          style: GoogleFonts.beVietnamPro(color: AppTheme.textLight, fontSize: 13),
                        ),
                        Text(
                          '${_totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} đ',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.cartItemIndex != null) {
                        AppState().updateCartItem(
                          widget.cartItemIndex!,
                          quantity: _quantity,
                          size: _selectedSize,
                          sugar: _sugarLevel,
                          ice: _iceLevel,
                        );
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã cập nhật ${widget.beverage.name} trong giỏ hàng',
                              style: GoogleFonts.beVietnamPro(),
                            ),
                            backgroundColor: AppTheme.primaryColor,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      } else {
                        AppState().addToCart(
                          widget.beverage,
                          quantity: _quantity,
                          size: _selectedSize,
                          sugar: _sugarLevel,
                          ice: _iceLevel,
                        );
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã thêm $_quantity x ${widget.beverage.name} vào giỏ hàng',
                              style: GoogleFonts.beVietnamPro(),
                            ),
                            backgroundColor: AppTheme.primaryColor,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.cartItemIndex != null ? 'Cập Nhật' : 'Thêm Vào Giỏ Hàng',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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

  Widget _buildSizeOption(String size, String desc) {
    final isSelected = _selectedSize == size;
    return Expanded(
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
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                size,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                size == 'S' ? '-5k' : size == 'M' ? 'Mặc định' : '+10k',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 9,
                  color: isSelected ? Colors.white70 : AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSugarOption(double level, String text) {
    final isSelected = _sugarLevel == level;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sugarLevel = level;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 38,
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
    );
  }

  Widget _buildIceOption(double level, String text) {
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
}

// Shopping Cart Sheet widget
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
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
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

      // Simulate place order transition delay
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      _appState.placeOrder(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _addressController.text.trim(),
      );

      setState(() {
        _isPlacingOrder = false;
      });

      Navigator.pop(context);

      // Show success dialog
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
                'Đơn hàng của bạn đã được tiếp nhận và đang được xử lý. Bạn có thể kiểm tra trạng thái trong mục quản trị nếu là Admin.',
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
      height: MediaQuery.of(context).size.height * 0.85,
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

          // Footer
          if (_appState.cartItems.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng thanh toán',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          '${_appState.cartSubtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} đ',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
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
                                  onPressed: _isCheckoutMode ? _submitOrder : () {
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
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: _appState.cartItems.length,
      separatorBuilder: (context, index) => const Divider(height: 24, color: AppTheme.dividerColor),
      itemBuilder: (context, index) {
        final item = _appState.cartItems[index];
        final sugarText = (item.sugar * 100).toInt().toString();
        final iceText = (item.ice * 100).toInt().toString();
        
        return Row(
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
            
            // Quantity buttons
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
                        // Dismiss current Cart sheet first
                        Navigator.pop(context);
                        // Show edit details sheet
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
        );
      },
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
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Địa chỉ giao hàng',
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.textLight),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

