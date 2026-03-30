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
