<script setup lang="ts">
const props = defineProps<{
  name: string
  size?: 'sm' | 'md' | 'lg'
}>()

const initials = computed(() => {
  return props.name
    .split(' ')
    .map(w => w[0])
    .join('')
    .substring(0, 2)
    .toUpperCase()
})
</script>

<template>
  <div class="avatar" :class="size ? `avatar-${size}` : ''">
    {{ initials }}
  </div>
</template>
