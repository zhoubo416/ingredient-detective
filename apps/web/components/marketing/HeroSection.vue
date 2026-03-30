<template>
  <section class="relative overflow-hidden py-20 sm:py-28">
    <UContainer class="grid gap-10 lg:grid-cols-[1.2fr_0.8fr] lg:items-center">
      <div class="space-y-6">
        <span class="eyebrow">
          <UIcon name="i-lucide-scan-line" />
          OCR + AI 全部在后台处理
        </span>
        <div class="space-y-5">
          <h1 class="section-title max-w-4xl">
            让食品配料表从“看不懂”变成
            <span class="text-emerald-700">可解释、可追踪、可复用</span>
          </h1>
          <p class="section-copy max-w-2xl">
            配料侦探把图片识别、配料解析、健康分析和用户历史统一放到 Nuxt 后台。
            用户先登录，再上传食品包装照片，系统会自动提取配料并生成结构化风险结论。
          </p>
        </div>
        <div class="flex flex-wrap gap-3">
          <UButton to="/login" size="xl" color="primary" trailing-icon="i-lucide-arrow-right">
            登录后开始分析
          </UButton>
          <UButton to="/dashboard" size="xl" variant="soft" color="neutral">
            查看后台
          </UButton>
        </div>
        <div class="grid gap-4 pt-3 sm:grid-cols-3">
          <div class="glass-panel rounded-3xl p-5">
            <p class="text-3xl font-semibold text-slate-900">1 次上传</p>
            <p class="mt-2 text-sm leading-6 text-slate-600">自动串联 OCR、配料抽取、AI 分析、入库存档。</p>
          </div>
          <div class="glass-panel rounded-3xl p-5">
            <p class="text-3xl font-semibold text-slate-900">100%</p>
            <p class="mt-2 text-sm leading-6 text-slate-600">所有分析记录绑定 Supabase 用户，可跨设备查看历史。</p>
          </div>
          <div class="glass-panel rounded-3xl p-5">
            <p class="text-3xl font-semibold text-slate-900">1 个后台</p>
            <p class="mt-2 text-sm leading-6 text-slate-600">网站用于宣传与转化，分析服务用于真正承接业务调用。</p>
          </div>
        </div>
      </div>

      <div class="relative">
        <div class="absolute inset-6 rounded-[2rem] bg-emerald-200/50 blur-3xl" />
        <div class="glass-panel relative rounded-[2rem] p-6 sm:p-8">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-semibold uppercase tracking-[0.24em] text-emerald-700">Analysis Preview</p>
              <h2 class="mt-2 text-2xl font-semibold text-slate-900">即拍即得结构化结论</h2>
            </div>
            <UBadge color="success" variant="soft">已登录可用</UBadge>
          </div>

          <div class="mt-8 space-y-4">
            <div class="rounded-3xl border border-slate-900/5 bg-white/90 p-5">
              <div class="flex items-center justify-between">
                <p class="text-sm font-medium text-slate-500">健康评分</p>
                <span class="rounded-full bg-emerald-50 px-3 py-1 text-sm font-semibold text-emerald-700">8.4 / 10</span>
              </div>
              <p class="mt-3 text-lg font-semibold text-slate-900">乳制品整体健康程度良好，建议继续关注糖含量。</p>
            </div>

            <div class="grid gap-4 sm:grid-cols-2">
              <div class="rounded-3xl border border-slate-900/5 bg-amber-50/90 p-5">
                <p class="text-sm font-medium text-amber-700">加工度</p>
                <p class="mt-2 text-xl font-semibold text-slate-900">中度加工</p>
                <p class="mt-2 text-sm leading-6 text-slate-600">存在稳定剂与风味增强成分，但主体原料仍清晰。</p>
              </div>
              <div class="rounded-3xl border border-slate-900/5 bg-slate-50/90 p-5">
                <p class="text-sm font-medium text-slate-500">追踪能力</p>
                <p class="mt-2 text-xl font-semibold text-slate-900">历史自动归档</p>
                <p class="mt-2 text-sm leading-6 text-slate-600">同一账号在网站和移动端都能看到同一批分析记录。</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </UContainer>
  </section>
</template>
