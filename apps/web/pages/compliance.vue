<script setup lang="ts">
useSeoMeta({
  title: '备案与合规说明 · 配料侦探'
})

const checklist = [
  '补充运营主体名称、统一社会信用代码或个人主体信息',
  '准备备案域名、服务器信息和接入商信息',
  '补充正式联系邮箱、联系电话和联系地址',
  '在正式上线前展示 ICP 备案号与公安备案信息入口',
  '确认隐私政策、用户协议与数据删除流程一致',
  '准备未成年人保护、内容安全和投诉处理机制说明'
] as const
</script>

<template>
  <LegalDocument
    eyebrow="备案与合规"
    title="备案与合规说明"
    description="本页用于为网站备案和正式上线做准备，展示当前已补充的法务页面以及建议在备案前完善的信息。"
    updated-at="2026-04-01"
  >
    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">1. 当前已准备内容</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>网站已补充隐私政策、用户协议和本页备案说明，并在页脚提供统一入口。</p>
        <p>正式备案完成后，建议在页脚追加 ICP 备案号、公安备案号和运营主体信息展示。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">2. 备案前建议补齐的信息</h2>
      <div class="mt-4 grid gap-3">
        <div
          v-for="item in checklist"
          :key="item"
          class="scenario-card p-4"
        >
          <p class="text-sm leading-6 text-slate-700">{{ item }}</p>
        </div>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">3. 页脚展示建议</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>备案完成后，建议页脚展示格式为：`ICP备案号`、`公安备案号`、`隐私政策`、`用户协议`、`联系邮箱`。</p>
        <p>如果当前还未完成备案，可以先展示“备案准备中，备案完成后将公示备案编号”的占位说明。</p>
      </div>
    </section>
  </LegalDocument>
</template>
