class User {
  final String id;
  final String username;
  User({required this.id, required this.username});

  factory User.fromJson(Map<String, dynamic> json)
  {
    return switch(json) {
      {"id": String id, "username": String username} => User(
        id: id,
        username: username
      ) ,
    _ => throw const FormatException("Failed to load user"),
    };
  }
}