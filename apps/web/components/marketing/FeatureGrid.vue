<script setup lang="ts">
const scenarios = [
  {
    title: '控糖或减脂人群',
    description: '一眼识别高糖、高能量、风味型乳制品等“看起来健康”的陷阱。',
    icon: 'i-lucide-activity'
  },
  {
    title: '有孩子的家庭',
    description: '买零食、酸奶、早餐食品时，快速判断配料是否复杂、是否含过多添加剂。',
    icon: 'i-lucide-baby'
  },
  {
    title: '慢病和饮食管理',
    description: '对高盐、高糖、重加工食品更敏感，能结合个人情况给出更谨慎的提醒。',
    icon: 'i-lucide-heart-pulse'
  },
  {
    title: '长期记录与复盘',
    description: '把每次分析自动沉淀为历史记录，对比同类产品，建立自己的饮食判断标准。',
    icon: 'i-lucide-history'
  }
] as const

const trustPoints = [
  {
    title: '不是只识别文字',
    description: '重点不在 OCR 本身，而在“识别之后能给你什么判断”。'
  },
  {
    title: '逐项解释配料作用',
    description: '每个配料都给出作用和影响，不再只是简单罗列名称。'
  },
  {
    title: '支持历史追踪',
    description: '同一账号下自动留存记录，方便长期比较和复盘。'
  }
] as const
</script>

<template>
  <section class="pb-20">
    <UContainer class="space-y-10">
      <div class="mx-auto max-w-3xl space-y-4 text-center reveal-up">
        <span class="eyebrow">
          <UIcon name="i-lucide-users" />
          产品价值
        </span>
        <h2 class="section-title text-4xl">不是给专业人士看的工具，而是给真实消费者的决策助手</h2>
        <p class="section-copy">
          你不需要懂食品工程，也不需要逐条查配料。拍照后就能知道风险点、加工度和是否适合自己。
        </p>
      </div>

      <div class="grid gap-5 md:grid-cols-2">
        <UCard
          v-for="scenario in scenarios"
          :key="scenario.title"
          class="feature-card reveal-up"
        >
          <template #header>
            <div class="flex items-center gap-4">
              <div class="feature-icon text-xl">
                <UIcon :name="scenario.icon" />
              </div>
              <h3 class="text-xl font-semibold text-slate-900">{{ scenario.title }}</h3>
            </div>
          </template>

          <p class="section-copy text-base">
            {{ scenario.description }}
          </p>
        </UCard>
      </div>

      <div class="highlight-panel reveal-up p-6 sm:p-8">
        <div class="max-w-2xl">
          <span class="eyebrow">
            <UIcon name="i-lucide-shield-check" />
            为什么更可信
          </span>
          <h3 class="mt-4 text-3xl font-semibold text-slate-900">用户真正需要的不是配料表翻译，而是购买建议</h3>
        </div>

        <div class="trust-grid mt-6">
          <div
            v-for="point in trustPoints"
            :key="point.title"
            class="scenario-card p-5"
          >
            <p class="text-lg font-semibold text-slate-900">{{ point.title }}</p>
            <p class="mt-2 text-sm leading-6 text-slate-600">{{ point.description }}</p>
          </div>
        </div>
      </div>
    </UContainer>
  </section>
</template>
