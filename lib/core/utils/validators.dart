String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return '이메일을 입력하세요';
  final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  if (!emailReg.hasMatch(value.trim())) return '유효한 이메일을 입력하세요';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return '비밀번호를 입력하세요';
  if (value.length < 6) return '비밀번호는 최소 6자 이상입니다';
  return null;
}

String? validateNickname(String? value) {
  if (value == null || value.trim().isEmpty) return '닉네임을 입력하세요';
  if (value.trim().length < 2) return '닉네임은 최소 2자 이상입니다';
  return null;
}