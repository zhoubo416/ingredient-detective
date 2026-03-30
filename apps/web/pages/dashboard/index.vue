<script setup lang="ts">
import type { AnalysisHistoryItem } from '~/shared/analysis'

definePageMeta({
  middleware: 'auth'
})

useSeoMeta({
  title: '分析台 · 配料侦探'
})

const user = useSupabaseUser()
const history = ref<AnalysisHistoryItem[]>([])
const selected = ref<AnalysisHistoryItem | null>(null)
const loading = ref(true)
const errorMessage = ref('')

async function loadHistory() {
  loading.value = true
  errorMessage.value = ''

  try {
    const response = await $fetch<{ items: AnalysisHistoryItem[] }>('/api/history', {
      query: { limit: 6 }
    })

    history.value = response.items
    selected.value = selected.value ?? response.items[0] ?? null
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '历史记录加载失败。'
  } finally {
    loading.value = false
  }
}

function handleCompleted(item: AnalysisHistoryItem) {
  history.value = [item, ...history.value.filter(existing => existing.id !== item.id)]
  selected.value = item
}

async function handleRemove(id: string) {
  await $fetch(`/api/history/${id}`, {
    method: 'DELETE'
  })

  history.value = history.value.filter(item => item.id !== id)
  if (selected.value?.id === id) {
    selected.value = history.value[0] ?? null
  }
}

onMounted(loadHistory)
</script>

<template>
  <UContainer class="space-y-8 py-12">
    <div class="glass-panel rounded-[2rem] p-8">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <span class="eyebrow">
            <UIcon name="i-lucide-layout-dashboard" />
            用户后台
          </span>
          <h1 class="mt-4 text-4xl font-semibold text-slate-900">欢迎回来，{{ user?.email }}</h1>
          <p class="mt-3 max-w-3xl text-sm leading-7 text-slate-600">
            在这里上传食品包装或粘贴配料文本。识别、分析和结果存储都由后端执行，客户端只负责输入和展示。
          </p>
        </div>
        <UButton to="/dashboard/history" color="neutral" variant="soft">
          查看完整历史
        </UButton>
      </div>
    </div>

    <UAlert
      v-if="errorMessage"
      color="error"
      variant="soft"
      title="历史记录加载失败"
      :description="errorMessage"
    />

    <div class="grid gap-6 xl:grid-cols-[0.9fr_1.1fr]">
      <AnalysisComposer @completed="handleCompleted" />
      <AnalysisResultCard :result="selected?.result ?? null" />
    </div>

    <section class="space-y-4">
      <div class="flex items-center justify-between">
        <h2 class="text-2xl font-semibold text-slate-900">最近历史</h2>
        <span class="text-sm text-slate-500">{{ history.length }} 条</span>
      </div>

      <div v-if="loading" class="rounded-[1.5rem] bg-white/80 px-6 py-10 text-sm text-slate-500">
        正在加载历史记录…
      </div>

      <HistoryList
        v-else
        :items="history"
        @select="selected = $event"
        @remove="handleRemove"
      />
    </section>
  </UContainer>
</template>
