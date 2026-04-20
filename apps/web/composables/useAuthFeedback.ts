function extractAuthErrorParts(error: unknown) {
  if (!error || typeof error !== 'object') {
    return {
      code: '',
      message: ''
    }
  }

  const record = error as Record<string, unknown>

  return {
    code: typeof record.code === 'string' ? record.code : '',
    message: typeof record.message === 'string' ? record.message : ''
  }
}

export function useAuthFeedback() {
  function getSignUpSuccessMessage(hasSession: boolean) {
    if (hasSession) {
      return '注册成功，已自动登录。'
    }

    return '注册成功。请检查邮箱中的确认链接；如果暂时没收到，可能是发送限流，稍后再试或改用登录。'
  }

  function mapAuthError(error: unknown) {
    const { code, message } = extractAuthErrorParts(error)
    const normalized = `${code} ${message}`.toLowerCase()

    if (normalized.includes('over_email_send_rate_limit')) {
      return '当前注册确认邮件发送过于频繁，请稍后再试。若你之前已注册成功，请先去邮箱确认，或直接尝试登录。'
    }

    if (normalized.includes('email not confirmed')) {
      return '邮箱还未确认。请先点击确认邮件中的链接，再回来登录。'
    }

    if (normalized.includes('invalid login credentials')) {
      return '邮箱或密码不正确；如果你刚注册，先检查邮箱是否已完成确认。'
    }

    if (normalized.includes('email_address_invalid')) {
      return '邮箱格式无效，请换一个真实可用的邮箱地址。'
    }

    if (normalized.includes('user already registered')) {
      return '该邮箱已经注册，可以直接登录；如果忘记密码，后续可补充找回流程。'
    }

    if (normalized.includes('signup is disabled')) {
      return '当前项目暂未开放注册，请联系管理员。'
    }

    if (normalized.includes('rate limit')) {
      return '请求过于频繁，请稍后再试。'
    }

    return message || '认证请求失败，请稍后重试。'
  }

  function getResetPasswordSuccessMessage() {
    return '重置密码邮件已发送。请检查邮箱，并在邮件打开的网站页面里设置新密码。'
  }

  function getResendConfirmationSuccessMessage() {
    return '确认邮件已重新发送。请检查收件箱和垃圾邮件文件夹。'
  }

  function getMagicLinkSentMessage() {
    return '登录链接已发送到你的邮箱。请检查收件箱，点击邮件中的链接即可登录。'
  }

  function getOtpSentMessage() {
    return '验证码已发送到你的邮箱。请查收并输入 6 位验证码完成登录。'
  }

  function getPasswordUpdatedSuccessMessage() {
    return '密码已更新，请使用新密码登录。'
  }

  return {
    getSignUpSuccessMessage,
    getResetPasswordSuccessMessage,
    getResendConfirmationSuccessMessage,
    getMagicLinkSentMessage,
    getOtpSentMessage,
    getPasswordUpdatedSuccessMessage,
    mapAuthError
  }
}
