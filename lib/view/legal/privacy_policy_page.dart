import 'package:flutter/material.dart';
import '../../widgets/backgroundUi.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'سياسة الخصوصية',
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
                      'سياسة الخصوصية لتطبيق Glamify',
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
                      'مقدمة',
                      'نحن في Glamify نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية. توضح هذه السياسة كيفية جمع واستخدام وحماية معلوماتك عند استخدام تطبيقنا.',
                    ),
                    
                    _buildSection(
                      'المعلومات التي نجمعها',
                      '''• معلومات الحساب: الاسم، البريد الإلكتروني، رقم الهاتف
• معلومات الطلبات: تفاصيل المنتجات، العناوين، تاريخ الطلبات
• معلومات الجهاز: نوع الجهاز، نظام التشغيل، معرف الجهاز
• معلومات الاستخدام: كيفية تفاعلك مع التطبيق والخدمات''',
                    ),
                    
                    _buildSection(
                      'كيف نستخدم معلوماتك',
                      '''• تقديم وتحسين خدماتنا
• معالجة الطلبات والمدفوعات
• إرسال الإشعارات المهمة
• تخصيص تجربة المستخدم
• الامتثال للمتطلبات القانونية''',
                    ),
                    
                    _buildSection(
                      'مشاركة المعلومات',
                      '''نحن لا نبيع أو نؤجر معلوماتك الشخصية لأطراف ثالثة. قد نشارك معلوماتك فقط في الحالات التالية:
• مع مقدمي الخدمات الموثوقين لتشغيل التطبيق
• عند الضرورة القانونية أو لحماية حقوقنا
• بموافقتك الصريحة''',
                    ),
                    
                    _buildSection(
                      'أمان البيانات',
                      '''نستخدم تدابير أمنية متقدمة لحماية بياناتك:
• تشفير البيانات أثناء النقل والتخزين
• مصادقة متعددة العوامل
• مراقبة مستمرة للأنشطة المشبوهة
• تحديثات أمنية منتظمة''',
                    ),
                    
                    _buildSection(
                      'حقوقك',
                      '''لديك الحق في:
• الوصول إلى بياناتك الشخصية
• تصحيح أو تحديث معلوماتك
• حذف حسابك وبياناتك
• سحب الموافقة في أي وقت
• تقديم شكوى لدى السلطات المختصة''',
                    ),
                    
                    _buildSection(
                      'ملفات تعريف الارتباط',
                      'نستخدم ملفات تعريف الارتباط وتقنيات مشابهة لتحسين أداء التطبيق وتخصيص تجربتك. يمكنك إدارة تفضيلاتك من إعدادات التطبيق.',
                    ),
                    
                    _buildSection(
                      'التغييرات على هذه السياسة',
                      'قد نحدث هذه السياسة من وقت لآخر. سنخطرك بأي تغييرات مهمة عبر التطبيق أو البريد الإلكتروني.',
                    ),
                    
                    _buildSection(
                      'اتصل بنا',
                      '''إذا كان لديك أي أسئلة حول سياسة الخصوصية هذه، يرجى التواصل معنا:
• البريد الإلكتروني: info@glamify-app.com
• الهاتف: +966554055582
• العنوان: المملكة العربية السعودية''',
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
