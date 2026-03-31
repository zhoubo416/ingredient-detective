<script setup lang="ts">
import type { FoodAnalysisResult } from '~/shared/analysis'
import { getScoreTone } from '~/shared/analysis'

const props = defineProps<{
  result: FoodAnalysisResult | null
}>()

const scoreTone = computed(() => props.result ? getScoreTone(props.result.healthScore) : null)
</script>

<template>
  <UCard class="glass-panel rounded-[2rem]">
    <template #header>
      <div class="flex items-start justify-between gap-4">
        <div>
          <h2 class="text-2xl font-semibold text-slate-900">分析结果</h2>
          <p class="mt-2 text-sm leading-6 text-slate-600">
            这里展示最近一次分析或你从历史记录中选中的结果。
          </p>
        </div>
        <UBadge
          v-if="result && scoreTone"
          :color="scoreTone.color"
          variant="soft"
          size="lg"
        >
          {{ scoreTone.label }}
        </UBadge>
      </div>
    </template>

    <div v-if="!result" class="rounded-[1.5rem] border border-dashed border-slate-300 bg-white/70 px-6 py-10 text-sm text-slate-500">
      还没有结果。先在左侧提交一条配料图片或配料文本。
    </div>

    <div v-else class="space-y-6">
      <div class="grid gap-4 xl:grid-cols-[0.7fr_1.3fr]">
        <div class="rounded-[1.5rem] bg-emerald-950 px-6 py-8 text-white">
          <p class="text-sm uppercase tracking-[0.18em] text-emerald-200">Health Score</p>
          <p class="mt-4 text-6xl font-semibold">{{ result.healthScore.toFixed(1) }}</p>
          <p class="mt-4 text-lg font-semibold">{{ result.foodName }}</p>
          <p class="mt-2 text-sm leading-6 text-emerald-100/90">{{ result.overallAssessment }}</p>
        </div>

        <div class="grid gap-4 md:grid-cols-3">
          <div class="rounded-[1.5rem] bg-white/85 p-5">
            <p class="text-sm font-medium text-slate-500">合规性</p>
            <p class="mt-3 text-lg font-semibold text-slate-900">{{ result.compliance.status }}</p>
            <p class="mt-2 text-sm leading-6 text-slate-600">{{ result.compliance.description }}</p>
          </div>
          <div class="rounded-[1.5rem] bg-white/85 p-5">
            <p class="text-sm font-medium text-slate-500">加工度</p>
            <p class="mt-3 text-lg font-semibold text-slate-900">{{ result.processing.level }}</p>
            <p class="mt-2 text-sm leading-6 text-slate-600">{{ result.processing.description }}</p>
          </div>
          <div class="rounded-[1.5rem] bg-white/85 p-5">
            <p class="text-sm font-medium text-slate-500">宣称评估</p>
            <p class="mt-3 text-lg font-semibold text-slate-900">已完成</p>
            <p class="mt-2 text-sm leading-6 text-slate-600">{{ result.claims.assessment }}</p>
          </div>
        </div>
      </div>

      <div class="rounded-[1.5rem] bg-amber-50/90 p-5">
        <p class="text-sm font-medium text-amber-800">建议</p>
        <p class="mt-3 text-sm leading-7 text-slate-700">{{ result.recommendations }}</p>
      </div>

      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <h3 class="text-xl font-semibold text-slate-900">逐项配料分析</h3>
          <span class="text-sm text-slate-500">
            {{ result.ingredients.length > 0 ? result.ingredients.length : '加载中' }} 项
          </span>
        </div>

        <div v-if="result.ingredients.length === 0" class="rounded-[1.5rem] border border-dashed border-slate-300 bg-amber-50/50 px-6 py-8 text-sm text-slate-600">
          <p>详细配料分析生成中，请稍候...</p>
          <div class="mt-3 h-1 w-full overflow-hidden rounded-full bg-slate-200">
            <div class="h-full w-1/3 animate-pulse bg-amber-400"></div>
          </div>
        </div>

        <div v-else class="grid gap-4">
          <div
            v-for="ingredient in result.ingredients"
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
