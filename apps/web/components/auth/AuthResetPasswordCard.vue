<script setup lang="ts">
const route = useRoute()
const client = useSupabaseClient()
const { updatePassword } = useAuthActions()
const { getPasswordUpdatedSuccessMessage, mapAuthError } = useAuthFeedback()

const loading = ref(true)
const ready = ref(false)
const pending = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const password = ref('')
const confirmPassword = ref('')

async function prepareRecoverySession() {
  const tokenHash = typeof route.query.token_hash === 'string' ? route.query.token_hash : ''

  if (!tokenHash) {
    errorMessage.value = '缺少重置凭证，请重新打开邮件中的完整链接。'
    loading.value = false
    return
  }

  const { error } = await client.auth.verifyOtp({
    token_hash: tokenHash,
    type: 'recovery'
  })

  if (error) {
    errorMessage.value = mapAuthError(error)
    loading.value = false
    return
  }

  ready.value = true
  loading.value = false
}

async function handleSubmit() {
  errorMessage.value = ''
  successMessage.value = ''

  if (password.value.length < 6) {
    errorMessage.value = '新密码至少需要 6 位。'
    return
  }

  if (password.value !== confirmPassword.value) {
    errorMessage.value = '两次输入的密码不一致。'
    return
  }

  pending.value = true

  try {
    await updatePassword(password.value)
    successMessage.value = getPasswordUpdatedSuccessMessage()
    ready.value = false
  } catch (error) {
    errorMessage.value = mapAuthError(error)
  } finally {
    pending.value = false
  }
}

onMounted(async () => {
  await prepareRecoverySession()
})
</script>

<template>
  <UCard class="glass-panel rounded-[2rem]">
    <template #header>
      <div class="space-y-3">
        <span class="eyebrow">
          <UIcon name="i-lucide-key-round" />
          密码重置
        </span>
        <h1 class="text-3xl font-semibold text-slate-900">设置新密码</h1>
      </div>
    </template>

    <div class="space-y-5">
      <p v-if="loading" class="text-sm leading-6 text-slate-600">
        正在验证重置链接，请稍候。
      </p>

      <UAlert
        v-if="errorMessage"
        color="error"
        variant="soft"
        title="无法继续"
        :description="errorMessage"
      />

      <UAlert
        v-if="successMessage"
        color="success"
        variant="soft"
        title="密码已更新"
        :description="successMessage"
      />

      <form v-if="ready" class="space-y-4" @submit.prevent="handleSubmit">
        <div class="space-y-2">
          <label class="text-sm font-medium text-slate-700" for="new-password">新密码</label>
          <UInput id="new-password" v-model="password" type="password" size="xl" placeholder="至少 6 位" required />
        </div>

        <div class="space-y-2">
          <label class="text-sm font-medium text-slate-700" for="confirm-password">确认新密码</label>
          <UInput id="confirm-password" v-model="confirmPassword" type="password" size="xl" placeholder="再次输入" required />
        </div>

        <UButton type="submit" size="xl" block :loading="pending">
          更新密码
        </UButton>
      </form>

      <UButton to="/login" size="xl" block variant="soft">
        返回登录
      </UButton>
    </div>
  </UCard>
</template>
