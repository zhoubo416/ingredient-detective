<script setup lang="ts">
import { marked } from 'marked'
import type { AnalysisHistoryItem } from '~/shared/analysis'
import { getScoreTone } from '~/shared/analysis'

defineProps<{
  items: AnalysisHistoryItem[]
  compact?: boolean
  selectedId?: string
}>()

const emit = defineEmits<{
  select: [item: AnalysisHistoryItem]
  remove: [id: string]
}>()

const expandedId = ref<string | null>(null)

function toggleExpand(id: string) {
  expandedId.value = expandedId.value === id ? null : id
}

function renderMarkdown(md: string | undefined) {
  if (!md) return ''
  return marked.parse(md, { async: false }) as string
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  }).format(new Date(value))
}
</script>

<template>
  <div class="space-y-3">
    <div
      v-for="item in items"
      :key="item.id"
      class="glass-panel reveal-up rounded-2xl p-4 transition"
      :class="selectedId === item.id ? 'ring-2 ring-emerald-500/50' : 'hover:-translate-y-0.5'"
    >
      <!-- Header: name + score -->
      <div class="flex items-start justify-between gap-3">
        <div class="min-w-0 flex-1">
          <div class="flex items-center gap-2">
            <h3 class="text-lg font-bold text-slate-900 truncate">{{ item.foodName }}</h3>
            <UBadge color="neutral" variant="soft" size="sm">
              {{ item.sourceType === 'image' ? '图片' : '手动' }}
            </UBadge>
          </div>
          <div class="mt-1.5 flex flex-wrap items-center gap-1.5">
            <span
              class="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-semibold"
              :style="{
                backgroundColor: getScoreTone(item.healthScore).softHex,
                color: getScoreTone(item.healthScore).hex
              }"
            >
              {{ getScoreTone(item.healthScore).label }}
            </span>
            <span v-if="item.result.compliance?.status" class="inline-flex items-center rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-semibold text-emerald-700">
              {{ item.result.compliance.status }}
            </span>
            <span v-if="item.result.processing?.level" class="inline-flex items-center rounded-full bg-indigo-50 px-2 py-0.5 text-xs font-semibold text-indigo-600">
              加工 {{ item.result.processing.level }}
            </span>
            <span class="text-xs text-slate-400">{{ formatDate(item.createdAt) }}</span>
          </div>
        </div>
        <div
          class="flex shrink-0 flex-col items-center justify-center w-12 h-12 rounded-xl border"
          :style="{
            backgroundColor: getScoreTone(item.healthScore).softHex,
            borderColor: getScoreTone(item.healthScore).borderHex
          }"
        >
          <span class="text-lg font-extrabold leading-none" :style="{ color: getScoreTone(item.healthScore).hex }">
            {{ item.healthScore.toFixed(1) }}
          </span>
          <span class="text-[9px]" :style="{ color: getScoreTone(item.healthScore).hex + '99' }">/ 10</span>
        </div>
      </div>

      <!-- Assessment -->
      <p class="mt-2 line-clamp-2 text-[13px] leading-relaxed text-slate-600">
        {{ item.result.overallAssessment }}
      </p>

      <!-- Actions -->
      <div class="mt-2.5 flex items-center gap-2">
        <UButton v-if="item.result.rawMarkdown" size="sm" color="neutral" variant="soft" @click="toggleExpand(item.id)">
          {{ expandedId === item.id ? '收起' : '展开配料' }}
        </UButton>
        <UButton size="sm" color="error" variant="soft" @click="$emit('remove', item.id)">删除</UButton>
      </div>

      <!-- Expanded markdown -->
      <div
        v-if="item.result.rawMarkdown && expandedId === item.id"
        class="markdown-content mt-3 w-full rounded-xl border border-slate-200 bg-white/90 px-4 py-3"
        v-html="renderMarkdown(item.result.rawMarkdown)"
      />
    </div>

    <div
      v-if="items.length === 0"
      class="rounded-2xl border border-dashed border-slate-300 bg-white/70 px-6 py-10 text-sm text-slate-500"
    >
      暂无历史记录。创建一次分析后，这里会自动出现。
    </div>
  </div>
</template>

<style scoped>
.markdown-content :deep(h2) {
  font-size: 0.875rem;
  font-weight: 600;
  color: #0f172a;
  margin-top: 0.5rem;
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
  font-size: 0.75rem;
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
