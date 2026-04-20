<script setup lang="ts">
const route = useRoute()
const { signIn, signUp, signInWithGoogle, signInWithApple } = useAuthActions()
const {
  getSignUpSuccessMessage,
  mapAuthError
} = useAuthFeedback()

const isSignUp = ref(false)
const email = ref('')
const password = ref('')
const pending = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

async function handleGoogleSignIn() {
  try {
    await signInWithGoogle()
  } catch (error) {
    errorMessage.value = mapAuthError(error)
  }
}

async function handleAppleSignIn() {
  try {
    await signInWithApple()
  } catch (error) {
    errorMessage.value = mapAuthError(error)
  }
}

async function handleSubmit() {
  pending.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    if (isSignUp.value) {
      const data = await signUp(email.value, password.value)

      if (data.session) {
        window.location.href = '/dashboard'
        return
      }

      successMessage.value = getSignUpSuccessMessage(Boolean(data.session))
    } else {
      await signIn(email.value, password.value)
      const target = (route.query.redirect as string) || '/dashboard'
      window.location.href = target
      return
    }
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
          用户认证
        </span>
        <div>
          <h1 class="text-3xl font-semibold text-slate-900">登录后才能调用分析能力</h1>
          <p class="mt-3 text-sm leading-6 text-slate-600">
            登录成功后，网站会开放 OCR、AI 分析和历史记录接口。
          </p>
        </div>
      </div>
    </template>

    <div class="space-y-4">
      <UButton
        color="neutral"
        variant="outline"
        size="xl"
        block
        class="gap-2"
        @click="handleGoogleSignIn"
      >
        <svg class="h-5 w-5" viewBox="0 0 24 24">
          <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"/>
          <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
          <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
          <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
        </svg>
        使用 Google 账号登录
      </UButton>

      <UButton
        color="neutral"
        variant="outline"
        size="xl"
        block
        class="gap-2"
        @click="handleAppleSignIn"
      >
        <svg class="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
          <path d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
        </svg>
        使用 Apple 账号登录
      </UButton>

      <div class="flex items-center gap-3">
        <div class="h-px flex-1 bg-slate-200" />
        <span class="text-xs text-slate-400">或使用邮箱登录</span>
        <div class="h-px flex-1 bg-slate-200" />
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
        title="操作成功"
        :description="successMessage"
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

        <UButton
          type="submit"
          size="xl"
          block
          :loading="pending"
          :color="isSignUp ? 'success' : 'primary'"
        >
          {{ isSignUp ? '创建账号' : '登录并进入后台' }}
        </UButton>

        <div class="flex items-center justify-between">
          <UButton
            type="button"
            color="neutral"
            variant="ghost"
            size="sm"
            @click="isSignUp = !isSignUp"
          >
            {{ isSignUp ? '已有账号？去登录' : '没有账号？去注册' }}
          </UButton>
        </div>

        <p class="text-xs leading-6 text-slate-500">
          {{ isSignUp ? '注册即表示你已阅读并同意' : '继续登录即表示你已阅读并同意' }}
          <NuxtLink class="apple-link" to="/terms">《用户协议》</NuxtLink>
          与
          <NuxtLink class="apple-link" to="/privacy-policy">《隐私政策》</NuxtLink>
        </p>
      </form>
    </div>
  </UCard>
</template>
