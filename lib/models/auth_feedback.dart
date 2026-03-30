class AuthFeedback {
  const AuthFeedback._();

  static String signUpSuccess({required bool hasSession}) {
    if (hasSession) {
      return '注册成功，已自动登录';
    }

    return '注册成功，请检查邮箱确认链接；如果暂时没收到，可能是发送限流，请稍后再试或直接尝试登录';
  }

  static String resetPasswordSuccess() {
    return '重置密码邮件已发送，请检查邮箱，并在邮件打开的网站页面里设置新密码';
  }

  static String resendConfirmationSuccess() {
    return '确认邮件已重新发送，请检查收件箱和垃圾邮件文件夹';
  }

  static String fromError(Object error) {
    final raw = error.toString();
    final normalized = raw.toLowerCase();

    if (normalized.contains('over_email_send_rate_limit')) {
      return '当前注册确认邮件发送过于频繁，请稍后再试。若你之前已注册成功，请先去邮箱确认，或直接尝试登录。';
    }

    if (normalized.contains('email not confirmed')) {
      return '邮箱还未确认。请先点击确认邮件中的链接，再回来登录。';
    }

    if (normalized.contains('invalid login credentials')) {
      return '邮箱或密码不正确；如果你刚注册，先检查邮箱是否已完成确认。';
    }

    if (normalized.contains('email_address_invalid')) {
      return '邮箱格式无效，请换一个真实可用的邮箱地址。';
    }

    if (normalized.contains('user already registered')) {
      return '该邮箱已经注册，可以直接登录。';
    }

    if (normalized.contains('signup is disabled')) {
      return '当前项目暂未开放注册，请联系管理员。';
    }

    if (normalized.contains('rate limit')) {
      return '请求过于频繁，请稍后再试。';
    }

    return raw.replaceFirst('Exception: ', '');
  }
}
