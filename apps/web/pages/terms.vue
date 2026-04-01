<script setup lang="ts">
useSeoMeta({
  title: '用户协议 · 配料侦探'
})
</script>

<template>
  <LegalDocument
    eyebrow="用户协议"
    title="配料侦探用户服务协议"
    description="本协议用于约定你在使用配料侦探网站及相关分析服务时的权利义务、使用规则、免责范围和争议处理原则。"
    updated-at="2026-04-01"
  >
    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">1. 服务内容</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>配料侦探为用户提供食品配料图片识别、文本分析、健康建议、历史记录管理等服务。</p>
        <p>分析结果旨在提供信息参考和辅助判断，不构成医疗诊断、处方建议或专业法律意见。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">2. 用户义务</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>你应当合法使用本服务，不得上传违法违规内容，不得利用本服务从事侵犯他人权益、攻击系统或绕过权限控制的行为。</p>
        <p>你应保证提交的注册信息真实、准确，并妥善保管自己的登录凭证。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">3. 结果说明与免责</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>由于 OCR 识别质量、包装图清晰度、食品标签完整性及模型推理局限，分析结果可能存在误差。</p>
        <p>对于特殊疾病、过敏、孕期、慢病管理等高风险决策，请在使用本产品结果时结合医生、营养师或其他专业人士意见。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">4. 服务变更与中止</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>为了维护系统安全、升级功能或符合法律法规要求，我们有权调整、暂停或终止部分服务。</p>
        <p>如涉及对用户权益有重大影响的变更，建议在正式上线后增加站内公告或邮件通知机制。</p>
      </div>
    </section>

    <section class="glass-panel rounded-[1.6rem] p-6 sm:p-8">
      <h2 class="text-2xl font-semibold text-slate-900">5. 法律适用与争议处理</h2>
      <div class="mt-4 space-y-3 text-sm leading-7 text-slate-600">
        <p>本协议的订立、执行与解释适用中华人民共和国法律。</p>
        <p>若因本协议或本服务产生争议，建议由双方先协商解决；协商不成时，可提交有管辖权的人民法院处理。正式备案上线前，应结合运营主体所在地进一步完善该条款。</p>
      </div>
    </section>
  </LegalDocument>
</template>
