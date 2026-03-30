<script setup lang="ts">
useSeoMeta({
  title: '配料侦探',
  description: '登录后上传食品包装图片，由后端完成 OCR 与 AI 分析，沉淀统一历史记录。'
})
</script>

<template>
  <div>
    <MarketingHeroSection />
    <MarketingFeatureGrid />

    <section class="pb-24">
      <UContainer>
        <div class="glass-panel grid gap-10 rounded-[2rem] p-8 lg:grid-cols-[0.9fr_1.1fr] lg:p-10">
          <div class="space-y-4">
            <span class="eyebrow">
              <UIcon name="i-lucide-rocket" />
              第一版交付
            </span>
            <h2 class="section-title text-4xl">官网、登录、后台分析、历史记录已经拆成标准 Web 架构</h2>
            <p class="section-copy">
              这套 Nuxt 工程已经把用户系统、后端 API、宣传页面和分析工作台放在同一个应用中。
              下一步只需要让 Flutter 改为调用这套 API，就能正式完成前后端分离。
            </p>
          </div>

          <div class="grid gap-4 sm:grid-cols-2">
            <div class="rounded-[1.75rem] bg-white/85 p-6">
              <p class="text-sm font-medium text-slate-500">后端职责</p>
              <p class="mt-3 text-lg font-semibold text-slate-900">接收图片、做 OCR、调用 DeepSeek、写入 Supabase</p>
            </div>
            <div class="rounded-[1.75rem] bg-white/85 p-6">
              <p class="text-sm font-medium text-slate-500">网站职责</p>
              <p class="mt-3 text-lg font-semibold text-slate-900">展示产品价值、完成注册登录、承接真实用户使用</p>
            </div>
            <div class="rounded-[1.75rem] bg-white/85 p-6">
              <p class="text-sm font-medium text-slate-500">登录限制</p>
              <p class="mt-3 text-lg font-semibold text-slate-900">游客只能看宣传页，分析 API 必须有 Supabase 身份</p>
            </div>
            <div class="rounded-[1.75rem] bg-white/85 p-6">
              <p class="text-sm font-medium text-slate-500">数据沉淀</p>
              <p class="mt-3 text-lg font-semibold text-slate-900">历史按用户绑定，可供网站和 Flutter 共用</p>
            </div>
          </div>
        </div>
      </UContainer>
    </section>
  </div>
</template>
