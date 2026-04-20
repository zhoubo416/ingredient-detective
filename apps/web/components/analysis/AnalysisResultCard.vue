<script setup lang="ts">
import type { FoodAnalysisResult } from '~/shared/analysis'
import { getScoreTone } from '~/shared/analysis'
import { marked } from 'marked'

const props = defineProps<{
  result: FoodAnalysisResult | null
  analyzing?: boolean
}>()

const scoreTone = computed(() => getScoreTone(props.result?.healthScore ?? 0))
const isEmpty = computed(() => props.result === null && !props.analyzing)
const isAnalyzing = computed(() => props.analyzing && props.result !== null)

const renderedMarkdown = computed(() => {
  if (!props.result?.rawMarkdown) return ''
  return marked.parse(props.result.rawMarkdown)
})
</script>

<template>
  <div class="space-y-3">
    <!-- Empty State -->
    <div v-if="isEmpty" class="rounded-2xl border border-dashed border-slate-300 bg-slate-50/50 p-8 text-center h-full">
      <UIcon name="i-lucide-clipboard-list" class="mx-auto text-4xl text-slate-400" />
      <p class="mt-3 text-sm text-slate-500">暂无分析结果</p>
      <p class="mt-1 text-xs text-slate-400">上传食品配料开始分析</p>
    </div>

    <!-- Analyzing State -->
    <div v-else-if="isAnalyzing" class="rounded-2xl border border-dashed border-emerald-300 bg-emerald-50/50 p-8 text-center">
      <div class="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-emerald-100">
        <UIcon name="i-lucide-loader-2" class="text-3xl text-emerald-600 animate-spin" />
      </div>
      <p class="mt-4 text-base font-semibold text-slate-900">正在分析中…</p>
      <p class="mt-2 text-sm text-slate-500">系统正在进行 OCR 识别与 AI 分析</p>
      <p class="mt-1 text-xs text-slate-400">预计需要 10-30 秒，请稍候</p>
      <div class="mx-auto mt-5 h-1.5 w-48 overflow-hidden rounded-full bg-slate-200">
        <div class="h-full w-1/3 animate-pulse rounded-full bg-emerald-500"></div>
      </div>
    </div>

    <!-- Has Result -->
    <template v-else>
      <!-- Hero: food name + chips + score -->
      <div class="rounded-2xl bg-gradient-to-br from-[#f3fbf4] to-[#e7f4e9] border border-[#d9e8db] p-4">
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0 flex-1">
            <div class="flex items-center gap-2">
              <h2 class="text-xl font-bold text-slate-900 truncate">{{ result?.foodName || '待分析' }}</h2>
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
                {{ result?.compliance.status || '待分析' }}
              </span>
              <span class="inline-flex items-center gap-1 rounded-full bg-indigo-50 px-2.5 py-1 text-xs font-semibold text-indigo-600">
                <UIcon name="i-lucide-factory" class="size-3" />
                加工 {{ result?.processing.level || '待分析' }}
              </span>
            </div>
          </div>
          <div
            class="flex shrink-0 flex-col items-center justify-center w-14 h-14 rounded-2xl border"
            :style="{ backgroundColor: scoreTone.softHex, borderColor: scoreTone.borderHex }"
          >
            <span class="text-xl font-extrabold leading-none" :style="{ color: scoreTone.hex }">
              {{ (result?.healthScore ?? 0).toFixed(1) }}
            </span>
            <span class="text-[10px]" :style="{ color: scoreTone.hex + '99' }">/ 10</span>
          </div>
        </div>

        <p class="mt-2.5 text-[13px] leading-relaxed text-slate-600">
          {{ result?.overallAssessment || '分析中...' }}
        </p>

        <!-- Warning / recommendations -->
        <div v-if="result?.recommendations" class="mt-2.5 flex gap-1.5 rounded-xl bg-amber-50/70 px-3 py-2">
          <UIcon name="i-lucide-triangle-alert" class="mt-0.5 size-3.5 shrink-0 text-amber-600" />
          <p class="text-xs leading-relaxed text-amber-800">{{ result.recommendations }}</p>
        </div>
      </div>

      <!-- Ingredients Raw Markdown -->
      <div class="rounded-2xl border border-[#dee9e0] bg-white p-3.5">
        <div class="flex items-center justify-between mb-3">
          <h3 class="text-base font-bold text-slate-900">配料分析</h3>
          <span class="text-xs text-slate-500">{{ result?.rawMarkdown ? '详细' : '加载中' }}</span>
        </div>

        <div v-if="result?.rawMarkdown" class="max-h-[400px] overflow-y-auto rounded-xl border border-slate-200 bg-slate-50/50 px-4 py-3">
          <div class="markdown-body" v-html="renderedMarkdown" />
        </div>
        <div v-else class="rounded-xl border border-dashed border-slate-300 bg-amber-50/50 px-4 py-6 text-sm text-slate-600">
          <p>详细配料分析生成中，请稍候...</p>
          <div class="mt-2 h-1 w-full overflow-hidden rounded-full bg-slate-200">
            <div class="h-full w-1/3 animate-pulse bg-amber-400"></div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
