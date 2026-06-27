class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  final String email;
  final String displayName;
  final String password;

  const RegisterRequest({
    required this.email,
    required this.displayName,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'display_name': displayName,
        'password': password,
      };
}

/// Token pair returned by `/auth/login`, `/auth/register`, `/auth/refresh`.
/// The backend returns only tokens here; the user is fetched via `/auth/me`.
class AuthResponse {
  final String accessToken;
  final String? refreshToken;

  const AuthResponse({
    required this.accessToken,
    this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String?,
      );
}

class User {
  final String id;
  final String email;
  final String displayName;
  final int level;
  final int totalXp;
  final int coins;
  final int currentStreak;
  final int longestStreak;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.level,
    required this.totalXp,
    required this.coins,
    required this.currentStreak,
    required this.longestStreak,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id']?.toString() ?? '',
        email: json['email'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        level: (json['level'] as num?)?.toInt() ?? 1,
        totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
        longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
        avatarUrl: json['avatar_url'] as String?,
      );

  User copyWith({
    int? level,
    int? totalXp,
    int? coins,
    int? currentStreak,
    int? longestStreak,
    String? avatarUrl,
  }) =>
      User(
        id: id,
        email: email,
        displayName: displayName,
        level: level ?? this.level,
        totalXp: totalXp ?? this.totalXp,
        coins: coins ?? this.coins,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}
