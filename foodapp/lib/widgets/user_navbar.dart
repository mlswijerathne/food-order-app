import 'package:flutter/material.dart';

class UserNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const UserNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B01),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              // First update the current index
              onTap(index);

              // Then handle navigation if needed

              if (index == 0) {
                
                Future.delayed(Duration.zero, () {
                  Navigator.pushNamed(context, '/');
                });
              }


              if (index == 1) {
                
                Future.delayed(Duration.zero, () {
                  Navigator.pushNamed(context, '/all_food_item_screen');
                });
              }


              if (index == 2) {
                
                Future.delayed(Duration.zero, () {
                  Navigator.pushNamed(context, '/all_order_screen');
                });
              }

              
              if (index == 3) {
                
                Future.delayed(Duration.zero, () {
                  Navigator.pushNamed(context, '/profile_screen');
                });
              }

              
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white,
            showUnselectedLabels: true,
            showSelectedLabels: true,
            elevation: 0,
            items: [
              _buildBottomNavigationBarItem(
                Icons.home_outlined,
                Icons.home,
                'Home',
                currentIndex == 0,
              ),
              _buildBottomNavigationBarItem(
                Icons.food_bank_outlined,
                Icons.food_bank,
                'Foods',
                currentIndex == 1,
              ),
              _buildBottomNavigationBarItem(
                Icons.assignment_outlined,
                Icons.assignment,
                'Orders',
                currentIndex == 2,
              ),
              _buildBottomNavigationBarItem(
                Icons.person_outline,
                Icons.person,
                'Profile',
                currentIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem(
    IconData icon,
    IconData activeIcon,
    String label,
    bool isSelected,
  ) {
    return BottomNavigationBarItem(
      icon: Transform.scale(
        scale: isSelected ? 1.3 : 1.0,
        child: Icon(isSelected ? activeIcon : icon),
      ),
      label: label,
    );
  }
}
