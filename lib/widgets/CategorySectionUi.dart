import 'package:flutter/material.dart';
import 'package:test_pro/model/categorys.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final bool isSubcategory;

  const CategoryCard({
    super.key,
    required this.category,
    this.isSelected = false,
    this.isSubcategory = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: isSubcategory
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: isSubcategory
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
          : const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFFC15C5C), Color(0xFF942A59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : const Color(0xFFF9D5D3).withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isSelected
              ? Colors.transparent
              : Colors.white.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF942A59).withOpacity(0.4)
                : Colors.black.withOpacity(0.1),
            blurRadius: 2,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          category.name,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: isSubcategory ? 12 : 14,
          ),
        ),
      ),
    );
  }
}
