class CustomerModel {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }
}
