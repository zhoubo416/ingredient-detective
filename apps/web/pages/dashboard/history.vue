<script setup lang="ts">
import type { AnalysisHistoryItem } from '~/shared/analysis'

definePageMeta({
  middleware: 'auth'
})

useSeoMeta({
  title: '历史记录 · 配料侦探'
})

const items = ref<AnalysisHistoryItem[]>([])
const selected = ref<AnalysisHistoryItem | null>(null)
const query = ref('')
const loading = ref(true)

const filteredItems = computed(() => {
  const keyword = query.value.trim().toLowerCase()
  if (!keyword) {
    return items.value
  }

  return items.value.filter(item => {
    const nameHit = item.foodName.toLowerCase().includes(keyword)
    const ingredientHit = item.ingredientLines.some(line => line.toLowerCase().includes(keyword))
    const assessmentHit = item.result.overallAssessment.toLowerCase().includes(keyword)
    return nameHit || ingredientHit || assessmentHit
  })
})

const averageScore = computed(() => {
  if (filteredItems.value.length === 0) return 0
  const total = filteredItems.value.reduce((sum, item) => sum + item.healthScore, 0)
  return Number((total / filteredItems.value.length).toFixed(1))
})

watch(filteredItems, (list) => {
  if (list.length === 0) {
    selected.value = null
    return
  }

  if (!selected.value || !list.some(item => item.id === selected.value?.id)) {
    selected.value = list[0] ?? null
  }
})

async function loadHistory() {
  loading.value = true

  try {
    const response = await $fetch<{ items: AnalysisHistoryItem[] }>('/api/history', {
      query: { limit: 30 }
    })

    items.value = response.items
    selected.value = response.items[0] ?? null
  } finally {
    loading.value = false
  }
}

async function handleRemove(id: string) {
  await $fetch(`/api/history/${id}`, {
    method: 'DELETE'
  })

  items.value = items.value.filter(item => item.id !== id)
  if (selected.value?.id === id) {
    selected.value = items.value[0] ?? null
  }
}

onMounted(loadHistory)
</script>

<template>
  <UContainer class="space-y-8 py-12">
    <div class="glass-panel reveal-up rounded-[2rem] p-8">
      <div class="flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <span class="eyebrow">
            <UIcon name="i-lucide-history" />
            历史查询
          </span>
          <h1 class="mt-4 text-4xl font-semibold text-slate-900">历史记录中心</h1>
          <p class="mt-3 max-w-3xl text-sm leading-7 text-slate-600">
            输入食品名或配料关键词，快速回看过往结果。点击左侧条目即可在右侧查看详细分析。
          </p>
        </div>

        <div class="grid gap-3 sm:grid-cols-2">
          <div class="metric-card min-w-[140px]">
            <strong>{{ filteredItems.length }}</strong>
            <p class="text-xs text-slate-500">当前匹配记录</p>
          </div>
          <div class="metric-card min-w-[140px]">
            <strong>{{ averageScore || '--' }}</strong>
            <p class="text-xs text-slate-500">匹配记录均分</p>
          </div>
        </div>
      </div>
    </div>

    <div class="glass-panel reveal-up delay-1 rounded-[1.5rem] p-5">
      <div class="flex flex-col gap-3 lg:flex-row lg:items-center">
        <UInput
          v-model="query"
          icon="i-lucide-search"
          size="xl"
          class="w-full"
          placeholder="搜索：食品名 / 配料关键词 / 结论关键词"
        />
        <UButton color="neutral" variant="soft" icon="i-lucide-rotate-ccw" @click="loadHistory">
          刷新
        </UButton>
      </div>
      <div class="mt-3 flex flex-wrap gap-2 text-xs text-slate-500">
        <span class="promo-chip">支持食品名关键词</span>
        <span class="promo-chip">支持配料关键词</span>
        <span class="promo-chip">支持结论关键词</span>
      </div>
    </div>

    <div class="grid gap-6 xl:grid-cols-[0.95fr_1.05fr]">
      <section class="space-y-4 reveal-up delay-1">
        <div class="flex items-center justify-between">
          <h2 class="text-2xl font-semibold text-slate-900">查询结果</h2>
          <span class="text-sm text-slate-500">{{ filteredItems.length }} 条</span>
        </div>

        <div v-if="loading" class="rounded-[1.5rem] bg-white/80 px-6 py-10 text-sm text-slate-500">
          正在加载…
        </div>

        <HistoryList
          v-else
          :items="filteredItems"
          :selected-id="selected?.id ?? ''"
          @select="selected = $event"
          @remove="handleRemove"
        />
      </section>

      <AnalysisResultCard :result="selected?.result ?? null" />
    </div>
  </UContainer>
</template>
