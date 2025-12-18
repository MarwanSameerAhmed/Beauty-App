import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:glamify/controller/company_service.dart';
import 'package:glamify/model/company.dart';
import 'package:glamify/view/admin_view/add_company_form.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/custom_admin_header.dart';
import 'package:glamify/widgets/loader.dart';

class ManageCompaniesScreen extends StatefulWidget {
  const ManageCompaniesScreen({super.key});

  @override
  State<ManageCompaniesScreen> createState() => _ManageCompaniesScreenState();
}

class _ManageCompaniesScreenState extends State<ManageCompaniesScreen> {
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
                title: 'إدارة الشركات',
                subtitle: 'استعراض أسماء الشركات التي يتم التعامل معها',
              ),
              Expanded(
                child: StreamBuilder<List<Company>>(
                  stream: CompanyService().getCompanies(),
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
                          'لا توجد شركات حالياً.',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                      );
                    }

                    final companies = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: companies.length,
                      itemBuilder: (context, index) {
                        final company = companies[index];
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
                          child: _buildCompanyCard(company),
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
      MaterialPageRoute(
        builder: (context) => AddCompanyForm(company: company),
      ),
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
