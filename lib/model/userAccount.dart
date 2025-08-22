class UserAccount {
  String uid;
  String name;
  String email;
  String password;
  String confirmPassword;
  String accountType; 
  String? companyName;
  String? taxNumber;
  String role;

  UserAccount({
    required this.uid,
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.accountType,
    this.companyName,
    this.taxNumber,
    this.role = 'user', 
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'accountType': accountType,
      'companyName': companyName,
      'taxNumber': taxNumber,
      'role': role, 
    };
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: '',
      confirmPassword: '',
      accountType: json['accountType'] ?? 'فرد',
      companyName: json['companyName'],
      taxNumber: json['taxNumber'],
      role: json['role'] ?? 'user', 
    );
  }
}
