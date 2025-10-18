import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/auth_storage.dart';
import 'profile_page.dart';
import 'map_screen.dart';
import 'favorites_page.dart';
import 'map_screen.dart' show MapScreen, PreSetDestination;

import '../widgets/about_us_page.dart';
import '../widgets/jeep_route_card.dart';

const Color kPrimaryColor = Color(0xFFE4572E);
const Color kBackgroundColor = Color(0xFFFDF8E2);
const Color kCardColor = Color(0xFFFC775C);
const Color kHeaderColor = Color(0xFFE4572E);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  
  PreSetDestination? _favoriteDestination;
  
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  bool _isJeepListSheetOpen = false;
  PersistentBottomSheetController? _bottomSheetController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  late final List<Widget> _pages;

  double get _fabElevation => _isJeepListSheetOpen ? 0.0 : 4.0;
  double get _appBarElevation => _isJeepListSheetOpen ? 0.0 : 8.0;


  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0.0, end: 0.5).animate(_animationController);

    _pages = [
      MapScreen(toPlace: _favoriteDestination),
      const AboutUsPage(),
      const SizedBox.shrink(),
      const Center(child: Text("Favorites Tab Content Placeholder")),
      ProfilePage(onLogout: () => _logout(context)),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _bottomSheetController?.close();
    super.dispose();
  }

  void _onItemTapped(int index) async {
    if (index == 2) return;

    if (_isJeepListSheetOpen) {
      _animationController.reverse();
      _bottomSheetController?.close();
      setState(() {
        _isJeepListSheetOpen = false;
        _bottomSheetController = null;
      });
    }

    if (index == 3) {
      setState(() => _selectedIndex = index);
      
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FavoritesPage(), 
        ),
      );

      if (result != null && result is PreSetDestination) {
        setState(() {
          _favoriteDestination = result;
          _selectedIndex = 0; 
        });
        _pageController.jumpToPage(0);
        
        return; 
      } else {
        setState(() => _selectedIndex = _pageController.page?.round() ?? 0);
        return;
      }
    }
    
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _onFabTapped(BuildContext fabContext) {
    final ScaffoldState scaffoldState = Scaffold.of(fabContext);

    if (_isJeepListSheetOpen) {
      _animationController.reverse();
      _bottomSheetController?.close();
    } else {
      _animationController.forward();

      _bottomSheetController = scaffoldState.showBottomSheet(
        (context) => _buildJeepListSheetContent(),
        backgroundColor: Colors.transparent,

        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                65),
      );

      _bottomSheetController!.closed.then((_) {
        if (mounted) {
          setState(() {
            _isJeepListSheetOpen = false;
            _bottomSheetController = null;
            _animationController.reverse(from: _animationController.value);
          });
        }
      });

      setState(() {
        _isJeepListSheetOpen = true;
      });
    }
    debugPrint(
        'Floating Action Button activated: Sheet is now ${_isJeepListSheetOpen ? "OPEN" : "CLOSED"}.');
  }

  Widget _buildJeepListSheetContent() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Main Page - Jeep List',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 300,
            child: ListView(
              shrinkWrap: true,
              children: const [
                JeepRouteCard(routeName: 'Main Gate - Friendship', colorName: 'Sand'),
                JeepRouteCard(routeName: 'C-Point - Balibago - H\'way', colorName: 'Grey'),
                JeepRouteCard(routeName: 'SM City - Main Gate - Dau', colorName: 'Various'),
                JeepRouteCard(routeName: 'Checkpoint - Hensonville - Holy', colorName: 'White'),
                JeepRouteCard(routeName: 'Sapang Bato - Angles', colorName: 'Maroon'),
                JeepRouteCard(routeName: 'Checkpoint - Holy - Highway', colorName: 'Lavander'),
                JeepRouteCard(routeName: 'Marisol - Pampang', colorName: 'Green'),
                JeepRouteCard(routeName: 'Pandan - Pampang', colorName: 'Blue'),
                JeepRouteCard(routeName: 'Sunset - Nepo', colorName: 'Orange'),
                JeepRouteCard(routeName: 'Villa - Pampang - SM Telebastagan', colorName: 'Yellow'),
                JeepRouteCard(routeName: 'Capaya - Angeles', colorName: 'Pink')
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      {required int index, required IconData icon, required String label}) {
    if (index == 2) return const SizedBox.shrink();

    final bool isSelected = _selectedIndex == index;
    final Color iconColor = isSelected ? Colors.white : Colors.white70;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                    color: iconColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Logged out successfully."),
              backgroundColor: Colors.green),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (Route<dynamic> route) => false,);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Logout failed: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      MapScreen(toPlace: _favoriteDestination),
      const AboutUsPage(),
      const SizedBox.shrink(),
      const Center(child: Text('Favorites Tab - Use FAB/Search to navigate.')),
      ProfilePage(onLogout: () => _logout(context)),
    ];
    
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          children: pages,
        ),
      ),
      backgroundColor: kBackgroundColor,

      floatingActionButton: Builder(builder: (fabContext) {
        return FloatingActionButton(
          backgroundColor: kPrimaryColor,
          shape: const CircleBorder(),
          onPressed: () => _onFabTapped(fabContext),
          elevation: _fabElevation,

          child: RotationTransition(
            turns: _animation,
            child:
                const Icon(Icons.arrow_upward, color: Colors.white, size: 30),
          ),
        );
      }),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: kPrimaryColor,
        elevation: _appBarElevation,

        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        padding: EdgeInsets.zero,
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(index: 0, icon: Icons.home, label: 'Home'),
            _buildNavItem(index: 1, icon: Icons.list, label: 'About Us'),
            const SizedBox(width: 40),
            _buildNavItem(index: 3, icon: Icons.bookmark, label: 'Favorites'),
            _buildNavItem(index: 4, icon: Icons.person, label: 'Profile'),
          ],
        ),
      ),
    );
  }
}