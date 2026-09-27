<script setup lang="ts">
defineProps<{
  variant?: 'success' | 'warning' | 'error' | 'primary'
  label: string
}>()
</script>

<template>
  <span class="badge" :class="`badge-${variant || 'primary'}`">{{ label }}</span>
</template>
