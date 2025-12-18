import 'package:flutter/material.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/custom_admin_header.dart';
import 'package:glamify/widgets/elegant_dialog.dart';
import 'package:glamify/widgets/FormFields.dart';
import 'package:glamify/widgets/buttonsWidgets.dart';

class HelpAndSupportPage extends StatefulWidget {
  const HelpAndSupportPage({super.key});

  @override
  State<HelpAndSupportPage> createState() => _HelpAndSupportPageState();
}

class _HelpAndSupportPageState extends State<HelpAndSupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Show elegant dialog
      showElegantDialog(
        context: context,
        child: ConfirmActionDialog(
          message:
              'هذه الخدمة غير متاحة حاليًا. نحن نعمل على تطويرها وسنطلقها قريبًا.',
          confirmText: 'حسنًا',
          onConfirm: () {},
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlowerBackground(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              const CustomAdminHeader(
                title: 'المساعدة والدعم',
                subtitle: 'تواصل معنا لأي استفسار.',
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9D5D3).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GlassField(
                              controller: _subjectController,
                              hintText: 'الموضوع',
                              prefixIcon: Icons.subject,
                              validator: (value) => value!.isEmpty
                                  ? 'الرجاء إدخال الموضوع'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            GlassField(
                              controller: _messageController,
                              hintText: 'الرسالة',
                              prefixIcon: Icons.message,
                              maxLines: 5,
                              validator: (value) =>
                                  value!.isEmpty ? 'الرجاء إدخال رسالتك' : null,
                            ),
                            const SizedBox(height: 30),
                            GradientElevatedButton(
                              text: 'إرسال',
                              onPressed: _submitForm,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
