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
    updated-at="2026-04-20"
  >
    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">1. 我们收集的信息</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>我们可能收集你的注册邮箱、登录信息、上传的食品图片、手动输入的配料文本、分析结果以及历史记录。</p>
        <p>如果你填写健康信息用于个性化分析，我们会将这些信息作为用户健康档案的一部分进行保存，用于生成更贴近你的提醒和建议。</p>
        <p>当你使用第三方账号（Google、Apple）登录时，我们会从对应服务提供商获取你的基础账号信息（如邮箱、昵称）用于创建和关联账号。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">2. 信息使用目的</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>我们使用这些信息用于账号认证、食品配料识别、健康分析、历史记录展示、服务优化以及安全审计。</p>
        <p>你的图片和文本内容不会用于与本服务无关的公开传播，也不会在未经授权的情况下向其他用户展示。</p>
        <p>我们可能使用匿名化、聚合后的数据用于改进算法、分析使用趋势和生成统计报告。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">3. 第三方服务</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>本服务依赖以下第三方平台：Supabase（数据存储与认证）、Google/Apple（第三方登录）、Google Analytics/百度统计（网站访问分析）。</p>
        <p>这些第三方服务有其各自的隐私政策，我们建议你在使用前阅读并了解其数据收集方式。</p>
        <p>我们不会向第三方出售、出租或交易你的个人信息。仅在法律法规要求、司法或行政机关依法要求时，我们可能依法提供必要信息。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">4. Cookie 使用</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>我们使用 Cookie 和类似技术用于维持登录状态、记住用户偏好、分析网站使用情况。</p>
        <p>你可以通过浏览器设置管理或禁用 Cookie，但这可能影响部分功能的正常使用。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">5. 信息存储与保护</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>账号信息和分析记录存储于本项目依赖的云服务中。我们会通过权限控制、服务端调用和密钥隔离等方式降低信息泄露风险。</p>
        <p>涉及 OCR 和模型推理的关键能力均在服务端执行，客户端不会直接暴露敏感凭证。</p>
        <p>除非你主动删除数据或注销账号，否则我们会持续存储你的信息以维持服务正常运行。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">6. 你的权利</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>你有权访问、更正、删除你的个人信息，也可以导出你的数据。</p>
        <p>你可以通过产品内功能删除历史记录，或联系站点运营方申请删除账号及相关数据。</p>
        <p>如果你希望注销账号，我们将依法删除你的个人信息，除非法律法规要求我们保留部分数据。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">7. 未成年人保护</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>本服务主要面向成年人。如果你未满 18 周岁，请在监护人的指导下使用本服务。</p>
        <p>我们不会在知情的情况下收集未成年人的个人信息。如果我们发现无意中收集了未成年人的信息，我们会尽快删除。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">8. 信息共享与删除</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>除法律法规要求、司法或行政机关依法要求外，我们不会主动向第三方出售你的个人信息。</p>
        <p>你可以通过产品内删除历史记录，或联系站点运营方申请删除账号及相关数据。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">9. 联系方式</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>如果你对本隐私政策有任何疑问或建议，请通过以下方式联系我们：</p>
        <p>邮箱：<a href="mailto:zhou.2516@qq.com" class="text-primary hover:underline">zhou.2516@qq.com</a></p>
      </div>
    </section>
  </LegalDocument>
</template>
