<script setup lang="ts">
const personas = [
  {
    title: '控糖用户',
    summary: '不再只看“低脂”“高钙”这些包装文案，而是直接判断糖和添加剂负担。',
    badge: '饮食管理'
  },
  {
    title: '有孩子的家庭',
    summary: '买零食和早餐奶时，能更快过滤掉配料复杂、甜味过重的产品。',
    badge: '家庭决策'
  },
  {
    title: '注重复购的人',
    summary: '历史记录帮助对比同类商品，减少“每次都重新查一遍”的成本。',
    badge: '长期使用'
  }
] as const

const quotes = [
  {
    quote: '以前我只能拍照识别文字，现在终于能直接看到“适不适合我吃”。',
    author: '早期体验用户 A'
  },
  {
    quote: '历史记录很有用，买酸奶和零食的时候可以快速对比之前查过的产品。',
    author: '早期体验用户 B'
  },
  {
    quote: '这个产品真正有价值的地方，是把配料表变成了购买决策。',
    author: '产品观察反馈'
  }
] as const
</script>

<template>
  <section class="pb-24">
    <UContainer class="space-y-10">
      <div class="mx-auto max-w-3xl space-y-4 text-center reveal-up">
        <span class="eyebrow">
          <UIcon name="i-lucide-message-circle-heart" />
          用户场景
        </span>
        <h2 class="section-title text-4xl">当用户真的在买东西时，这个产品才有意义</h2>
        <p class="section-copy">
          最好的宣传不是抽象口号，而是让访问者一眼看懂“这在我的真实生活里有什么用”。
        </p>
      </div>

      <div class="grid gap-5 lg:grid-cols-3">
        <div
          v-for="persona in personas"
          :key="persona.title"
          class="scenario-card reveal-up p-6"
        >
          <span class="promo-chip">{{ persona.badge }}</span>
          <h3 class="mt-4 text-2xl font-semibold text-slate-900">{{ persona.title }}</h3>
          <p class="mt-3 text-sm leading-7 text-slate-600">{{ persona.summary }}</p>
        </div>
      </div>

      <div class="grid gap-5 lg:grid-cols-3">
        <div
          v-for="item in quotes"
          :key="item.author"
          class="highlight-panel reveal-up p-6"
        >
          <p class="text-lg leading-8 text-slate-900">“{{ item.quote }}”</p>
          <p class="mt-5 text-sm font-medium text-slate-500">{{ item.author }}</p>
        </div>
      </div>
    </UContainer>
  </section>
</template>
