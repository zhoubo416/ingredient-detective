<script setup lang="ts">
const route = useRoute()
const { signIn, signUp } = useAuthActions()
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

async function handleSubmit() {
  pending.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    if (isSignUp.value) {
      const data = await signUp(email.value, password.value)

      if (data.session) {
        window.location.href = '/dashboard/history'
        return
      }

      successMessage.value = getSignUpSuccessMessage(Boolean(data.session))
    } else {
      await signIn(email.value, password.value)
      const target = (route.query.redirect as string) || '/dashboard/history'
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
