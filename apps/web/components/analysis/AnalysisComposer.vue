<script setup lang="ts">
import type { AnalysisHistoryItem } from '~/shared/analysis'

const emit = defineEmits<{
  completed: [item: AnalysisHistoryItem]
}>()

const mode = ref<'image' | 'manual'>('image')
const file = ref<File | null>(null)
const previewUrl = ref('')
const productName = ref('')
const ingredientsText = ref('')
const errorMessage = ref('')
const pending = ref(false)

function resetPreview() {
  if (previewUrl.value) {
    URL.revokeObjectURL(previewUrl.value)
  }
  previewUrl.value = ''
}

function handleFileChange(event: Event) {
  const target = event.target as HTMLInputElement
  const selectedFile = target.files?.[0] ?? null

  file.value = selectedFile
  resetPreview()

  if (selectedFile) {
    previewUrl.value = URL.createObjectURL(selectedFile)
  }
}

async function submitAnalysis() {
  pending.value = true
  errorMessage.value = ''

  try {
    let item: AnalysisHistoryItem

    if (mode.value === 'image') {
      if (!file.value) {
        throw new Error('请先选择一张食品包装图片。')
      }

      const formData = new FormData()
      formData.append('image', file.value)
      if (productName.value.trim()) {
        formData.append('productName', productName.value.trim())
      }

      item = await $fetch<AnalysisHistoryItem>('/api/analysis', {
        method: 'POST',
        body: formData
      })
    } else {
      item = await $fetch<AnalysisHistoryItem>('/api/analysis', {
        method: 'POST',
        body: {
          productName: productName.value.trim(),
          ingredientsText: ingredientsText.value.trim()
        }
      })
    }

    emit('completed', item)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '分析失败，请稍后再试。'
  } finally {
    pending.value = false
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
            @click="mode = 'image'"
          >
            上传图片
          </button>
          <button
            class="rounded-2xl px-4 py-2 text-sm font-semibold transition"
            :class="mode === 'manual' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500'"
            @click="mode = 'manual'"
          >
            手动输入
          </button>
        </div>
      </div>
    </template>

    <div class="space-y-5">
      <UAlert
        v-if="errorMessage"
        color="error"
        variant="soft"
        title="分析失败"
        :description="errorMessage"
      />

      <div class="space-y-2">
        <label class="text-sm font-medium text-slate-700" for="product-name">商品名称</label>
        <UInput
          id="product-name"
          v-model="productName"
          size="xl"
          placeholder="可选，留空则由系统自动判断食品类型"
        />
      </div>

      <div v-if="mode === 'image'" class="space-y-4">
        <label class="flex min-h-52 cursor-pointer flex-col items-center justify-center rounded-[1.75rem] border border-dashed border-slate-300 bg-white/70 px-6 py-8 text-center transition hover:border-emerald-500 hover:bg-emerald-50/50">
          <UIcon name="i-lucide-image-plus" class="text-3xl text-emerald-700" />
          <p class="mt-4 text-base font-semibold text-slate-900">选择食品包装图片</p>
          <p class="mt-2 text-sm text-slate-500">建议上传正面清晰、包含完整配料表的照片</p>
          <input class="hidden" type="file" accept="image/*" @change="handleFileChange" />
        </label>

        <div v-if="previewUrl" class="overflow-hidden rounded-[1.75rem] border border-slate-900/5 bg-white/80 p-3">
          <img :src="previewUrl" alt="Preview" class="h-64 w-full rounded-[1.25rem] object-cover" />
        </div>
      </div>

      <div v-else class="space-y-2">
        <label class="text-sm font-medium text-slate-700" for="ingredients-text">配料文本</label>
        <UTextarea
          id="ingredients-text"
          v-model="ingredientsText"
          :rows="8"
          placeholder="例如：生牛乳、白砂糖、乳清蛋白粉、果胶……"
        />
      </div>

      <UButton size="xl" :loading="pending" @click="submitAnalysis">
        提交到后台分析
      </UButton>
    </div>
  </UCard>
</template>
