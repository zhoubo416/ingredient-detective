<script setup lang="ts">
definePageMeta({
  middleware: 'guest'
})

useSeoMeta({
  title: '登录',
  description: '登录配料侦探，使用 Google、Apple 或邮箱账号登录，即可享受 AI 智能食品成分分析服务。',
  ogTitle: '登录 · 配料侦探',
  ogDescription: '登录配料侦探，使用 Google、Apple 或邮箱账号登录，即可享受 AI 智能食品成分分析服务。'
})
</script>

<template>
  <UContainer class="py-16 sm:py-24">
    <div class="grid gap-10 lg:grid-cols-[0.9fr_1.1fr] lg:items-center">
      <div class="space-y-5">
        <span class="eyebrow">
          <UIcon name="i-lucide-badge-check" />
          用户认证
        </span>
        <h1 class="section-title">先登录，再调用食品配料识别与分析</h1>
        <p class="section-copy max-w-xl">
          登录之后，分析请求会以当前 Supabase 用户身份进入后端，结果同时写入数据库，供你在任何设备查看历史记录。
        </p>
      </div>

      <AuthCard />
    </div>
  </UContainer>
</template>
