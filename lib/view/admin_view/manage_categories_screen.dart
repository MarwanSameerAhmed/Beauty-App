import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:test_pro/controller/category_service.dart';
import 'package:test_pro/model/categorys.dart';
import 'package:test_pro/view/admin_view/add_category_form.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';
import 'package:test_pro/widgets/loader.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FlowerBackground(
          child: Column(
            children: [
              const CustomAdminHeader(
                title: 'إدارة الأصناف',
                subtitle:
                    'تنظيم المنتجات والإعلانات ضمن تصنيفات رئيسية وفرعية لتسهيل التصفح',
              ),
              Expanded(
                child: StreamBuilder<List<Category>>(
                  stream: CategoryService().getCategories(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Loader(),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'حدث خطأ: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد أصناف حالياً.',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                      );
                    }

                    final categories = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return PlayAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 50 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: _buildCategoryCard(category),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddCategoryForm()),
            );
          },
          backgroundColor: const Color(0xFF942A59),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
          color: const Color(0xFFF9D5D3).withOpacity(0.5),
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.2,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withOpacity(0.8),
              child: const Icon(
                Icons.category,
                size: 30,
                color: Color(0xFF52002C),
              ),
            ),
            title: Text(
              category.name,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 17,
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editCategory(category);
                } else if (value == 'delete') {
                  _deleteCategory(category.id);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('تعديل'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('حذف'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editCategory(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCategoryForm(category: category),
      ),
    );
  }

  void _deleteCategory(String categoryId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد أنك تريد حذف هذا الصنف؟'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('حذف'),
              onPressed: () {
                CategoryService().deleteCategory(categoryId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
