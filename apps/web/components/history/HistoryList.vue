<script setup lang="ts">
import type { AnalysisHistoryItem } from '~/shared/analysis'

defineProps<{
  items: AnalysisHistoryItem[]
  compact?: boolean
  selectedId?: string
}>()

defineEmits<{
  select: [item: AnalysisHistoryItem]
  remove: [id: string]
}>()

function formatDate(value: string) {
  return new Intl.DateTimeFormat('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  }).format(new Date(value))
}

function scoreColor(score: number) {
  if (score >= 7.5) return 'success'
  if (score >= 5.5) return 'warning'
  return 'error'
}
</script>

<template>
  <div class="space-y-4">
    <div
      v-for="item in items"
      :key="item.id"
      class="glass-panel reveal-up rounded-[1.5rem] p-5 transition"
      :class="selectedId === item.id ? 'ring-2 ring-emerald-500/50' : 'hover:-translate-y-0.5'"
    >
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div class="space-y-3">
          <div class="flex flex-wrap items-center gap-2">
            <UBadge color="neutral" variant="soft">{{ item.sourceType === 'image' ? '图片识别' : '手动输入' }}</UBadge>
            <UBadge :color="scoreColor(item.healthScore)" variant="soft">
              {{ item.healthScore.toFixed(1) }} 分
            </UBadge>
          </div>
          <div>
            <h3 class="text-xl font-semibold text-slate-900">{{ item.foodName }}</h3>
            <p class="mt-1 text-sm text-slate-500">{{ formatDate(item.createdAt) }}</p>
          </div>
          <div class="rounded-xl bg-slate-900/5 px-3 py-2">
            <p class="line-clamp-2 text-sm leading-6 text-slate-600">
              {{ item.result.overallAssessment }}
            </p>
          </div>
          <p class="line-clamp-1 text-sm text-slate-500">
            配料：{{ item.ingredientLines.join('、') || '暂无' }}
          </p>
        </div>

        <div class="flex shrink-0 gap-2">
          <UButton color="primary" variant="soft" @click="$emit('select', item)">查看详情</UButton>
          <UButton color="error" variant="soft" @click="$emit('remove', item.id)">删除</UButton>
        </div>
      </div>
    </div>

    <div
      v-if="items.length === 0"
      class="rounded-[1.5rem] border border-dashed border-slate-300 bg-white/70 px-6 py-10 text-sm text-slate-500"
    >
      暂无历史记录。创建一次分析后，这里会自动出现。
    </div>
  </div>
</template>
