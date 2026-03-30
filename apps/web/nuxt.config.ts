export default defineNuxtConfig({
  compatibilityDate: '2026-03-29',
  devtools: { enabled: true },
  css: ['~/assets/css/main.css'],
  modules: ['@nuxt/ui', '@nuxtjs/supabase'],
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
      supabaseAnonKey: process.env.NUXT_PUBLIC_SUPABASE_ANON_KEY ?? ''
    }
  },
  supabase: {
    redirect: false,
    url: process.env.NUXT_PUBLIC_SUPABASE_URL,
    key: process.env.NUXT_PUBLIC_SUPABASE_ANON_KEY
  }
})
