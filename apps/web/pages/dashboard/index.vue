<script setup lang="ts">
definePageMeta({
  middleware: 'auth'
})

await navigateTo('/dashboard/history', { replace: true })
</script>

<template>
  <div />
</template>
