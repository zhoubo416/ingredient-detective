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
    <header class="site-header">
      <UContainer class="flex items-center justify-between gap-4 py-3">
        <NuxtLink class="flex items-center gap-3" to="/">
          <div class="brand-badge">
            配
          </div>
          <div class="space-y-0.5">
            <p class="text-[11px] font-medium tracking-[0.08em] text-slate-500">Ingredient Detective</p>
            <p class="text-sm font-semibold text-slate-900">配料侦探</p>
          </div>
        </NuxtLink>

        <nav class="flex items-center gap-1 rounded-full border border-black/10 bg-white/85 p-1">
          <UButton to="/" variant="ghost" color="neutral" class="nav-pill">产品首页</UButton>
          <UButton v-if="user" to="/dashboard" variant="ghost" color="neutral" class="nav-pill">分析台</UButton>
          <UButton v-if="user" to="/dashboard/history" variant="ghost" color="neutral" class="nav-pill">历史记录</UButton>
          <UButton v-if="!user" to="/login" color="primary" class="rounded-full px-4">登录</UButton>
          <UButton
            v-else
            :loading="isSigningOut"
            color="neutral"
            variant="soft"
            class="rounded-full px-4"
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

    <footer class="mt-16 border-t border-slate-200 bg-[#f7faf7]">
      <UContainer class="flex flex-col gap-4 py-7 text-sm text-slate-500">
        <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <p>配料侦探 · 拍照看懂配料表，快速获得健康建议。</p>
          <div class="flex items-center gap-2 text-xs">
            <span class="promo-chip">Nuxt</span>
            <span class="promo-chip">Supabase</span>
            <span class="promo-chip">OCR + AI</span>
          </div>
        </div>

        <div class="flex flex-wrap items-center gap-x-4 gap-y-2 text-sm">
          <NuxtLink class="apple-link" to="/privacy-policy">隐私政策</NuxtLink>
          <NuxtLink class="apple-link" to="/terms">用户协议</NuxtLink>
          <NuxtLink class="apple-link" to="/compliance">备案与合规说明</NuxtLink>
          <span class="text-slate-400">备案准备中，备案完成后将展示 ICP/公安备案信息</span>
        </div>
      </UContainer>
    </footer>
  </div>
</template>
