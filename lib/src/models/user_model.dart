enum UserRole { user, vendor }

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String mobile;
  final String city;
  final String pincode;
  final String address;
  final UserRole role;
  final DateTime createdAt;
  
  // Vendor specific fields
  final String? businessName;
  final String? ownerName;
  final String? category;
  final String? aadharCard;
  final String? panCard;
  final String? license;
  final String? licenseDocument;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.city,
    required this.pincode,
    required this.address,
    required this.role,
    required this.createdAt,
    this.businessName,
    this.ownerName,
    this.category,
    this.aadharCard,
    this.panCard,
    this.license,
    this.licenseDocument,
  });

  // Factory constructor for creating UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      city: json['city'] ?? '',
      pincode: json['pincode'] ?? '',
      address: json['address'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.user,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      businessName: json['businessName'],
      ownerName: json['ownerName'],
      category: json['category'],
      aadharCard: json['aadharCard'],
      panCard: json['panCard'],
      license: json['license'],
      licenseDocument: json['licenseDocument'],
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'mobile': mobile,
      'city': city,
      'pincode': pincode,
      'address': address,
      'role': role.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      if (businessName != null) 'businessName': businessName,
      if (ownerName != null) 'ownerName': ownerName,
      if (category != null) 'category': category,
      if (aadharCard != null) 'aadharCard': aadharCard,
      if (panCard != null) 'panCard': panCard,
      if (license != null) 'license': license,
      if (licenseDocument != null) 'licenseDocument': licenseDocument,
    };
  }

  // Copy with method for updating user data
  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? mobile,
    String? city,
    String? pincode,
    String? address,
    UserRole? role,
    DateTime? createdAt,
    String? businessName,
    String? ownerName,
    String? category,
    String? aadharCard,
    String? panCard,
    String? license,
    String? licenseDocument,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      address: address ?? this.address,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      category: category ?? this.category,
      aadharCard: aadharCard ?? this.aadharCard,
      panCard: panCard ?? this.panCard,
      license: license ?? this.license,
      licenseDocument: licenseDocument ?? this.licenseDocument,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, fullName: $fullName, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Vendor categories
class VendorCategories {
  static const List<String> categories = [
    'Salon',
    'Shop',
    'Restaurant',
    'Grocery Store',
    'Electronics',
    'Clothing',
    'Pharmacy',
    'Bakery',
    'Hardware Store',
    'Beauty Parlor',
    'Gym/Fitness',
    'Laundry',
    'Mobile Repair',
    'Automobile Service',
    'Other',
  ];
}