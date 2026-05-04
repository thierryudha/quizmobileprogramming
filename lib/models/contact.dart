class Contact {
  String? id;
  String name;
  String phone;

  Contact(this.name, this.phone);

  Contact.fromMap(Map<String, dynamic> map, String documentId)
      : id = documentId,
        name = map['name'] ?? '',
        phone = map['phone'] ?? '';

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}