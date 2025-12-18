import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:glamify/controller/Auth_Service.dart';
import 'package:glamify/model/userAccount.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glamify/view/bottomNavUi.dart';
import 'package:glamify/widgets/ElegantToast.dart';
import 'package:glamify/widgets/FormFields.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/buttonsWidgets.dart';

class CompleteProfileUi extends StatefulWidget {
  final User user;
  const CompleteProfileUi({super.key, required this.user});

  @override
  State<CompleteProfileUi> createState() => _CompleteProfileUiState();
}

class _CompleteProfileUiState extends State<CompleteProfileUi> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController taxNumberController = TextEditingController();
  String? _selectedAccountType = 'فرد';
  final List<String> _accountTypes = ['فرد', 'شركة'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.user.displayName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return FlowerBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _buildAnimatedContainer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAnimatedHeader(),
                      const SizedBox(height: 40.0),
                      _buildForm(),
                      const SizedBox(height: 30.0),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedContainer({required Widget child}) {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
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
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedHeader() {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: child,
          ),
        );
      },
      child: const Text(
        'إكمال التسجيل',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            GlassField(
              controller: nameController,
              hintText: 'الاسم الكامل',
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال اسمك';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildAccountTypeDropdown(),
            _buildCompanyFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedAccountType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          style: const TextStyle(
            color: Colors.black87,
            fontFamily: 'Tajawal',
            fontSize: 16,
          ),
          dropdownColor: const Color(0xFFF9D5D3),
          items: _accountTypes.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedAccountType = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCompanyFields() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _selectedAccountType == 'شركة'
          ? Column(
              key: const ValueKey('company-fields'),
              children: [
                const SizedBox(height: 20),
                GlassField(
                  controller: companyNameController,
                  hintText: 'اسم الشركة',
                  prefixIcon: Icons.business,
                  validator: (value) {
                    if (_selectedAccountType == 'شركة' && (value == null || value.isEmpty)) {
                      return 'يرجى إدخال اسم الشركة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                GlassField(
                  controller: taxNumberController,
                  hintText: 'الرقم الضريبي',
                  prefixIcon: Icons.receipt_long,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_selectedAccountType == 'شركة' && (value == null || value.isEmpty)) {
                      return 'يرجى إدخال الرقم الضريبي';
                    }
                    return null;
                  },
                ),
              ],
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }

  Widget _buildSubmitButton() {
    return GradientElevatedButton(
      text: 'حفظ ومتابعة',
      isLoading: _isLoading,
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          setState(() {
            _isLoading = true;
          });

          final userAccount = UserAccount(
            uid: widget.user.uid,
            name: nameController.text.trim(),
            email: widget.user.email!,
            accountType: _selectedAccountType!,
            role: 'user',
            password: '', // Not needed for Google sign-in
            confirmPassword: '', // Not needed for Google sign-in
            companyName: _selectedAccountType == 'شركة' ? companyNameController.text.trim() : null,
            taxNumber: _selectedAccountType == 'شركة' ? taxNumberController.text.trim() : null,
          );

          final authService = AuthService();
          final result = await authService.updateUserProfile(userAccount);

          if (mounted) {
            if (result == null) {
              // Success - Save session and navigate
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('uid', userAccount.uid);
              await prefs.setString('userName', userAccount.name);
              await prefs.setString('email', userAccount.email);
              await prefs.setBool('isLoggedIn', true);
              await prefs.setString('role', userAccount.role);

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const Run()),
                (Route<dynamic> route) => false,
              );
            } else {
              // Error
              showElegantToast(context, result, isSuccess: false);
            }
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
    );
  }
}
