<script setup lang="ts">
const painPoints = [
  {
    label: '看不懂配料'
  },
  {
    label: '不知道该不该买'
  },
  {
    label: '担心糖、盐、添加剂'
  }
] as const
</script>

<template>
  <section class="brand-hero py-16 sm:py-24">
    <UContainer>
      <div class="hero-shell grid gap-10 p-8 lg:grid-cols-[1.05fr_0.95fr] lg:p-10">
        <div class="space-y-6 reveal-up">
          <span class="eyebrow">
            <UIcon name="i-lucide-leaf" />
            AI 配料分析产品
          </span>

          <div class="space-y-4">
            <h1 class="section-title max-w-4xl">
              拍一张配料表，
              <span class="gradient-title">立刻知道这东西适不适合你吃</span>
            </h1>
            <p class="section-copy max-w-2xl">
              配料侦探把 OCR、配料解析、健康判断和历史追踪整合在一个产品里。
              用户上传食品包装图后，几秒内就能得到可执行的购买建议，而不是一堆看不懂的术语。
            </p>
          </div>

          <div class="flex flex-wrap gap-3">
            <UButton to="/login" size="xl" color="primary" trailing-icon="i-lucide-arrow-right">
              立即上传配料表
            </UButton>
            <UButton to="/dashboard/history" size="xl" variant="soft" color="neutral">
              查看历史记录
            </UButton>
          </div>

          <div class="flex flex-wrap gap-2 pt-1">
            <span
              v-for="item in painPoints"
              :key="item.label"
              class="promo-chip"
            >
              {{ item.label }}
            </span>
          </div>

          <div class="grid gap-3 sm:grid-cols-3">
            <div class="hero-stat">
              <strong>2-5 秒</strong>
              <p class="text-xs text-slate-500">快速返回首屏结论</p>
            </div>
            <div class="hero-stat">
              <strong>逐项解释</strong>
              <p class="text-xs text-slate-500">每个配料的作用都说清楚</p>
            </div>
            <div class="hero-stat">
              <strong>长期追踪</strong>
              <p class="text-xs text-slate-500">自动归档，支持历史复盘</p>
            </div>
          </div>
        </div>

        <div class="demo-card reveal-up delay-1 p-5 sm:p-6">
          <div class="flex items-center justify-between">
            <p class="text-xs font-semibold uppercase tracking-[0.14em] text-emerald-700">Analysis Preview</p>
            <UBadge color="success" variant="soft">实时示例</UBadge>
          </div>

          <div class="demo-score mt-5 p-5">
            <p class="text-xs uppercase tracking-[0.16em] text-emerald-50/80">健康评分</p>
            <p class="mt-3 text-5xl font-semibold">5.0</p>
            <p class="mt-3 text-lg font-semibold">风味酸乳</p>
            <p class="mt-2 text-sm leading-6 text-emerald-50/85">
              含糖和多种添加剂，适合作为偶尔零食，不建议高频饮用。
            </p>
          </div>

          <div class="mt-4 grid gap-3">
            <div class="rounded-2xl bg-emerald-50/70 p-4">
              <p class="text-sm font-semibold text-slate-900">白砂糖</p>
              <p class="mt-1 text-sm leading-6 text-slate-600">提升口感，但会明显抬高糖负担，控糖人群要谨慎。</p>
            </div>
            <div class="rounded-2xl bg-white p-4 ring-1 ring-slate-900/5">
              <p class="text-sm font-semibold text-slate-900">果胶</p>
              <p class="mt-1 text-sm leading-6 text-slate-600">用于稳定质地，本身风险较低，主要反映产品加工属性。</p>
            </div>
            <div class="rounded-2xl bg-amber-50/70 p-4">
              <p class="text-sm font-semibold text-slate-900">个性化提醒</p>
              <p class="mt-1 text-sm leading-6 text-slate-600">如果你有控糖需求或正在减脂，这类产品不适合日常高频摄入。</p>
            </div>
          </div>
        </div>
      </div>
    </UContainer>
  </section>
</template>
