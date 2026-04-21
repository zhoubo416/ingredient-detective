<script setup lang="ts">
useSeoMeta({
  title: 'AI智能分析食品成分安全与营养价值',
  description: '拍照看懂食品配料，快速获得健康评估、配料作用解释和个性化建议，并可持续查询历史记录。关注食品安全，守护全家健康。',
  ogTitle: '配料侦探 - AI智能分析食品成分安全与营养价值',
  ogDescription: '拍照识别食品配料表，AI智能分析营养价值和食品安全，获取个性化健康建议。支持历史记录检索和持续复盘。'
})

useHead({
  script: [{
    type: 'application/ld+json',
    innerHTML: JSON.stringify({
      '@context': 'https://schema.org',
      '@type': 'WebApplication',
      name: '配料侦探',
      description: 'AI智能分析食品成分安全与营养价值，通过拍照识别配料表，快速获得专业的健康评分和个性化建议。',
      url: 'https://ingredient-detective.com',
      applicationCategory: 'HealthApplication',
      operatingSystem: 'Web',
      offers: {
        '@type': 'Offer',
        price: '0',
        priceCurrency: 'CNY'
      },
      aggregateRating: {
        '@type': 'AggregateRating',
        ratingValue: '4.8',
        ratingCount: '1024'
      }
    })
  }]
})
</script>

<template>
  <div>
    <MarketingHeroSection />
    <MarketingFeatureGrid />
    <MarketingShowcaseSection />
    <MarketingVoicesSection />

    <section class="pb-24">
      <UContainer>
        <div class="grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
          <div class="glass-panel reveal-up rounded-[1.8rem] p-8 lg:p-10">
            <span class="eyebrow">
              <UIcon name="i-lucide-sparkles" />
              产品亮点
            </span>
            <h2 class="section-title mt-4 text-4xl">一次分析，不止告诉你"有什么"，还告诉你"意味着什么"</h2>
            <div class="mt-6 grid gap-4 sm:grid-cols-2">
              <div class="scenario-card p-5">
                <p class="text-sm font-medium text-slate-500">识别速度</p>
                <p class="mt-3 text-lg font-semibold text-slate-900">几秒内拿到首屏结论</p>
              </div>
              <div class="scenario-card p-5">
                <p class="text-sm font-medium text-slate-500">内容深度</p>
                <p class="mt-3 text-lg font-semibold text-slate-900">逐项解释配料作用与风险</p>
              </div>
              <div class="scenario-card p-5">
                <p class="text-sm font-medium text-slate-500">个性化提醒</p>
                <p class="mt-3 text-lg font-semibold text-slate-900">结合你的健康情况给出建议</p>
              </div>
              <div class="scenario-card p-5">
                <p class="text-sm font-medium text-slate-500">长期价值</p>
                <p class="mt-3 text-lg font-semibold text-slate-900">历史记录可检索、可持续复盘</p>
              </div>
            </div>
          </div>

          <div class="story-panel reveal-up delay-1 p-8 lg:p-10">
            <span class="eyebrow bg-white/10 text-white">
              <UIcon name="i-lucide-badge-check" />
              适合宣传转化
            </span>
            <h2 class="section-title mt-4 text-4xl text-white">把"看不懂配料表"变成一个能持续使用的产品体验</h2>
            <p class="section-copy mt-3">
              用户第一次因为好奇而上传，第二次会因为历史记录和个性化提醒继续回来。
              这比单纯做一个 OCR 工具更有产品价值。
            </p>
            <div class="mt-6 grid gap-3">
              <div class="trust-badge text-sm text-slate-100">
                1. 拍照上传配料表
              </div>
              <div class="trust-badge text-sm text-slate-100">
                2. 获得健康判断与配料解释
              </div>
              <div class="trust-badge text-sm text-slate-100">
                3. 在历史页持续追踪和对比
              </div>
            </div>
            <div class="mt-6 flex flex-wrap gap-3 justify-end">
              <UButton to="/login" color="primary" size="lg" trailing-icon="i-lucide-arrow-right">
                立即体验产品
              </UButton>
              <UButton to="/dashboard" color="success" size="lg">
                进入分析台
              </UButton>
            </div>
          </div>
        </div>
      </UContainer>
    </section>
  </div>
</template>
