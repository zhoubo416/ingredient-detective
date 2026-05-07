<script setup lang="ts">
useSeoMeta({
  title: '下载 App · 配料侦探',
  description: '扫描二维码下载配料侦探 iOS / Android 客户端，随手拍照即可识别配料并获取健康评分。',
  ogTitle: '下载 App · 配料侦探',
  ogDescription: '扫描二维码下载配料侦探 iOS / Android 客户端，随手拍照即可识别配料并获取健康评分。'
})

const downloadTargets = [
  {
    platform: 'iOS',
    description: '使用 iPhone 相机扫描下方二维码，前往 App Store 下载',
    qrSrc: '/placeholder-ios-qr.svg',
    href: 'https://example.com/ingredient-detective-ios',
    buttonLabel: '前往 App Store'
  },
  {
    platform: 'Android',
    description: '使用安卓相机或浏览器扫描下方二维码下载安装包',
    qrSrc: '/placeholder-android-qr.svg',
    href: 'https://example.com/ingredient-detective-android',
    buttonLabel: '下载 Android APK'
  }
] as const
</script>

<template>
  <UContainer class="space-y-8 py-12">
    <div class="glass-panel reveal-up rounded-[2rem] p-8">
      <span class="eyebrow">
        <UIcon name="i-lucide-smartphone" />
        移动端下载
      </span>
      <h1 class="mt-4 text-4xl font-semibold text-slate-900">下载配料侦探 App</h1>
      <p class="mt-3 max-w-3xl text-sm leading-7 text-slate-600">
        网页端仅提供历史记录查看。请在 iOS 或 Android 端下载 App，开通 Pro 后使用拍照识别配料、AI 健康评分等完整功能。下载后请使用同一账号登录，分析记录会自动同步到此处。
      </p>
    </div>

    <div class="grid gap-6 md:grid-cols-2">
      <article
        v-for="target in downloadTargets"
        :key="target.platform"
        class="glass-panel reveal-up rounded-[2rem] p-6 sm:p-8"
      >
        <div class="flex items-center justify-between gap-3">
          <div>
            <h2 class="text-2xl font-semibold text-slate-900">{{ target.platform }}</h2>
            <p class="mt-1 text-sm text-slate-500">{{ target.description }}</p>
          </div>
          <span class="rounded-full bg-white px-3 py-1 text-xs font-semibold text-slate-600 ring-1 ring-slate-200">
            Placeholder
          </span>
        </div>

        <div class="mt-6 overflow-hidden rounded-[1.5rem] border border-slate-200 bg-white p-5">
          <img :src="target.qrSrc" :alt="`${target.platform} 下载二维码`" class="mx-auto h-56 w-56 rounded-2xl object-cover" />
        </div>

        <div class="mt-5 space-y-3">
          <p class="rounded-2xl bg-white px-4 py-3 text-xs leading-5 text-slate-600 ring-1 ring-slate-200 break-all">
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
  </UContainer>
</template>
