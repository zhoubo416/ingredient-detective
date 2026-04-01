<script setup lang="ts">
useSeoMeta({
  title: '隐私政策 · 配料侦探'
})
</script>

<template>
  <LegalDocument
    eyebrow="隐私政策"
    title="配料侦探隐私政策"
    description="本政策用于说明配料侦探在提供账号注册、食品配料识别、历史记录保存等服务过程中，如何收集、使用、存储和保护你的个人信息。"
    updated-at="2026-04-01"
  >
    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">1. 我们收集的信息</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>我们可能收集你的注册邮箱、登录信息、上传的食品图片、手动输入的配料文本、分析结果以及历史记录。</p>
        <p>如果你填写健康信息用于个性化分析，我们会将这些信息作为用户健康档案的一部分进行保存，用于生成更贴近你的提醒和建议。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">2. 信息使用目的</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>我们使用这些信息用于账号认证、食品配料识别、健康分析、历史记录展示、服务优化以及安全审计。</p>
        <p>你的图片和文本内容不会用于与本服务无关的公开传播，也不会在未经授权的情况下向其他用户展示。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">3. 信息存储与保护</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>账号信息和分析记录存储于本项目依赖的云服务中。我们会通过权限控制、服务端调用和密钥隔离等方式降低信息泄露风险。</p>
        <p>涉及 OCR 和模型推理的关键能力均在服务端执行，客户端不会直接暴露敏感凭证。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">4. 信息共享与删除</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>除法律法规要求、司法或行政机关依法要求外，我们不会主动向第三方出售你的个人信息。</p>
        <p>你可以通过产品内删除历史记录，或联系站点运营方申请删除账号及相关数据。建议预留联系邮箱并在正式上线前补充到本页。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">5. 联系方式</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>建议你在正式备案和上线前补充以下信息：运营主体名称、联系邮箱、联系电话、办公地址。</p>
        <p>当前可在页脚或本页补充一个正式联系邮箱，例如：`support@example.com`。</p>
      </div>
    </section>
  </LegalDocument>
</template>
