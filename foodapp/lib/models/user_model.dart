class UserModel {
  final String uid;
  final String email;
  final String name;
  final String contactNumber;
  final String profilePicture;
  final bool isAdmin;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.contactNumber,
    required this.profilePicture,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'contactNumber': contactNumber,
      'profilePicture': profilePicture,
      'isAdmin': isAdmin,
    };
  }

  // factory UserModel.fromMap(Map<String, dynamic> map) {
  //   return UserModel(
  //     uid: map['uid'],
  //     email: map['email'],
  //     name: map['name'],
  //     contactNumber: map['contactNumber'],
  //     profilePicture: map['profilePicture'],
  //     isAdmin: map['isAdmin'] ?? false,
  //   );
  // }

  factory UserModel.fromMap(Map<String, dynamic> map) {
  return UserModel(
    uid: map['uid'] ?? '',
    email: map['email'] ?? '',
    name: map['name'] ?? '',
    contactNumber: map['contactNumber'] ?? '',
    profilePicture: map['profilePicture'] ?? '',
    isAdmin: map['isAdmin'] ?? false,
  );
}
}