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
const loading = ref(true)

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
    <div class="glass-panel rounded-[2rem] p-8">
      <span class="eyebrow">
        <UIcon name="i-lucide-history" />
        用户历史
      </span>
      <h1 class="mt-4 text-4xl font-semibold text-slate-900">历史记录中心</h1>
      <p class="mt-3 max-w-3xl text-sm leading-7 text-slate-600">
        所有分析结果都按账号归档在 Supabase 中。你可以查看旧结果、重新打开详情，或删除不需要的记录。
      </p>
    </div>

    <div class="grid gap-6 xl:grid-cols-[0.95fr_1.05fr]">
      <section class="space-y-4">
        <div class="flex items-center justify-between">
          <h2 class="text-2xl font-semibold text-slate-900">全部记录</h2>
          <span class="text-sm text-slate-500">{{ items.length }} 条</span>
        </div>

        <div v-if="loading" class="rounded-[1.5rem] bg-white/80 px-6 py-10 text-sm text-slate-500">
          正在加载…
        </div>

        <HistoryList
          v-else
          :items="items"
          @select="selected = $event"
          @remove="handleRemove"
        />
      </section>

      <AnalysisResultCard :result="selected?.result ?? null" />
    </div>
  </UContainer>
</template>
