export default defineNuxtConfig({
  compatibilityDate: '2026-03-29',
  devtools: { enabled: true },
  css: ['~/assets/css/main.css'],
  modules: ['@nuxt/ui', '@nuxtjs/supabase'],
  ui: {
    fonts: false
  },
  app: {
    head: {
      meta: [
        { charset: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'description', content: '配料侦探 - AI智能分析食品成分安全与营养价值。通过拍照识别配料表，快速获得专业的健康评分和个性化建议。关注食品安全，守护全家健康。' },
        { name: 'keywords', content: '食品成分分析,配料表,营养成分,食品安全,AI识别,健康评分,添加剂,食品分析工具' },
        { name: 'author', content: '配料侦探' },
        { name: 'theme-color', content: '#10b981' },
        { property: 'og:type', content: 'website' },
        { property: 'og:title', content: '配料侦探 - 智能食品成分分析' },
        { property: 'og:description', content: '拍照识别食品包装成分，AI智能分析营养价值和食品安全' },
        { name: 'twitter:card', content: 'summary_large_image' },
        { name: 'twitter:title', content: '配料侦探 - 智能食品成分分析' }
      ],
      link: [
        { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/favicon-32x32.png' },
        { rel: 'icon', type: 'image/png', sizes: '16x16', href: '/favicon-16x16.png' },
        { rel: 'apple-touch-icon', sizes: '180x180', href: '/apple-touch-icon.png' },
        { rel: 'manifest', href: '/site.webmanifest' },
        { rel: 'canonical', href: 'https://ingredient-detective.com' }
      ]
    }
  },
  runtimeConfig: {
    llmProvider: process.env.LLM_PROVIDER ?? '',
    llmModel: process.env.LLM_MODEL ?? '',
    dashscopeApiKey: process.env.DASHSCOPE_API_KEY ?? '',
    deepseekApiKey: process.env.DEEPSEEK_API_KEY ?? '',
    aliyunAccessKeyId: process.env.ALIYUN_ACCESS_KEY_ID ?? '',
    aliyunAccessKeySecret: process.env.ALIYUN_ACCESS_KEY_SECRET ?? '',
    aliyunOcrEndpoint: process.env.ALIYUN_OCR_ENDPOINT ?? 'https://ocr-api.cn-hangzhou.aliyuncs.com',
    aliyunRegionId: process.env.ALIYUN_REGION_ID ?? 'cn-hangzhou',
    supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY ?? '',
    public: {
      appName: '配料侦探',
      marketingSiteUrl: process.env.NUXT_PUBLIC_MARKETING_SITE_URL ?? 'http://localhost:3000',
      supabaseUrl: process.env.NUXT_PUBLIC_SUPABASE_URL ?? '',
      supabaseAnonKey: process.env.NUXT_PUBLIC_SUPABASE_ANON_KEY ?? '',
      googleAnalyticsId: process.env.NUXT_PUBLIC_GOOGLE_ANALYTICS_ID ?? '',
      baiduTrackingId: process.env.NUXT_PUBLIC_BAIDU_TRACKING_ID ?? ''
    }
  },
  supabase: {
    redirect: false,
    url: process.env.NUXT_PUBLIC_SUPABASE_URL,
    key: process.env.NUXT_PUBLIC_SUPABASE_ANON_KEY,
    cookieOptions: {
      sameSite: 'lax',
      secure: false
    }
  }
})
