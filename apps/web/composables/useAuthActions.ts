export function useAuthActions() {
  const client = useSupabaseClient()
  const config = useRuntimeConfig()

  function buildRedirectUrl(path: string) {
    const base = config.public.marketingSiteUrl || 'http://localhost:3000'
    return new URL(path, base).toString()
  }

  async function signIn(email: string, password: string) {
    const { error, data } = await client.auth.signInWithPassword({
      email,
      password
    })

    if (error) {
      throw error
    }

    return data
  }

  async function signUp(email: string, password: string) {
    const { error, data } = await client.auth.signUp({
      email,
      password,
      options: {
        emailRedirectTo: buildRedirectUrl('/auth/confirm')
      }
    })

    if (error) {
      throw error
    }

    return data
  }

  async function sendMagicLink(email: string) {
    const { error, data } = await client.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: buildRedirectUrl('/auth/confirm')
      }
    })

    if (error) {
      throw error
    }

    return data
  }

  async function verifyOtp(email: string, token: string) {
    const { error, data } = await client.auth.verifyOtp({
      email,
      token,
      type: 'email'
    })

    if (error) {
      throw error
    }

    return data
  }

  async function signInWithGoogle() {
    const { error, data } = await client.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: buildRedirectUrl('/auth/confirm')
      }
    })

    if (error) {
      throw error
    }

    return data
  }

  async function signInWithApple() {
    const { error, data } = await client.auth.signInWithOAuth({
      provider: 'apple',
      options: {
        redirectTo: buildRedirectUrl('/auth/confirm')
      }
    })

    if (error) {
      throw error
    }

    return data
  }

  async function resendSignupConfirmation(email: string) {
    const { error, data } = await client.auth.resend({
      type: 'signup',
      email
    })

    if (error) {
      throw error
    }

    return data
  }

  async function requestPasswordReset(email: string) {
    const { error, data } = await client.auth.resetPasswordForEmail(email, {
      redirectTo: buildRedirectUrl('/auth/reset-password')
    })

    if (error) {
      throw error
    }

    return data
  }

  async function updatePassword(password: string) {
    const { error, data } = await client.auth.updateUser({
      password
    })

    if (error) {
      throw error
    }

    return data
  }

  async function signOut() {
    const { error } = await client.auth.signOut()
    if (error) {
      throw error
    }
  }

  return {
    signIn,
    signUp,
    sendMagicLink,
    verifyOtp,
    signInWithGoogle,
    signInWithApple,
    resendSignupConfirmation,
    requestPasswordReset,
    updatePassword,
    signOut
  }
}
