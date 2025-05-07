class UserData {
  UserData({
    required this.id,
    required this.isOonline,
    required this.createdAt,
    required this.image,
    required this.email,
    required this.pushToken,
    required this.about,
    required this.lastActive,
    required this.name,
  });

  final String? id;
  final bool? isOonline;
  final String? createdAt;
  final String? image;
  final String? email;
  final String? pushToken;
  final String? about;
  final String? lastActive;
  final String? name;

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json["id"],
      isOonline: json["is_oonline"],
      createdAt: json["created_at"],
      image: json["image"],
      email: json["email"],
      pushToken: json["push_token"],
      about: json["about"],
      lastActive: json["last_active"],
      name: json["name"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "is_oonline": isOonline,
        "created_at": createdAt,
        "image": image,
        "email": email,
        "push_token": pushToken,
        "about": about,
        "last_active": lastActive,
        "name": name,
      };
}
