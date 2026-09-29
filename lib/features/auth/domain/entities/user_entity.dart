/// 使用者實體 (Domain Entity)
class UserEntity {
  const UserEntity({
    required this.id,
    this.email,
    required this.displayName,
    this.photoUrl,
    this.isGuest = false,
  });

  final String id;
  final String? email;
  final String displayName;
  final String? photoUrl;
  final bool isGuest;

  /// 建立訪客使用者實體
  factory UserEntity.guest() {
    return UserEntity(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      displayName: '熱血健身訪客',
      isGuest: true,
    );
  }

  /// 建立變更部分屬性後之新實體
  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isGuest,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}
