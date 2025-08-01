class EmergencyContact {
  final String? name;
  final String? phone;
  final String? relationship;

  EmergencyContact({this.name, this.phone, this.relationship});

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'],
      phone: json['phone'],
      relationship: json['relationship'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'relationship': relationship,
  };
}

class Profile {
  final String? id;
  final String? fullName;
  final String? gender;
  final String? dob;
  final String? address;
  final String? avatar;
  final String? identityNumber;
  final String? issuedDate;
  final String? issuedPlace;
  final String? nationality;
  final EmergencyContact? emergencyContact;

  Profile({
    this.id,
    this.fullName,
    this.gender,
    this.dob,
    this.address,
    this.avatar,
    this.identityNumber,
    this.issuedDate,
    this.issuedPlace,
    this.nationality,
    this.emergencyContact,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      fullName: json['fullName'],
      gender: json['gender'],
      dob: json['dob'],
      address: json['address'],
      avatar: json['avatar'],
      identityNumber: json['identityNumber'],
      issuedDate: json['issuedDate'],
      issuedPlace: json['issuedPlace'],
      nationality: json['nationality'],
      emergencyContact: json['emergencyContact'] != null
          ? EmergencyContact.fromJson(json['emergencyContact'])
          : null,
    );
  }
}
