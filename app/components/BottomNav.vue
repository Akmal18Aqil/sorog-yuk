<script setup lang="ts">
import { navUtama } from '~/utils/nav'

const { role } = useAuth()
const route = useRoute()

const item = computed(() => navUtama(role.value))
</script>

<template>
  <nav v-if="item.length" class="bottom-nav" aria-label="Navigasi utama">
    <NuxtLink
      v-for="i in item" :key="i.to"
      :to="i.to"
      class="bottom-nav-item"
      :aria-current="route.path === i.to ? 'page' : undefined"
    >
      <IkonNav :nama="i.ikon" />
      <span class="bottom-nav-label">{{ i.label }}</span>
    </NuxtLink>
  </nav>
</template>
