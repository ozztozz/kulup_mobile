import "package:flutter/material.dart";

class AppFooterMenu extends StatelessWidget {
  const AppFooterMenu({super.key, required this.onTap, this.selectedIndex});

  final int? selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFF12233F),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              _FooterNavItem(
                icon: Icons.home_filled,
                selected: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _FooterNavItem(
                icon: Icons.calendar_month_outlined,
                selected: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              _FooterNavItem(
                icon: Icons.assignment_turned_in_outlined,
                selected: selectedIndex == 2,
                onTap: () => onTap(2),
              ),
              _FooterNavItem(
                icon: Icons.payments_outlined,
                selected: selectedIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterNavItem extends StatelessWidget {
  const _FooterNavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: Icon(
          icon,
          color: selected ? Colors.white : Colors.white70,
          size: 22,
        ),
      ),
    );
  }
}