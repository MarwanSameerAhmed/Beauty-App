import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:glamify/controller/category_service.dart';
import 'package:glamify/model/categorys.dart';
import 'package:glamify/view/admin_view/add_category_form.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/custom_admin_header.dart';
import 'package:glamify/widgets/loader.dart';
import 'package:glamify/widgets/FormFields.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<List<Category>>? _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  void _loadCategories() {
    setState(() {
      _categoriesFuture = CategoryService().getCategoriesFuture();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
              // حقل البحث
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GlassField(
                  controller: _searchController,
                  hintText: 'ابحث عن صنف...',
                  prefixIcon: Icons.search,
                  textColor: Colors.black,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _loadCategories();
                    await _categoriesFuture;
                  },
                  child: FutureBuilder<List<Category>>(
                    future: _categoriesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Loader(),
                        );
                      }
                    if (snapshot.hasError) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Text(
                                'حدث خطأ: ${snapshot.error}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: const Center(
                              child: Text(
                                'لا توجد أصناف حالياً.',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 18,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final categories = snapshot.data!;
                    final mainCategories = categories.where((c) => c.parentId == null).toList();

                    // فلترة حسب البحث
                    final filteredMainCategories = _searchQuery.isEmpty
                        ? mainCategories
                        : mainCategories.where((c) {
                            // بحث في الصنف الرئيسي
                            if (c.name.toLowerCase().contains(_searchQuery.toLowerCase())) return true;
                            // بحث في الفرعيات
                            final subs = categories.where((sub) => sub.parentId == c.id);
                            return subs.any((sub) => sub.name.toLowerCase().contains(_searchQuery.toLowerCase()));
                          }).toList();

                    if (filteredMainCategories.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: const Center(
                              child: Text(
                                'لا توجد نتائج مطابقة.',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 18,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: filteredMainCategories.length,
                      itemBuilder: (context, index) {
                        final category = filteredMainCategories[index];
                        final subCategories = categories.where((c) => c.parentId == category.id).toList();
                        return PlayAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + ((index % 6) * 80)),
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
                          child: _buildCategoryItem(category, subCategories),
                        );
                      },
                    );
                  },
                ),
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

  Widget _buildCategoryItem(Category category, List<Category> subCategories) {
    if (subCategories.isEmpty) {
      return _buildCategoryCard(category, isSubCategory: false);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(15.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF9D5D3).withOpacity(0.5),
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.2,
            ),
          ),
          child: ExpansionTile(
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editCategory(category);
                    } else if (value == 'delete') {
                      _deleteCategoryWithCheck(category.id, subCategories.length);
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
                const Icon(Icons.expand_more, color: Colors.black54),
              ],
            ),
            children: subCategories.map((sub) => _buildCategoryCard(sub, isSubCategory: true)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Category category, {required bool isSubCategory}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          margin: isSubCategory
              ? const EdgeInsets.fromLTRB(12, 0, 12, 12)
              : const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSubCategory
                ? const Color(0xFFF9D5D3).withOpacity(0.7)
                : const Color(0xFFF9D5D3).withOpacity(0.5),
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.2,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: isSubCategory ? 24 : 28,
              backgroundColor: Colors.white.withOpacity(isSubCategory ? 0.6 : 0.8),
              child: Icon(
                isSubCategory ? Icons.subdirectory_arrow_right : Icons.category,
                size: isSubCategory ? 26 : 30,
                color: const Color(0xFF52002C),
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

  void _deleteCategoryWithCheck(String categoryId, int subCategoriesCount) {
    if (subCategoriesCount > 0) {
      // منع الحذف إذا كان لديه فرعيات
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('لا يمكن الحذف', style: TextStyle(fontFamily: 'Tajawal')),
            content: Text(
              'لا يمكن حذف هذا الصنف لأنه يحتوي على $subCategoriesCount تصنيفات فرعية.\nيرجى حذف التصنيفات الفرعية أولاً.',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('حسناً', style: TextStyle(fontFamily: 'Tajawal')),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }
    _deleteCategory(categoryId);
  }

  void _deleteCategory(String categoryId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Tajawal')),
          content: const Text('هل أنت متأكد أنك تريد حذف هذا الصنف؟', style: TextStyle(fontFamily: 'Tajawal')),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('حذف', style: TextStyle(fontFamily: 'Tajawal')),
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
