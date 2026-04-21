<script setup lang="ts">
import type { AnalysisHistoryItem } from '~/shared/analysis'
import type { SubscriptionStatusResponse } from '~/shared/subscription'

definePageMeta({
  middleware: 'auth'
})

useSeoMeta({
  title: '分析台',
  description: '上传食品包装图片或配料文本，AI 自动完成识别与分析，获得健康评分和个性化建议。',
  ogTitle: '分析台 · 配料侦探',
  ogDescription: '上传食品包装图片或配料文本，AI 自动完成识别与分析，获得健康评分和个性化建议。'
})

const user = useSupabaseUser()
const history = ref<AnalysisHistoryItem[]>([])
const selected = ref<AnalysisHistoryItem | null>(null)
const isAnalyzing = ref(false)
const loading = ref(true)
const errorMessage = ref('')
const subscription = ref<SubscriptionStatusResponse | null>(null)
const subscriptionLoading = ref(true)
const subscriptionError = ref('')

const isProUser = computed(() => subscription.value?.isPro ?? false)
const subscriptionBadge = computed(() => {
  if (subscriptionLoading.value) {
    return '正在检查 Pro 权限'
  }

  return isProUser.value ? 'Pro 已开通' : '当前为免费版'
})
const upgradeMessage = computed(() => {
  if (subscriptionLoading.value) {
    return '正在检查 Pro 权限，请稍后再试。'
  }

  if (subscriptionError.value) {
    return subscriptionError.value
  }

  return '当前账号未开通 Pro，网页端已锁定图片上传和手动输入分析。请先在移动端升级 Pro，并使用同一账号登录。'
})

async function loadHistory() {
  loading.value = true
  errorMessage.value = ''

  try {
    const response = await $fetch<{ items: AnalysisHistoryItem[] }>('/api/history', {
      query: { limit: 6 }
    })

    history.value = response.items
    if (selected.value && !response.items.some(item => item.id === selected.value?.id)) {
      selected.value = null
    }
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '历史记录加载失败。'
  } finally {
    loading.value = false
  }
}

async function loadSubscriptionStatus() {
  subscriptionLoading.value = true
  subscriptionError.value = ''

  try {
    subscription.value = await $fetch<SubscriptionStatusResponse>('/api/subscription/status')
  } catch (error) {
    subscription.value = null
    subscriptionError.value = error instanceof Error
      ? error.message
      : '暂时无法确认当前账号的 Pro 权限，请刷新后重试。'
  } finally {
    subscriptionLoading.value = false
  }
}

function handleCompleted(item: AnalysisHistoryItem) {
  history.value = [item, ...history.value.filter(existing => existing.id !== item.id)]
  selected.value = item
  isAnalyzing.value = item.result?.detailedStatus === 'pending'
}

async function handleRemove(id: string) {
  await $fetch(`/api/history/${id}`, {
    method: 'DELETE'
  })

  history.value = history.value.filter(item => item.id !== id)
  if (selected.value?.id === id) {
    selected.value = null
  }
}

onMounted(() => {
  loadHistory()
  loadSubscriptionStatus()
})
</script>

<template>
  <UContainer class="space-y-8 py-12">
    <div class="glass-panel reveal-up rounded-[2rem] p-8">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <span class="eyebrow">
            <UIcon name="i-lucide-layout-dashboard" />
            用户后台
          </span>
          <h1 class="mt-4 text-4xl font-semibold text-slate-900">欢迎回来，{{ user?.email }}</h1>
          <p class="mt-3 max-w-3xl text-sm leading-7 text-slate-600">
            上传食品包装图或粘贴配料文本，系统会自动完成识别与分析。分析完成后可在历史页按关键词快速检索。
          </p>
        </div>
        <div class="flex flex-col items-start gap-3 sm:items-end">
          <span class="rounded-full bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm ring-1 ring-slate-900/5">
            {{ subscriptionBadge }}
          </span>
          <UButton to="/dashboard/history" color="neutral" variant="soft">
            历史查询
          </UButton>
        </div>
      </div>
    </div>

    <UAlert
      v-if="errorMessage"
      color="error"
      variant="soft"
      title="历史记录加载失败"
      :description="errorMessage"
    />

    <UAlert
      v-if="subscriptionError"
      color="warning"
      variant="soft"
      title="Pro 权限检查失败"
      :description="subscriptionError"
    />

    <div class="grid gap-6 xl:grid-cols-[0.9fr_1.1fr] items-stretch">
      <AnalysisComposer
        :is-pro="isProUser"
        :subscription-loading="subscriptionLoading"
        :upgrade-message="upgradeMessage"
        @completed="handleCompleted"
        @start-analyzing="isAnalyzing = true"
      />
      <div class="flex flex-col">
        <AnalysisResultCard
          :result="selected?.result ?? null"
          :analyzing="isAnalyzing"
          class="xl:sticky xl:top-4 flex-1"
        />
      </div>
    </div>

    <section class="space-y-4 reveal-up delay-1">
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
        :selected-id="selected?.id ?? ''"
        @select="selected = $event"
        @remove="handleRemove"
      />
    </section>
  </UContainer>
</template>
