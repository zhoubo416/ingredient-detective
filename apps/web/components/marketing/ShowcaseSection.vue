<script setup lang="ts">
const timeline = [
  {
    title: '上传图片',
    copy: '拍照上传食品包装图，系统自动识别配料表。'
  },
  {
    title: '生成结论',
    copy: '快速给出健康分、总体判断和关键风险点。'
  },
  {
    title: '沉淀历史',
    copy: '结果自动进入历史记录，方便后续检索和比较。'
  }
] as const

const historyExpanded = ref(false)
</script>

<template>
  <section class="pb-20">
    <UContainer class="space-y-10">
      <div class="mx-auto max-w-3xl space-y-4 text-center reveal-up">
        <span class="eyebrow">
          <UIcon name="i-lucide-smartphone" />
          产品展示
        </span>
        <h2 class="section-title text-4xl">页面不是空讲概念，而是直接展示产品实际交付结果</h2>
        <p class="section-copy">
          首页应该先把结果长什么样讲清楚。下面这组示意，展示了用户最关心的两件事：分析结论和历史复盘。
        </p>
      </div>

      <div class="grid gap-6 xl:grid-cols-[1.1fr_0.9fr]">
        <div class="highlight-panel reveal-up p-6 sm:p-8">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.14em] text-emerald-700">Screen 01</p>
              <h3 class="mt-2 text-2xl font-semibold text-slate-900">分析结果页</h3>
            </div>
            <span class="promo-chip">首屏结论 + 配料解释</span>
          </div>

          <div class="mt-6 grid gap-5 lg:grid-cols-[0.52fr_0.48fr]">
            <div class="device-frame p-4">
              <div class="device-screen space-y-4 p-4">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="text-xs uppercase tracking-[0.14em] text-slate-400">Analysis</p>
                    <p class="mt-1 text-lg font-semibold text-slate-900">风味酸乳</p>
                  </div>
                  <div class="rounded-full bg-emerald-100 px-3 py-1 text-sm font-semibold text-emerald-700">
                    5.0 分
                  </div>
                </div>

                <div class="rounded-2xl bg-emerald-950 px-4 py-5 text-white">
                  <p class="text-xs uppercase tracking-[0.16em] text-emerald-200">总体判断</p>
                  <p class="mt-3 text-sm leading-6 text-emerald-50/90">
                    含糖和多种添加剂，偶尔食用可以，不适合作为日常高频乳制品。
                  </p>
                </div>

                <div class="space-y-2">
                  <!-- White sugar -->
                  <div class="rounded-lg border border-slate-200 bg-gradient-to-br from-slate-50 to-white p-2.5">
                    <div class="flex items-start justify-between gap-2 mb-1.5">
                      <p class="text-xs font-semibold text-slate-900 flex-1">白砂糖</p>
                      <span class="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-full bg-amber-50 text-amber-700 font-medium text-[10px]">
                        <UIcon name="i-lucide-alert-circle" class="size-2.5" />
                        注意
                      </span>
                    </div>
                    <div class="space-y-0.5 text-[11px] text-slate-600">
                      <div class="flex gap-1.5">
                        <span class="shrink-0 font-semibold text-slate-700 w-9">作用：</span>
                        <span class="flex-1 leading-snug">提供甜味和能量</span>
                      </div>
                      <div class="flex gap-1.5">
                        <span class="shrink-0 font-semibold text-slate-700 w-9">安全：</span>
                        <span class="flex-1 leading-snug line-clamp-1">常见甜味剂，需控制量</span>
                      </div>
                      <div class="flex gap-1.5 pt-0.5">
                        <span class="shrink-0 font-semibold text-amber-700 w-9">⚠️：</span>
                        <span class="flex-1 leading-snug text-amber-700">过量摄入不利健康</span>
                      </div>
                    </div>
                  </div>
                  
                  <!-- Pectin -->
                  <div class="rounded-lg border border-slate-200 bg-gradient-to-br from-slate-50 to-white p-2.5">
                    <div class="flex items-start justify-between gap-2 mb-1.5">
                      <p class="text-xs font-semibold text-slate-900 flex-1">果胶</p>
                      <span class="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-full bg-emerald-50 text-emerald-700 font-medium text-[10px]">
                        <UIcon name="i-lucide-check-circle" class="size-2.5" />
                        合规
                      </span>
                    </div>
                    <div class="space-y-0.5 text-[11px] text-slate-600">
                      <div class="flex gap-1.5">
                        <span class="shrink-0 font-semibold text-slate-700 w-9">作用：</span>
                        <span class="flex-1 leading-snug">增稠剂、胶凝剂</span>
                      </div>
                      <div class="flex gap-1.5">
                        <span class="shrink-0 font-semibold text-slate-700 w-9">安全：</span>
                        <span class="flex-1 leading-snug line-clamp-1">天然提取物，安全</span>
                      </div>
                    </div>
                  </div>
                  
                  <!-- Food flavor -->
                  <div class="rounded-lg border border-slate-200 bg-gradient-to-br from-slate-50 to-white p-2.5">
                    <div class="flex items-start justify-between gap-2 mb-1.5">
                      <p class="text-xs font-semibold text-slate-900 flex-1">食用香精</p>
                      <span class="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-full bg-emerald-50 text-emerald-700 font-medium text-[10px]">
                        <UIcon name="i-lucide-check-circle" class="size-2.5" />
                        合规
                      </span>
                    </div>
                    <div class="space-y-0.5 text-[11px] text-slate-600">
                      <div class="flex gap-1.5">
                        <span class="shrink-0 font-semibold text-slate-700 w-9">作用：</span>
                        <span class="flex-1 leading-snug">增强产品风味</span>
                      </div>
                      <div class="flex gap-1.5">
                        <span class="shrink-0 font-semibold text-slate-700 w-9">安全：</span>
                        <span class="flex-1 leading-snug line-clamp-1">人工调配，合规使用安全</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="space-y-4">
              <div
                v-for="item in timeline"
                :key="item.title"
                class="scenario-card p-5"
              >
                <p class="text-lg font-semibold text-slate-900">{{ item.title }}</p>
                <p class="mt-2 text-sm leading-6 text-slate-600">{{ item.copy }}</p>
              </div>
            </div>
          </div>
        </div>

        <div class="demo-card reveal-up delay-1 p-6 sm:p-8">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.14em] text-emerald-700">Screen 02</p>
              <h3 class="mt-2 text-2xl font-semibold text-slate-900">历史记录页</h3>
            </div>
            <span class="promo-chip">可检索 / 可回看 / 可对比</span>
          </div>

          <div class="mt-6 space-y-3">
            <div class="rounded-2xl border border-slate-200 bg-[#f7faf7] p-4">
              <div class="flex items-center justify-between gap-3">
                <div>
                  <p class="text-sm font-semibold text-slate-900">低糖酸奶</p>
                  <p class="mt-1 text-xs text-slate-500">白砂糖、果胶、乳清蛋白粉</p>
                </div>
                <span class="rounded-full bg-emerald-100 px-3 py-1 text-xs font-semibold text-emerald-700">7.4</span>
              </div>
            </div>
            <div class="rounded-2xl border border-slate-200 bg-white p-4">
              <div class="flex items-center justify-between gap-3 mb-3">
                <div>
                  <p class="text-sm font-semibold text-slate-900">风味酸乳</p>
                  <p class="mt-1 text-xs text-slate-500">白砂糖、果胶、食用香精</p>
                </div>
                <span class="rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold text-amber-700">5.0</span>
              </div>
              <button
                @click="historyExpanded = !historyExpanded"
                class="text-xs font-medium text-slate-600 hover:text-slate-900 transition-colors"
              >
                {{ historyExpanded ? '▼ 收起配料' : '▶ 展开配料' }}
              </button>
              
              <div v-if="historyExpanded" class="mt-3 space-y-2 pt-3 border-t border-slate-100">
                <!-- White sugar -->
                <div class="rounded-lg border border-slate-200 bg-gradient-to-br from-slate-50 to-white p-2.5">
                  <div class="flex items-start justify-between gap-2 mb-1.5">
                    <p class="text-xs font-semibold text-slate-900 flex-1">白砂糖</p>
                    <span class="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-full bg-amber-50 text-amber-700 font-medium text-[10px]">
                      <UIcon name="i-lucide-alert-circle" class="size-2.5" />
                      注意
                    </span>
                  </div>
                  <div class="space-y-0.5 text-[11px] text-slate-600">
                    <div class="flex gap-1.5">
                      <span class="shrink-0 font-semibold text-slate-700 w-9">作用：</span>
                      <span class="flex-1 leading-snug">提供甜味和能量</span>
                    </div>
                    <div class="flex gap-1.5">
                      <span class="shrink-0 font-semibold text-slate-700 w-9">安全：</span>
                      <span class="flex-1 leading-snug line-clamp-1">常见甜味剂，需控制量</span>
                    </div>
                    <div class="flex gap-1.5 pt-0.5">
                      <span class="shrink-0 font-semibold text-amber-700 w-9">⚠️：</span>
                      <span class="flex-1 leading-snug text-amber-700">过量摄入不利健康</span>
                    </div>
                  </div>
                </div>
                
                <!-- Pectin -->
                <div class="rounded-lg border border-slate-200 bg-gradient-to-br from-slate-50 to-white p-2.5">
                  <div class="flex items-start justify-between gap-2 mb-1.5">
                    <p class="text-xs font-semibold text-slate-900 flex-1">果胶</p>
                    <span class="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-full bg-emerald-50 text-emerald-700 font-medium text-[10px]">
                      <UIcon name="i-lucide-check-circle" class="size-2.5" />
                      合规
                    </span>
                  </div>
                  <div class="space-y-0.5 text-[11px] text-slate-600">
                    <div class="flex gap-1.5">
                      <span class="shrink-0 font-semibold text-slate-700 w-9">作用：</span>
                      <span class="flex-1 leading-snug">增稠剂、胶凝剂</span>
                    </div>
                    <div class="flex gap-1.5">
                      <span class="shrink-0 font-semibold text-slate-700 w-9">安全：</span>
                      <span class="flex-1 leading-snug line-clamp-1">天然提取物，安全</span>
                    </div>
                  </div>
                </div>
                
                <!-- Food flavor -->
                <div class="rounded-lg border border-slate-200 bg-gradient-to-br from-slate-50 to-white p-2.5">
                  <div class="flex items-start justify-between gap-2 mb-1.5">
                    <p class="text-xs font-semibold text-slate-900 flex-1">食用香精</p>
                    <span class="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-full bg-emerald-50 text-emerald-700 font-medium text-[10px]">
                      <UIcon name="i-lucide-check-circle" class="size-2.5" />
                      合规
                    </span>
                  </div>
                  <div class="space-y-0.5 text-[11px] text-slate-600">
                    <div class="flex gap-1.5">
                      <span class="shrink-0 font-semibold text-slate-700 w-9">作用：</span>
                      <span class="flex-1 leading-snug">增强产品风味</span>
                    </div>
                    <div class="flex gap-1.5">
                      <span class="shrink-0 font-semibold text-slate-700 w-9">安全：</span>
                      <span class="flex-1 leading-snug line-clamp-1">人工调配，合规使用安全</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="rounded-2xl border border-slate-200 bg-white p-4">
              <div class="flex items-center justify-between gap-3">
                <div>
                  <p class="text-sm font-semibold text-slate-900">儿童乳饮品</p>
                  <p class="mt-1 text-xs text-slate-500">葡萄糖浆、香精、稳定剂</p>
                </div>
                <span class="rounded-full bg-rose-100 px-3 py-1 text-xs font-semibold text-rose-700">3.8</span>
              </div>
            </div>
          </div>

          <div class="mt-6 rounded-2xl bg-slate-900 px-5 py-5 text-white">
            <p class="text-sm font-semibold">长期价值不止在单次识别，而在“你吃过什么、以后还想不想再买”。</p>
            <p class="mt-2 text-sm leading-6 text-slate-300">
              历史记录会让用户在超市、便利店或复购场景里真正回来使用，而不是一次性体验后流失。
            </p>
          </div>
        </div>
      </div>
    </UContainer>
  </section>
</template>
