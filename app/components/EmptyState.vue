<script setup lang="ts">
defineProps<{
  icon?: string
  message: string
}>()
</script>

<template>
  <div class="empty-state">
    <span v-if="icon" class="empty-icon">{{ icon }}</span>
    <p class="empty-text">{{ message }}</p>
  </div>
</template>

<style scoped>
.empty-state {
  text-align: center; padding: var(--space-8) var(--space-4);
}
.empty-icon {
  font-size: 48px; display: block; margin-bottom: var(--space-3); opacity: 0.5;
}
.empty-text {
  color: var(--muted); font-size: var(--text-sm); margin: 0;
}
</style>
