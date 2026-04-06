<script setup lang="ts">
const user = useSupabaseUser()
const route = useRoute()
const { signIn, signUp, resendSignupConfirmation, requestPasswordReset } = useAuthActions()
const {
  getSignUpSuccessMessage,
  getResetPasswordSuccessMessage,
  getResendConfirmationSuccessMessage,
  mapAuthError
} = useAuthFeedback()

const mode = ref<'signin' | 'signup'>('signin')
const email = ref('')
const password = ref('')
const pending = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const redirectTarget = ref('')

watch(
  () => [user.value, redirectTarget.value, pending.value] as const,
  async ([currentUser, target, isPending]) => {
    if (!currentUser || !target || isPending) {
      return
    }

    redirectTarget.value = ''
    await navigateTo(target)
  }
)

async function handleResendConfirmation() {
  if (!email.value) {
    errorMessage.value = '请先输入邮箱，再重发确认邮件。'
    successMessage.value = ''
    return
  }

  pending.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    await resendSignupConfirmation(email.value)
    successMessage.value = getResendConfirmationSuccessMessage()
  } catch (error) {
    errorMessage.value = mapAuthError(error)
  } finally {
    pending.value = false
  }
}

async function handlePasswordReset() {
  if (!email.value) {
    errorMessage.value = '请先输入邮箱，再发送重置密码邮件。'
    successMessage.value = ''
    return
  }

  pending.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    await requestPasswordReset(email.value)
    successMessage.value = getResetPasswordSuccessMessage()
  } catch (error) {
    errorMessage.value = mapAuthError(error)
  } finally {
    pending.value = false
  }
}

async function handleSubmit() {
  pending.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    if (mode.value === 'signin') {
      await signIn(email.value, password.value)
      const target = (route.query.redirect as string) || '/dashboard'

      redirectTarget.value = target
      return
    }

    const data = await signUp(email.value, password.value)

    if (data.session) {
      redirectTarget.value = '/dashboard'
      return
    }

    successMessage.value = getSignUpSuccessMessage(Boolean(data.session))
  } catch (error) {
    errorMessage.value = mapAuthError(error)
  } finally {
    pending.value = false
  }
}
</script>

<template>
  <UCard class="glass-panel rounded-[2rem]">
    <template #header>
      <div class="space-y-4">
        <span class="eyebrow">
          <UIcon name="i-lucide-user-round-check" />
          Supabase Auth
        </span>
        <div>
          <h1 class="text-3xl font-semibold text-slate-900">登录后才能调用分析能力</h1>
          <p class="mt-3 text-sm leading-6 text-slate-600">
            邮箱密码认证由 Supabase 处理。登录成功后，网站会开放 OCR、AI 分析和历史记录接口。
          </p>
        </div>
      </div>
    </template>

    <div class="space-y-5">
      <div class="grid grid-cols-2 gap-2 rounded-2xl bg-slate-900/5 p-1">
        <button
          class="rounded-2xl px-4 py-3 text-sm font-semibold transition"
          :class="mode === 'signin' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500'"
          @click="mode = 'signin'"
        >
          登录
        </button>
        <button
          class="rounded-2xl px-4 py-3 text-sm font-semibold transition"
          :class="mode === 'signup' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500'"
          @click="mode = 'signup'"
        >
          注册
        </button>
      </div>

      <UAlert
        v-if="errorMessage"
        color="error"
        variant="soft"
        title="请求失败"
        :description="errorMessage"
      />

      <UAlert
        v-if="successMessage"
        color="success"
        variant="soft"
        title="注册成功"
        :description="successMessage"
      />

      <UAlert
        v-if="mode === 'signup'"
        color="info"
        variant="soft"
        title="注册说明"
        description="如果项目开启了邮箱确认，注册后需要先点确认邮件里的链接。短时间内频繁注册可能触发邮件发送限流。"
      />

      <form class="space-y-4" @submit.prevent="handleSubmit">
        <div class="space-y-2">
          <label class="text-sm font-medium text-slate-700" for="email">邮箱</label>
          <UInput
            id="email"
            v-model="email"
            class="w-full"
            type="email"
            size="xl"
            placeholder="name@example.com"
            required
          />
        </div>

        <div class="space-y-2">
          <label class="text-sm font-medium text-slate-700" for="password">密码</label>
          <UInput
            id="password"
            v-model="password"
            class="w-full"
            type="password"
            size="xl"
            placeholder="至少 6 位"
            required
          />
        </div>

        <UButton type="submit" size="xl" block :loading="pending">
          {{ mode === 'signin' ? '登录并进入后台' : '创建账号' }}
        </UButton>

        <p class="text-xs leading-6 text-slate-500">
          {{ mode === 'signin' ? '继续登录即表示你已阅读并同意' : '注册即表示你已阅读并同意' }}
          <NuxtLink class="apple-link" to="/terms">《用户协议》</NuxtLink>
          与
          <NuxtLink class="apple-link" to="/privacy-policy">《隐私政策》</NuxtLink>
        </p>

        <div class="flex flex-wrap gap-3 text-sm justify-end">
          <UButton
            v-if="mode === 'signin'"
            type="button"
            color="neutral"
            variant="ghost"
            :loading="pending"
            @click="handlePasswordReset"
          >
            忘记密码
          </UButton>

          <UButton
            type="button"
            color="neutral"
            variant="ghost"
            :loading="pending"
            @click="handleResendConfirmation"
          >
            重发确认邮件
          </UButton>
        </div>
      </form>
    </div>
  </UCard>
</template>
