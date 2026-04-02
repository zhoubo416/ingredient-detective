<script setup lang="ts">
import { marked } from 'marked'
import type { FoodAnalysisResult } from '~/shared/analysis'
import { getScoreTone } from '~/shared/analysis'

const props = defineProps<{
  result: FoodAnalysisResult | null
}>()

const demoResult: FoodAnalysisResult = {
  foodName: '风味酸乳',
  ingredients: [
    {
      ingredientName: '白砂糖',
      function: '提供甜味，改善入口口感。',
      nutritionalValue: '会提高糖摄入负担，长期高频摄入不利于控糖和体重管理。',
      complianceStatus: '常见配料',
      processingLevel: '中度加工',
      remarks: '如果你在控糖或减脂，建议降低这类产品的食用频率。',
      riskLevel: 'caution',
      riskReason: '属于常见配料，但糖负担较明显。',
      actionableAdvice: '控糖或减脂人群不建议高频摄入。',
      negativeImpact: '可能增加总糖摄入。',
      isAdditive: false
    },
    {
      ingredientName: '果胶',
      function: '稳定质地，使乳制品口感更均匀顺滑。',
      nutritionalValue: '本身营养贡献有限，主要体现为工艺用途。',
      complianceStatus: '常见添加剂',
      processingLevel: '中度加工',
      remarks: '通常风险不高，但说明产品存在一定加工处理。',
      riskLevel: 'additive',
      riskReason: '主要承担工艺稳定作用。',
      actionableAdvice: '',
      negativeImpact: '',
      isAdditive: true
    },
    {
      ingredientName: '食用香精',
      function: '增强风味，让口味更明显。',
      nutritionalValue: '不提供核心营养价值，更多是风味修饰。',
      complianceStatus: '需结合产品整体判断',
      processingLevel: '高度加工',
      remarks: '如果配料中风味修饰成分较多，通常不建议作为日常高频食品。',
      riskLevel: 'caution',
      riskReason: '风味修饰成分较强，提示产品加工属性更明显。',
      actionableAdvice: '优先比较配料更简单的同类产品。',
      negativeImpact: '可能增加对风味型加工食品的依赖。',
      isAdditive: true
    }
  ],
  healthScore: 5,
  compliance: {
    status: '合规',
    description: '配料及过敏原表达较清晰，未见明显违规表述。',
    issues: []
  },
  processing: {
    level: '较高',
    description: '含糖和多种风味、稳定类成分，整体更偏加工型乳制品。',
    score: 4
  },
  claims: {
    detectedClaims: ['风味酸乳'],
    supportedClaims: ['乳制品属性明确'],
    questionableClaims: [],
    assessment: '宣传信息较克制，重点仍应关注真实配料构成。'
  },
  overallAssessment: '这类产品可以偶尔饮用，但不适合作为日常高频乳制品替代纯酸奶。',
  recommendations: '如果你在控糖、减脂或关注儿童日常糖摄入，建议优先选择配料更简单、含糖更低的产品。',
  warnings: [
    '白砂糖会明显抬高糖负担，控糖人群不建议高频摄入。',
    '食用香精说明产品风味修饰较强，可优先比较配料更简单的同类产品。'
  ],
  analysisTime: new Date().toISOString()
}

const activeResult = computed(() => props.result ?? demoResult)
const scoreTone = computed(() => getScoreTone(activeResult.value.healthScore))
const isDemo = computed(() => !props.result)
const renderedMarkdown = computed(() => {
  const md = activeResult.value.rawMarkdown
  if (!md) return ''
  return marked.parse(md, { async: false }) as string
})
</script>

<template>
  <UCard class="glass-panel rounded-[2rem]">
    <template #header>
      <div class="flex items-start justify-between gap-4">
        <div>
          <h2 class="text-2xl font-semibold text-slate-900">分析结果</h2>
          <p class="mt-2 text-sm leading-6 text-slate-600">
            {{ isDemo ? '还没开始分析时，这里会先展示一份演示结果。' : '这里展示最近一次分析或你从历史记录中选中的结果。' }}
          </p>
        </div>
        <div class="flex items-center gap-2">
          <UBadge v-if="isDemo" color="neutral" variant="soft" size="lg">
            演示
          </UBadge>
          <UBadge
            :color="scoreTone.color"
            variant="soft"
            size="lg"
          >
          {{ scoreTone.label }}
          </UBadge>
        </div>
      </div>
    </template>

    <div class="space-y-6">
      <div class="grid gap-4 xl:grid-cols-[0.7fr_1.3fr]">
        <div class="rounded-[1.5rem] bg-emerald-950 px-6 py-8 text-white">
          <p class="text-sm uppercase tracking-[0.18em] text-emerald-200">Health Score</p>
          <p class="mt-4 text-6xl font-semibold">{{ activeResult.healthScore.toFixed(1) }}</p>
          <p class="mt-4 text-lg font-semibold">{{ activeResult.foodName }}</p>
          <p class="mt-2 text-sm leading-6 text-emerald-100/90">{{ activeResult.overallAssessment }}</p>
        </div>

        <div class="grid gap-4 md:grid-cols-3">
          <div class="rounded-[1.5rem] bg-white/85 p-5">
            <p class="text-sm font-medium text-slate-500">合规性</p>
            <p class="mt-3 text-lg font-semibold text-slate-900">{{ activeResult.compliance.status }}</p>
            <p class="mt-2 text-sm leading-6 text-slate-600">{{ activeResult.compliance.description }}</p>
          </div>
          <div class="rounded-[1.5rem] bg-white/85 p-5">
            <p class="text-sm font-medium text-slate-500">加工度</p>
            <p class="mt-3 text-lg font-semibold text-slate-900">{{ activeResult.processing.level }}</p>
            <p class="mt-2 text-sm leading-6 text-slate-600">{{ activeResult.processing.description }}</p>
          </div>
          <div class="rounded-[1.5rem] bg-white/85 p-5">
            <p class="text-sm font-medium text-slate-500">宣称评估</p>
            <p class="mt-3 text-lg font-semibold text-slate-900">已完成</p>
            <p class="mt-2 text-sm leading-6 text-slate-600">{{ activeResult.claims.assessment }}</p>
          </div>
        </div>
      </div>

      <div class="rounded-[1.5rem] bg-amber-50/90 p-5">
        <p class="text-sm font-medium text-amber-800">建议</p>
        <p class="mt-3 text-sm leading-7 text-slate-700">{{ activeResult.recommendations }}</p>
      </div>

      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <h3 class="text-xl font-semibold text-slate-900">逐项配料分析</h3>
          <span class="text-sm text-slate-500">
            {{ activeResult.ingredients.length > 0 ? activeResult.ingredients.length : '加载中' }} 项
          </span>
        </div>

        <div v-if="renderedMarkdown" class="markdown-content rounded-[1.5rem] border border-slate-900/5 bg-white/85 px-5 py-4" v-html="renderedMarkdown" />

        <div v-else-if="activeResult.ingredients.length === 0" class="rounded-[1.5rem] border border-dashed border-slate-300 bg-amber-50/50 px-6 py-8 text-sm text-slate-600">
          <p>详细配料分析生成中，请稍候...</p>
          <div class="mt-3 h-1 w-full overflow-hidden rounded-full bg-slate-200">
            <div class="h-full w-1/3 animate-pulse bg-amber-400"></div>
          </div>
        </div>

        <div v-else class="grid gap-4">
          <div
            v-for="ingredient in activeResult.ingredients"
            :key="ingredient.ingredientName"
            class="rounded-[1.5rem] border border-slate-900/5 bg-white/85 p-5"
          >
            <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
              <h4 class="text-lg font-semibold text-slate-900">{{ ingredient.ingredientName }}</h4>
              <div class="flex flex-wrap gap-2 text-xs">
                <UBadge color="neutral" variant="soft">{{ ingredient.complianceStatus }}</UBadge>
                <UBadge color="warning" variant="soft">{{ ingredient.processingLevel }}</UBadge>
              </div>
            </div>
            <div class="mt-4 grid gap-3 text-sm leading-6 text-slate-600 lg:grid-cols-3">
              <p><span class="font-semibold text-slate-800">作用：</span>{{ ingredient.function }}</p>
              <p><span class="font-semibold text-slate-800">营养：</span>{{ ingredient.nutritionalValue }}</p>
              <p><span class="font-semibold text-slate-800">备注：</span>{{ ingredient.remarks }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </UCard>
</template>

<style scoped>
.markdown-content :deep(h2) {
  font-size: 0.9375rem;
  font-weight: 600;
  color: #0f172a;
  margin-top: 0.75rem;
  margin-bottom: 0.125rem;
}

.markdown-content :deep(h2:first-child) {
  margin-top: 0;
}

.markdown-content :deep(ul) {
  list-style: none;
  padding-left: 0;
  margin: 0;
}

.markdown-content :deep(li) {
  font-size: 0.8125rem;
  line-height: 1.5;
  color: #475569;
}

.markdown-content :deep(p) {
  margin: 0;
}

.markdown-content :deep(strong) {
  color: #1e293b;
}
</style>
