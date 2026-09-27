<script setup lang="ts">
defineProps<{
  icon: string
  value: number | string
  label: string
}>()
</script>

<template>
  <div class="stat-card">
    <div class="icon">{{ icon }}</div>
    <p class="value">{{ value }}</p>
    <p class="label">{{ label }}</p>
  </div>
</template>
