<script setup lang="ts">
const config = useRuntimeConfig()

const googleAnalyticsId = config.public.googleAnalyticsId
const baiduTrackingId = config.public.baiduTrackingId

// Client端加载统计脚本
if (process.client) {
  // Google Analytics
  if (googleAnalyticsId) {
    const script = document.createElement('script')
    script.src = `https://www.googletagmanager.com/gtag/js?id=${googleAnalyticsId}`
    script.async = true
    document.head.appendChild(script)

    window.dataLayer = window.dataLayer || []
    function gtag(...args: any[]) {
      window.dataLayer?.push(args)
    }
    gtag('js', new Date())
    gtag('config', googleAnalyticsId)
    window.gtag = gtag
  }

  // Baidu Analytics
  if (baiduTrackingId) {
    const _hmt: any[] = []
    const hm = document.createElement('script')
    hm.src = `https://hm.baidu.com/hm.js?${baiduTrackingId}`
    const s = document.getElementsByTagName('script')[0]
    s?.parentNode?.insertBefore(hm, s)
    window._hmt = _hmt
  }
}
</script>

<template>
  <UApp>
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </UApp>
</template>
