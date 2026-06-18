import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:glamify/controller/company_service.dart';
import 'package:glamify/model/company.dart';
import 'package:glamify/view/admin_view/add_company_form.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/custom_admin_header.dart';
import 'package:glamify/widgets/loader.dart';
import 'package:glamify/widgets/FormFields.dart';

class ManageCompaniesScreen extends StatefulWidget {
  const ManageCompaniesScreen({super.key});

  @override
  State<ManageCompaniesScreen> createState() => _ManageCompaniesScreenState();
}

class _ManageCompaniesScreenState extends State<ManageCompaniesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<List<Company>>? _companiesFuture;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  void _loadCompanies() {
    setState(() {
      _companiesFuture = CompanyService().getCompaniesFuture();
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
                title: 'إدارة الماركات',
                subtitle: 'استعراض أسماء الماركات التي يتم التعامل معها',
              ),
              // حقل البحث
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: GlassField(
                  controller: _searchController,
                  hintText: 'ابحث عن ماركة...',
                  prefixIcon: Icons.search,
                  textColor: Colors.black,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _loadCompanies();
                    await _companiesFuture;
                  },
                  child: FutureBuilder<List<Company>>(
                    future: _companiesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Loader());
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
                                'لا توجد ماركات حالياً.',
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

                    final companies = snapshot.data!;

                    // فلترة حسب البحث
                    final filteredCompanies = _searchQuery.isEmpty
                        ? companies
                        : companies
                              .where(
                                (c) => c.name.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ),
                              )
                              .toList();

                    if (filteredCompanies.isEmpty) {
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
                      itemCount: filteredCompanies.length,
                      itemBuilder: (context, index) {
                        final company = filteredCompanies[index];
                        return PlayAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(
                            milliseconds: 300 + ((index % 6) * 80),
                          ),
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
                          child: _buildCompanyCard(company),
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
              MaterialPageRoute(builder: (context) => const AddCompanyForm()),
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

  Widget _buildCompanyCard(Company company) {
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
              backgroundImage: company.logoUrl != null
                  ? NetworkImage(company.logoUrl!)
                  : null,
              child: company.logoUrl == null
                  ? const Icon(
                      Icons.business,
                      size: 30,
                      color: Color(0xFF52002C),
                    )
                  : null,
            ),
            title: Text(
              company.name,
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
                  _editCompany(company);
                } else if (value == 'delete') {
                  _deleteCompany(company.id);
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

  void _editCompany(Company company) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddCompanyForm(company: company)),
    );
  }

  void _deleteCompany(String companyId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد أنك تريد حذف هذه الشركة؟'),
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
                CompanyService().deleteCompany(companyId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
