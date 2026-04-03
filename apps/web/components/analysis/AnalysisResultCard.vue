<script setup lang="ts">
import { marked } from 'marked'
import type { FoodAnalysisResult } from '~/shared/analysis'
import { getScoreTone } from '~/shared/analysis'

const props = defineProps<{
  result: FoodAnalysisResult | null
}>()

const demoResult: FoodAnalysisResult = {
  foodName: '风味酸乳',
  ingredients: [],
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
  <div class="space-y-3">
    <!-- Hero: food name + chips + score -->
    <div class="rounded-2xl bg-gradient-to-br from-[#f3fbf4] to-[#e7f4e9] border border-[#d9e8db] p-4">
      <div class="flex items-start justify-between gap-3">
        <div class="min-w-0 flex-1">
          <div class="flex items-center gap-2">
            <h2 class="text-xl font-bold text-slate-900 truncate">{{ activeResult.foodName }}</h2>
            <UBadge v-if="isDemo" color="neutral" variant="soft" size="sm">演示</UBadge>
          </div>
          <div class="mt-2 flex flex-wrap gap-1.5">
            <span
              class="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-semibold"
              :style="{ backgroundColor: scoreTone.softHex, color: scoreTone.hex }"
            >
              <UIcon name="i-lucide-heart" class="size-3" />
              {{ scoreTone.label }}
            </span>
            <span class="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700">
              <UIcon name="i-lucide-shield-check" class="size-3" />
              {{ activeResult.compliance.status || '待分析' }}
            </span>
            <span class="inline-flex items-center gap-1 rounded-full bg-indigo-50 px-2.5 py-1 text-xs font-semibold text-indigo-600">
              <UIcon name="i-lucide-factory" class="size-3" />
              加工 {{ activeResult.processing.level || '待分析' }}
            </span>
          </div>
        </div>
        <div
          class="flex shrink-0 flex-col items-center justify-center w-14 h-14 rounded-2xl border"
          :style="{ backgroundColor: scoreTone.softHex, borderColor: scoreTone.borderHex }"
        >
          <span class="text-xl font-extrabold leading-none" :style="{ color: scoreTone.hex }">
            {{ activeResult.healthScore.toFixed(1) }}
          </span>
          <span class="text-[10px]" :style="{ color: scoreTone.hex + '99' }">/ 10</span>
        </div>
      </div>

      <p class="mt-2.5 text-[13px] leading-relaxed text-slate-600">
        {{ activeResult.overallAssessment }}
      </p>

      <!-- Warning / recommendations -->
      <div v-if="activeResult.recommendations" class="mt-2.5 flex gap-1.5 rounded-xl bg-amber-50/70 px-3 py-2">
        <UIcon name="i-lucide-triangle-alert" class="mt-0.5 size-3.5 shrink-0 text-amber-600" />
        <p class="text-xs leading-relaxed text-amber-800">{{ activeResult.recommendations }}</p>
      </div>
    </div>

    <!-- Ingredients -->
    <div class="rounded-2xl border border-[#dee9e0] bg-white p-3.5">
      <div class="flex items-center justify-between mb-2.5">
        <h3 class="text-base font-bold text-slate-900">配料信息</h3>
        <span class="text-xs text-slate-500">{{ renderedMarkdown ? '已完成' : '加载中' }}</span>
      </div>

      <div v-if="renderedMarkdown" class="markdown-content" v-html="renderedMarkdown" />

      <div v-else-if="activeResult.ingredients.length === 0" class="rounded-xl border border-dashed border-slate-300 bg-amber-50/50 px-4 py-6 text-sm text-slate-600">
        <p>详细配料分析生成中，请稍候...</p>
        <div class="mt-2 h-1 w-full overflow-hidden rounded-full bg-slate-200">
          <div class="h-full w-1/3 animate-pulse bg-amber-400"></div>
        </div>
      </div>

      <div v-else class="grid gap-3">
        <div
          v-for="ingredient in activeResult.ingredients"
          :key="ingredient.ingredientName"
          class="rounded-xl border border-slate-900/5 bg-slate-50/80 p-4"
        >
          <div class="flex flex-col gap-1.5 sm:flex-row sm:items-center sm:justify-between">
            <h4 class="text-sm font-bold text-slate-900">{{ ingredient.ingredientName }}</h4>
            <div class="flex flex-wrap gap-1.5 text-xs">
              <UBadge color="neutral" variant="soft" size="sm">{{ ingredient.complianceStatus }}</UBadge>
              <UBadge color="warning" variant="soft" size="sm">{{ ingredient.processingLevel }}</UBadge>
            </div>
          </div>
          <div class="mt-2 grid gap-2 text-xs leading-relaxed text-slate-600 lg:grid-cols-3">
            <p><span class="font-semibold text-slate-800">作用：</span>{{ ingredient.function }}</p>
            <p><span class="font-semibold text-slate-800">营养：</span>{{ ingredient.nutritionalValue }}</p>
            <p><span class="font-semibold text-slate-800">备注：</span>{{ ingredient.remarks }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.markdown-content :deep(h2) {
  font-size: 0.875rem;
  font-weight: 600;
  color: #0f172a;
  margin-top: 0.625rem;
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
