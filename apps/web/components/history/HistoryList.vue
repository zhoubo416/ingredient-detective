<script setup lang="ts">
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

interface ParsedIngredient {
  name: string
  function: string
  safety: string
  reminder: string
}

const expandedId = ref<string | null>(null)

function toggleExpand(id: string) {
  expandedId.value = expandedId.value === id ? null : id
}

function parseIngredients(md: string | undefined): ParsedIngredient[] {
  if (!md) return []
  
  const ingredients: ParsedIngredient[] = []
  const blocks = md.split(/\n(?=##)/)
  
  for (const block of blocks) {
    const lines = block.split('\n').filter(l => l.trim())
    if (lines.length === 0) continue
    
    const nameLine = lines[0]?.replace(/^##\s+/, '').trim()
    if (!nameLine) continue
    
    let functionText = ''
    let safetyText = ''
    let reminderText = ''
    
    for (const line of lines.slice(1)) {
      if (line.startsWith('- 作用:')) {
        functionText = line.replace(/^-\s+作用:\s*/, '').trim()
      } else if (line.startsWith('- 安全:')) {
        safetyText = line.replace(/^-\s+安全:\s*/, '').trim()
      } else if (line.startsWith('- 提醒:')) {
        reminderText = line.replace(/^-\s+提醒:\s*/, '').trim()
      }
    }
    
    ingredients.push({
      name: nameLine,
      function: functionText,
      safety: safetyText,
      reminder: reminderText
    })
  }
  
  return ingredients
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

      <!-- Expanded ingredients list -->
      <div v-if="item.result.rawMarkdown && expandedId === item.id" class="mt-3 space-y-2 max-h-[600px] overflow-y-auto">
        <div
          v-for="(ingredient, idx) in parseIngredients(item.result.rawMarkdown)"
          :key="idx"
          class="rounded-lg border border-slate-200 bg-gradient-to-br from-slate-50 to-white p-2.5 transition-all hover:border-slate-300 hover:shadow-sm"
        >
          <!-- Header: name + safety indicator -->
          <div class="flex items-start justify-between gap-2 mb-2">
            <h5 class="text-xs font-semibold text-slate-900 flex-1 leading-snug">{{ ingredient.name }}</h5>
            <div class="shrink-0 flex items-center gap-1">
              <span v-if="ingredient.safety.includes('合规')" class="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-full bg-emerald-50 text-emerald-700 font-medium text-[10px]">
                <UIcon name="i-lucide-check-circle" class="size-2.5" />
                合规
              </span>
              <span v-else-if="ingredient.safety.includes('⚠️')" class="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-full bg-amber-50 text-amber-700 font-medium text-[10px]">
                <UIcon name="i-lucide-alert-circle" class="size-2.5" />
                注意
              </span>
            </div>
          </div>
          
          <!-- Details -->
          <div class="space-y-1 text-[11px] text-slate-600">
            <div class="flex gap-1.5">
              <span class="shrink-0 font-semibold text-slate-700 w-10">作用：</span>
              <span class="flex-1 leading-relaxed">{{ ingredient.function || '—' }}</span>
            </div>
            <div class="flex gap-1.5">
              <span class="shrink-0 font-semibold text-slate-700 w-10">安全：</span>
              <span class="flex-1 leading-relaxed line-clamp-1">{{ ingredient.safety || '—' }}</span>
            </div>
            <div v-if="ingredient.reminder && ingredient.reminder !== '无特别提醒'" class="flex gap-1.5 pt-0.5">
              <span class="shrink-0 font-semibold text-amber-700 w-14">⚠️ 提醒：</span>
              <span class="flex-1 leading-relaxed text-amber-700">{{ ingredient.reminder }}</span>
            </div>
          </div>
        </div>
      </div>
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
/* Scrollbar styling for ingredient list */
.space-y-2::-webkit-scrollbar {
  width: 6px;
}

.space-y-2::-webkit-scrollbar-track {
  background: transparent;
}

.space-y-2::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 3px;
}

.space-y-2::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}
</style>
