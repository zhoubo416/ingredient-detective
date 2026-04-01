<script setup lang="ts">
defineProps<{
  eyebrow: string
  title: string
  description: string
  updatedAt: string
}>()
</script>

<template>
  <UContainer class="py-14 sm:py-20">
    <div class="space-y-8">
      <div class="glass-panel rounded-[1.8rem] p-8 sm:p-10">
        <span class="eyebrow">
          <UIcon name="i-lucide-shield-check" />
          {{ eyebrow }}
        </span>
        <h1 class="section-title mt-4">{{ title }}</h1>
        <p class="section-copy mt-4 max-w-3xl">
          {{ description }}
        </p>
        <p class="mt-4 text-sm text-slate-500">
          更新时间：{{ updatedAt }}
        </p>
      </div>

      <div class="grid gap-5">
        <slot />
      </div>
    </div>
  </UContainer>
</template>
