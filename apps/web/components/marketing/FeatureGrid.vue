<script setup lang="ts">
const features = [
  {
    title: '登录后才能调用分析能力',
    description: '用 Supabase Auth 统一身份。匿名访客只能浏览官网，不能直接消耗 OCR 和 AI 资源。',
    icon: 'i-lucide-lock-keyhole'
  },
  {
    title: '识别与分析迁到后端',
    description: 'OCR 签名、DeepSeek 调用和结果存储都由 Nuxt server API 执行，敏感密钥不再暴露在客户端。',
    icon: 'i-lucide-server-cog'
  },
  {
    title: 'Supabase 承载用户与数据',
    description: '分析结果按用户入库，支持 RLS，天然适合后续扩展为多端共用历史记录。',
    icon: 'i-lucide-database-zap'
  },
  {
    title: '官网和产品后台一体化',
    description: '营销首页、登录入口、用户后台和 API 在一个 Nuxt 工程里完成，减少部署和维护分裂。',
    icon: 'i-lucide-layout-dashboard'
  }
] as const
</script>

<template>
  <section class="pb-20">
    <UContainer class="space-y-10">
      <div class="max-w-3xl space-y-4">
        <span class="eyebrow">
          <UIcon name="i-lucide-sparkles" />
          产品能力
        </span>
        <h2 class="section-title text-4xl">你要加的三件事，现在在同一套架构里闭环</h2>
        <p class="section-copy">
          网站负责展示和承接流量，登录负责控制使用权限，后台负责真正执行识别与分析。
          这样 Flutter、Web 和未来的管理端都能共享同一套服务能力。
        </p>
      </div>

      <div class="grid gap-5 lg:grid-cols-2">
        <UCard
          v-for="feature in features"
          :key="feature.title"
          class="glass-panel rounded-[1.75rem]"
        >
          <template #header>
            <div class="flex items-center gap-4">
              <div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-emerald-700 text-xl text-white">
                <UIcon :name="feature.icon" />
              </div>
              <h3 class="text-xl font-semibold text-slate-900">{{ feature.title }}</h3>
            </div>
          </template>

          <p class="section-copy text-base">
            {{ feature.description }}
          </p>
        </UCard>
      </div>
    </UContainer>
  </section>
</template>
