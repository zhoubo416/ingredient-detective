<script setup lang="ts">
import type { AnalysisHistoryItem, AnalysisResponse } from '~/shared/analysis'

const props = withDefaults(defineProps<{
  isPro: boolean
  subscriptionLoading?: boolean
  upgradeMessage?: string
}>(), {
  subscriptionLoading: false,
  upgradeMessage: ''
})

const emit = defineEmits<{
  completed: [item: AnalysisHistoryItem]
  startAnalyzing: []
}>()

const mode = ref<'image' | 'manual'>('image')
const file = ref<File | null>(null)
const fileInput = useTemplateRef<HTMLInputElement>('fileInput')
const selectedImage = ref<File | null>(null)
const previewUrl = ref('')
const productName = ref('')
const ingredientsText = ref('')
const errorMessage = ref('')
const loading = ref(false)
const showDownloadPrompt = ref(false)
const isAnalysisLocked = computed(() => props.subscriptionLoading || !props.isPro)
const downloadTargets = [
  {
    platform: 'iOS',
    description: 'App Store 下载演示占位符',
    qrSrc: '/placeholder-ios-qr.svg',
    href: 'https://example.com/ingredient-detective-ios',
    buttonLabel: '打开 iOS 占位链接'
  },
  {
    platform: 'Android',
    description: 'Android 下载演示占位符',
    qrSrc: '/placeholder-android-qr.svg',
    href: 'https://example.com/ingredient-detective-android',
    buttonLabel: '打开 Android 占位链接'
  }
] as const
const lockedDescription = computed(() => {
  if (props.subscriptionLoading) {
    return '正在检查 Pro 权限，请稍后再试。'
  }

  return props.upgradeMessage || '当前账号未开通 Pro，暂无法使用图片上传和配料文本分析。'
})
const submitLabel = computed(() => {
  if (props.subscriptionLoading) {
    return '正在检查 Pro 权限'
  }

  return props.isPro ? '提交到后台分析' : 'Pro 会员专享'
})

function resetPreview() {
  if (previewUrl.value) {
    URL.revokeObjectURL(previewUrl.value)
  }
  previewUrl.value = ''
}

function handleFileChange(event: Event) {
  if (isAnalysisLocked.value) {
    openDownloadPrompt()
    return
  }

  const target = event.target as HTMLInputElement
  const selectedFile = target.files?.[0] ?? null

  file.value = selectedFile
  selectedImage.value = selectedFile
  resetPreview()

  if (selectedFile) {
    previewUrl.value = URL.createObjectURL(selectedFile)
  }
}

function openDownloadPrompt() {
  errorMessage.value = ''
  showDownloadPrompt.value = true
}

function handleModeChange(nextMode: 'image' | 'manual') {
  if (isAnalysisLocked.value) {
    openDownloadPrompt()
    return
  }

  mode.value = nextMode
}

function handleImagePickerClick() {
  if (isAnalysisLocked.value) {
    openDownloadPrompt()
    return
  }

  fileInput.value?.click()
}

async function handleSubmit() {
  if (isAnalysisLocked.value) {
    openDownloadPrompt()
    return
  }

  loading.value = true
  errorMessage.value = ''

  const tempId = `temp-${Date.now()}`
  const tempItem: AnalysisHistoryItem = {
    id: tempId,
    sourceType: 'image',
    imageFilename: null,
    ingredientLines: [],
    rawOcrText: null,
    foodName: productName.value || '分析中',
    healthScore: 0,
    createdAt: new Date().toISOString(),
    result: {
      foodName: productName.value || '分析中',
      ingredients: [],
      healthScore: 0,
      compliance: { status: 'pending', description: '', issues: [] },
      processing: { level: '待分析', description: '', score: 0 },
      claims: { detectedClaims: [], supportedClaims: [], questionableClaims: [], assessment: '' },
      overallAssessment: '',
      recommendations: '',
      warnings: [],
      detailedStatus: 'pending',
      analysisTime: new Date().toISOString()
    }
  }

  emit('completed', tempItem)
  emit('startAnalyzing')

  try {
    const formData = new FormData()
    if (selectedImage.value) {
      formData.append('image', selectedImage.value)
    }
    if (ingredientsText.value) {
      formData.append('ingredientsText', ingredientsText.value)
    }
    if (productName.value) {
      formData.append('productName', productName.value)
    }

    const response = await $fetch<AnalysisResponse>('/api/analysis', {
      method: 'POST',
      body: formData
    })

    const historyItem: AnalysisHistoryItem = {
      id: response.id,
      sourceType: 'image',
      imageFilename: null,
      ingredientLines: [],
      rawOcrText: null,
      foodName: response.detailed?.foodName || response.quick.foodName,
      healthScore: response.detailed?.healthScore || response.quick.healthScore,
      createdAt: new Date().toISOString(),
      result: response.detailed || {
        foodName: response.quick.foodName,
        ingredients: [],
        healthScore: response.quick.healthScore,
        compliance: {
          ...response.quick.compliance,
          description: '',
          issues: []
        },
        processing: {
          ...response.quick.processing,
          description: ''
        },
        claims: {
          detectedClaims: [],
          supportedClaims: [],
          questionableClaims: [],
          assessment: ''
        },
        overallAssessment: response.quick.overallAssessment,
        recommendations: response.quick.recommendations,
        warnings: [],
        detailedStatus: response.isComplete ? 'complete' : 'pending',
        analysisTime: new Date().toISOString()
      }
    }

    emit('completed', historyItem)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '分析失败'
  } finally {
    loading.value = false
  }
}

// 轮询完整分析结果
async function pollForDetailedAnalysis(analysisId: string, maxAttempts = 60) {
  for (let i = 0; i < maxAttempts; i++) {
    await new Promise(resolve => setTimeout(resolve, 2000)) // 每 2 秒轮询一次

    try {
      const response = await $fetch<AnalysisHistoryItem>(`/api/analysis/${analysisId}`)

      if (
        response &&
        (
          response.result.detailedStatus === 'failed' ||
          response.result.detailedStatus === 'complete' ||
          (response.result.rawMarkdown && response.result.rawMarkdown.length > 0) ||
          (response.result.ingredients && response.result.ingredients.length > 0)
        )
      ) {
        // 发出更新事件，让父组件刷新结果显示
        emit('completed', response)
        return
      }
    } catch (err) {
      console.warn('[poll-error]', err)
    }
  }
}

onBeforeUnmount(() => {
  resetPreview()
})
</script>

<template>
  <UCard class="glass-panel rounded-[2rem]">
    <template #header>
      <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h2 class="text-2xl font-semibold text-slate-900">创建新的配料分析</h2>
          <p class="mt-2 text-sm leading-6 text-slate-600">
            上传商品配料图，或直接粘贴配料文本。提交后将由 Nuxt 后台完成 OCR 与 AI 分析。
          </p>
        </div>
        <div class="grid grid-cols-2 gap-2 rounded-2xl bg-slate-900/5 p-1">
          <button
            class="rounded-2xl px-4 py-2 text-sm font-semibold transition"
            :class="mode === 'image' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500'"
            @click="handleModeChange('image')"
          >
            图片
          </button>
          <button
            class="rounded-2xl px-4 py-2 text-sm font-semibold transition"
            :class="mode === 'manual' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500'"
            @click="handleModeChange('manual')"
          >
            输入
          </button>
        </div>
      </div>
    </template>

    <div class="flex flex-col" style="height: 42vh">
      <div class="flex-1 flex flex-col space-y-3 overflow-hidden">
        <UAlert
          v-if="isAnalysisLocked"
          color="warning"
          variant="soft"
          :title="subscriptionLoading ? '正在检查 Pro 权限' : '请先下载移动端并开通 Pro'"
          :description="lockedDescription"
          class="shrink-0"
        />

        <UAlert
          v-if="errorMessage"
          color="error"
          variant="soft"
          title="分析失败"
          :description="errorMessage"
          class="shrink-0"
        />

        <div class="space-y-1.5 shrink-0">
          <label class="text-sm font-medium text-slate-700" for="product-name">商品名称</label>
          <UInput
            id="product-name"
            v-model="productName"
            :disabled="isAnalysisLocked"
            size="lg"
            class="w-full"
            placeholder="可选，留空则由系统自动判断食品类型"
          />
        </div>

        <div v-if="mode === 'image'" class="space-y-3 flex-1 min-h-0">
          <button
            type="button"
            class="flex w-full flex-col items-center justify-center rounded-[1.75rem] border border-dashed border-slate-300 bg-white/70 px-6 text-center transition h-full"
            :class="isAnalysisLocked ? 'cursor-not-allowed opacity-60' : 'cursor-pointer hover:border-emerald-500 hover:bg-emerald-50/50'"
            @click="handleImagePickerClick"
          >
            <div v-if="previewUrl" class="overflow-hidden rounded-[1.75rem] border border-slate-900/5 bg-white/80 p-1 w-full h-full">
              <img :src="previewUrl" alt="Preview" class="w-full h-full rounded-[1.25rem] object-contain" />
            </div>
            <template v-show="!previewUrl">
              <UIcon name="i-lucide-image-plus" class="text-2xl text-emerald-700" />
              <p class="mt-2 text-sm font-semibold text-slate-900">选择食品包装图片</p>
              <p class="mt-1 text-xs text-slate-500">建议上传正面清晰、包含完整配料表的照片</p>
              <input ref="fileInput" class="hidden" type="file" accept="image/*" :disabled="isAnalysisLocked" @change="handleFileChange" />
            </template>
          </button>
        </div>

        <div v-else class="space-y-1.5 flex-1 min-h-0">
          <label class="text-sm font-medium text-slate-700" for="ingredients-text">配料文本</label>
          <div class="relative h-full">
            <UTextarea
              id="ingredients-text"
              v-model="ingredientsText"
              :disabled="isAnalysisLocked"
              class="w-full h-full resize-none"
              placeholder="例如：生牛乳、白砂糖、乳清蛋白粉、果胶……"
            />
            <button
              v-if="isAnalysisLocked"
              type="button"
              class="absolute inset-0 rounded-2xl"
              aria-label="打开移动端下载弹窗"
              @click="openDownloadPrompt"
            />
          </div>
        </div>
      </div>

      <div class="space-y-2 pt-3 mt-3 border-t border-slate-200 shrink-0">
        <UButton size="lg" :loading="loading" :disabled="subscriptionLoading" @click="handleSubmit" class="w-full">
          {{ submitLabel }}
        </UButton>
      </div>
    </div>
  </UCard>

  <div
    v-if="showDownloadPrompt"
    class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/55 px-4 py-8"
    @click.self="showDownloadPrompt = false"
  >
    <div class="w-full max-w-4xl rounded-[2rem] bg-white p-6 shadow-2xl sm:p-8">
      <div class="flex items-start justify-between gap-4">
        <div>
          <p class="text-sm font-semibold uppercase tracking-[0.24em] text-emerald-700">移动端下载</p>
          <h3 class="mt-3 text-2xl font-semibold text-slate-900">请先在 iOS 或 Android 端下载 App 并开通 Pro</h3>
          <p class="mt-3 max-w-2xl text-sm leading-6 text-slate-600">
            当前网页端暂不提供购买入口。下面两个二维码和链接都是演示占位符，你后续可以替换成真实的 iOS 与 Android 下载地址。
          </p>
        </div>
        <button
          type="button"
          class="rounded-full p-2 text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
          aria-label="关闭下载弹窗"
          @click="showDownloadPrompt = false"
        >
          <UIcon name="i-lucide-x" class="text-xl" />
        </button>
      </div>

      <div class="mt-8 grid gap-5 md:grid-cols-2">
        <article
          v-for="target in downloadTargets"
          :key="target.platform"
          class="rounded-[1.5rem] border border-slate-200 bg-slate-50/70 p-5"
        >
          <div class="flex items-center justify-between gap-3">
            <div>
              <h4 class="text-lg font-semibold text-slate-900">{{ target.platform }}</h4>
              <p class="mt-1 text-sm text-slate-500">{{ target.description }}</p>
            </div>
            <span class="rounded-full bg-white px-3 py-1 text-xs font-semibold text-slate-600 ring-1 ring-slate-200">
              Placeholder
            </span>
          </div>

          <div class="mt-5 overflow-hidden rounded-[1.25rem] border border-slate-200 bg-white p-4">
            <img :src="target.qrSrc" :alt="`${target.platform} QR placeholder`" class="mx-auto h-48 w-48 rounded-2xl object-cover" />
          </div>

          <div class="mt-4 space-y-3">
            <p class="rounded-2xl bg-white px-4 py-3 text-xs leading-5 text-slate-600 ring-1 ring-slate-200">
              {{ target.href }}
            </p>
            <UButton
              :to="target.href"
              target="_blank"
              rel="noreferrer"
              color="neutral"
              variant="soft"
              class="w-full"
            >
              {{ target.buttonLabel }}
            </UButton>
          </div>
        </article>
      </div>
    </div>
  </div>
</template>
