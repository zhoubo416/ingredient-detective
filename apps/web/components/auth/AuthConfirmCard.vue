<script setup lang="ts">
const route = useRoute()
const client = useSupabaseClient()

const loading = ref(true)
const errorMessage = ref('')
const successMessage = ref('')

function normalizeVerifyType(type: string) {
  if (type === 'recovery') {
    return 'recovery'
  }

  if (type === 'invite' || type === 'email_change') {
    return type
  }

  return 'email'
}

onMounted(async () => {
  const tokenHash = typeof route.query.token_hash === 'string' ? route.query.token_hash : ''
  const rawType = typeof route.query.type === 'string' ? route.query.type : ''
  const oauthCode = typeof route.query.code === 'string' ? route.query.code : ''
  const oauthError = typeof route.query.error_description === 'string' ? route.query.error_description : ''
  const hasHashSession = typeof window !== 'undefined' && window.location.hash.includes('access_token')

  if (oauthError) {
    errorMessage.value = oauthError
    loading.value = false
    return
  }

  // OAuth (Apple/Google) callback: client auto-detects ?code=... or #access_token=... during init,
  // exchanges the code, saves the session. Just wait for it to finish, then redirect.
  if (oauthCode || hasHashSession) {
    const { data: { session }, error } = await client.auth.getSession()
    if (error) {
      errorMessage.value = error.message
      loading.value = false
      return
    }

    if (!session) {
      errorMessage.value = '登录失败：未获得会话，请重试。'
      loading.value = false
      return
    }

    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/dashboard/history'
    await navigateTo(redirect, { replace: true })
    return
  }

  // Email verification link
  if (!tokenHash) {
    errorMessage.value = '确认链接缺少 token，请重新打开邮件中的完整链接。'
    loading.value = false
    return
  }

  const { error } = await client.auth.verifyOtp({
    token_hash: tokenHash,
    type: normalizeVerifyType(rawType)
  })

  if (error) {
    errorMessage.value = error.message
    loading.value = false
    return
  }

  successMessage.value = '邮箱确认成功。现在可以返回登录页继续使用。'
  loading.value = false
})
</script>

<template>
  <UCard class="glass-panel rounded-[2rem]">
    <template #header>
      <div class="space-y-3">
        <span class="eyebrow">
          <UIcon name="i-lucide-mail-check" />
          邮箱确认
        </span>
        <h1 class="text-3xl font-semibold text-slate-900">正在确认你的邮箱</h1>
      </div>
    </template>

    <div class="space-y-4">
      <p v-if="loading" class="text-sm leading-6 text-slate-600">
        正在验证邮件里的确认链接，请稍候。
      </p>

      <UAlert
        v-if="errorMessage"
        color="error"
        variant="soft"
        title="确认失败"
        :description="errorMessage"
      />

      <UAlert
        v-if="successMessage"
        color="success"
        variant="soft"
        title="确认成功"
        :description="successMessage"
      />

      <UButton to="/login" size="xl" block>
        返回登录
      </UButton>
    </div>
  </UCard>
</template>
