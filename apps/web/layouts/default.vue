<script setup lang="ts">
const user = useSupabaseUser()
const { signOut } = useAuthActions()
const isSigningOut = ref(false)

async function handleSignOut() {
  isSigningOut.value = true

  try {
    await signOut()
    await navigateTo('/')
  } finally {
    isSigningOut.value = false
  }
}
</script>

<template>
  <div class="shell min-h-screen">
    <header class="border-b border-slate-900/5 bg-white/70 backdrop-blur-xl">
      <UContainer class="flex items-center justify-between gap-4 py-4">
        <NuxtLink class="flex items-center gap-3" to="/">
          <div class="flex h-11 w-11 items-center justify-center rounded-2xl bg-emerald-700 text-lg font-bold text-white shadow-lg shadow-emerald-900/20">
            配
          </div>
          <div>
            <p class="text-sm font-semibold uppercase tracking-[0.24em] text-emerald-700">Ingredient Detective</p>
            <p class="text-base font-semibold text-slate-900">配料侦探</p>
          </div>
        </NuxtLink>

        <nav class="flex items-center gap-2">
          <UButton to="/" variant="ghost" color="neutral">首页</UButton>
          <UButton v-if="user" to="/dashboard" variant="ghost" color="neutral">分析台</UButton>
          <UButton v-if="user" to="/dashboard/history" variant="ghost" color="neutral">历史</UButton>
          <UButton v-if="!user" to="/login" color="primary">登录</UButton>
          <UButton
            v-else
            :loading="isSigningOut"
            color="neutral"
            variant="soft"
            @click="handleSignOut"
          >
            退出登录
          </UButton>
        </nav>
      </UContainer>
    </header>

    <main>
      <slot />
    </main>

    <footer class="border-t border-slate-900/5 bg-white/60 backdrop-blur-xl">
      <UContainer class="flex flex-col gap-2 py-6 text-sm text-slate-600 sm:flex-row sm:items-center sm:justify-between">
        <p>配料侦探 · 登录后统一通过后端完成 OCR 与 AI 分析。</p>
        <p>Nuxt + Nuxt UI + Supabase</p>
      </UContainer>
    </footer>
  </div>
</template>
