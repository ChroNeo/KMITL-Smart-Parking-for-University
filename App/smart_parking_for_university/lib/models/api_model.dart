class RegisterRequest {
  final String email;
  final String password;
  final String fullname;
  final String phoneNumber;
  final String carBrand;
  final String carRegistration;
  final String carProvince;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.fullname,
    required this.phoneNumber,
    required this.carBrand,
    required this.carRegistration,
    required this.carProvince
  });

  Map<String, dynamic> toJson() => {
        "email": email,
        "password": password,
        "fullname": fullname,
        "phone_number": phoneNumber,
        "car_brand": carBrand,
        "car_registration": carRegistration,
        "car_province": carProvince,
      };
}
