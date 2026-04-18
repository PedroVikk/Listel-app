class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? username;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.username,
    this.avatarUrl,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? username,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          username == other.username &&
          avatarUrl == other.avatarUrl;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      username.hashCode ^
      avatarUrl.hashCode;
}
