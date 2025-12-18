import 'package:flutter/material.dart';
import '../../widgets/backgroundUi.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'شروط الخدمة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: FlowerBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'شروط الخدمة لتطبيق Glamify',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                        color: Color(0xFF2E2E2E),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'تاريخ آخر تحديث: ديسمبر 2024',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Tajawal',
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    _buildSection(
                      'الموافقة على الشروط',
                      'باستخدام تطبيق Glamify، فإنك توافق على الالتزام بهذه الشروط والأحكام. إذا كنت لا توافق على أي من هذه الشروط، يرجى عدم استخدام التطبيق.',
                    ),
                    
                    _buildSection(
                      'وصف الخدمة',
                      '''Glamify هو تطبيق للتجميل والعناية الشخصية يوفر:
• تصفح وشراء منتجات التجميل
• إدارة الطلبات والفواتير
• خدمة العملاء والدعم الفني
• عروض وخصومات حصرية''',
                    ),
                    
                    _buildSection(
                      'التسجيل والحساب',
                      '''• يجب أن تكون 18 عاماً أو أكثر لاستخدام التطبيق
• يجب تقديم معلومات صحيحة ودقيقة عند التسجيل
• أنت مسؤول عن الحفاظ على سرية كلمة المرور
• يجب إخطارنا فوراً بأي استخدام غير مصرح به لحسابك''',
                    ),
                    
                    _buildSection(
                      'الطلبات والدفع',
                      '''• جميع الأسعار معروضة بالريال السعودي شاملة ضريبة القيمة المضافة
• نحتفظ بالحق في تعديل الأسعار دون إشعار مسبق
• الدفع مطلوب وقت تأكيد الطلب
• نقبل جميع وسائل الدفع الإلكترونية المعتمدة
• يمكن إلغاء الطلب خلال ساعة من التأكيد''',
                    ),
                    
                    _buildSection(
                      'التوصيل والإرجاع',
                      '''• نوصل لجميع مناطق المملكة العربية السعودية
• مدة التوصيل من 2-5 أيام عمل
• يمكن إرجاع المنتجات خلال 14 يوم من التسليم
• المنتجات المرتجعة يجب أن تكون في حالتها الأصلية
• تكلفة الإرجاع على العميل ما لم يكن هناك عيب في المنتج''',
                    ),
                    
                    _buildSection(
                      'الاستخدام المقبول',
                      '''يُمنع استخدام التطبيق لـ:
• أي أنشطة غير قانونية أو احتيالية
• انتهاك حقوق الملكية الفكرية
• نشر محتوى مسيء أو ضار
• محاولة اختراق أو إتلاف النظام
• إنشاء حسابات وهمية متعددة''',
                    ),
                    
                    _buildSection(
                      'الملكية الفكرية',
                      'جميع المحتويات في التطبيق محمية بحقوق الطبع والنشر والعلامات التجارية. لا يجوز نسخ أو توزيع أو تعديل أي محتوى دون إذن كتابي مسبق.',
                    ),
                    
                    _buildSection(
                      'إخلاء المسؤولية',
                      '''• التطبيق متاح "كما هو" دون ضمانات من أي نوع
• لا نضمن دقة أو اكتمال المعلومات
• لا نتحمل مسؤولية الأضرار غير المباشرة
• مسؤوليتنا محدودة بقيمة الطلب المتأثر''',
                    ),
                    
                    _buildSection(
                      'تعديل الشروط',
                      'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إشعارك بالتغييرات المهمة عبر التطبيق أو البريد الإلكتروني.',
                    ),
                    
                    _buildSection(
                      'القانون المطبق',
                      'تخضع هذه الشروط لقوانين المملكة العربية السعودية. أي نزاع سيتم حله في المحاكم السعودية المختصة.',
                    ),
                    
                    _buildSection(
                      'التواصل',
                      '''للاستفسارات حول شروط الخدمة:
• البريد الإلكتروني: info@glamify-app.com
• الهاتف: +966554055582
• ساعات العمل: الأحد - الخميس، 9 صباحاً - 6 مساءً''',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
            color: Color(0xFF2E2E2E),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Tajawal',
            color: Color(0xFF555555),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }
}
