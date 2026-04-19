class Friend {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? username;
  final DateTime addedAt;

  const Friend({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.username,
    required this.addedAt,
  });

  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  Friend copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    String? username,
    DateTime? addedAt,
  }) {
    return Friend(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      username: username ?? this.username,
      addedAt: addedAt ?? this.addedAt,
    );
  }

}
