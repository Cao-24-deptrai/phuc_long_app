import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PhucLongImageBannerItem {
  final String title;
  final String subtitle;
  final String tag;
  final String imageUrl;
  final List<Color> gradientColors;

  const PhucLongImageBannerItem({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.imageUrl,
    required this.gradientColors,
  });
}

class PhucLongImageBanner extends StatefulWidget {
  const PhucLongImageBanner({super.key});

  @override
  State<PhucLongImageBanner> createState() => _PhucLongImageBannerState();
}

class _PhucLongImageBannerState extends State<PhucLongImageBanner> {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  final List<PhucLongImageBannerItem> _banners = const [
    PhucLongImageBannerItem(
      title: '100% ARABICA TUYỂN CHỌN',
      subtitle: 'Tinh tế trong từng bước tiến • Hương vị cà phê đậm đà hảo hạng',
      tag: 'CÀ PHÊ PHÚC LONG',
      imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=800&auto=format&fit=crop&q=80',
      gradientColors: [Color(0xFF2C1810), Color(0xFF8B5A2B)],
    ),
    PhucLongImageBannerItem(
      title: 'VỌNG NGUYỆT THƯỞNG DANH TRÀ',
      subtitle: 'Bộ sưu tập Trà & Bánh phong vị truyền thống Việt Nam',
      tag: 'BST MỚI RA MẮT',
      imageUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=800&auto=format&fit=crop&q=80',
      gradientColors: [Color(0xFF0D3B2E), Color(0xFF1E6B52)],
    ),
    PhucLongImageBannerItem(
      title: 'TRÀ LÀI & Ô LONG THƯỢNG HẠNG',
      subtitle: 'Đậm vị trà, thơm vị lá • Chiết xuất từ lá trà nguyên bản',
      tag: 'TRÀ NGUYÊN BẢN',
      imageUrl: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=800&auto=format&fit=crop&q=80',
      gradientColors: [Color(0xFF1A3C2A), Color(0xFF0F5A37)],
    ),
    PhucLongImageBannerItem(
      title: 'ƯU ĐÃI THÀNH VIÊN VIP',
      subtitle: 'Tích điểm đổi quà & nhận voucher giảm 20% mỗi tuần',
      tag: 'ĐẶC QUYỀN MEMBER',
      imageUrl: 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800&auto=format&fit=crop&q=80',
      gradientColors: [Color(0xFF4A154B), Color(0xFF6B1B6D)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _resetTimer() {
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 175,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    if (scrollNotification is ScrollStartNotification) {
                      _autoScrollTimer?.cancel();
                    } else if (scrollNotification is ScrollEndNotification) {
                      _resetTimer();
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _banners.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final banner = _banners[index];
                      return Stack(
                        children: [
                          // Background Image
                          Positioned.fill(
                            child: Image.network(
                              banner.imageUrl,
                              headers: const {
                                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
                              },
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: banner.gradientColors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Gradient Overlay for High Contrast Legibility
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.75),
                                    Colors.black.withOpacity(0.35),
                                    Colors.black.withOpacity(0.1),
                                  ],
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight,
                                ),
                              ),
                            ),
                          ),

                          // Content overlay
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.goldColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      banner.tag,
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    banner.title,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.1,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.6),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    banner.subtitle,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Left Arrow Button (Mũi tên Trái)
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final prevPage = (_currentPage - 1 + _banners.length) % _banners.length;
                          _pageController.animateToPage(
                            prevPage,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOutCubic,
                          );
                          _resetTimer();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.35),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Right Arrow Button (Mũi tên Phải)
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final nextPage = (_currentPage + 1) % _banners.length;
                          _pageController.animateToPage(
                            nextPage,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOutCubic,
                          );
                          _resetTimer();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.35),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Indicator Dots (Web Phúc Long Dot Style)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            final active = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? AppTheme.primaryColor : AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
