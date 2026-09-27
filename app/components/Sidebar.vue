<script setup lang="ts">
import { navUntuk } from '~/utils/nav'

const { role, keluar } = useAuth()
const { theme, toggle } = useTheme()

const route = useRoute()

// computed, bukan sekali jalan: role baru terisi setelah sesi dicek, dan
// sidebar harus ikut berubah saat itu terjadi.
const item = computed(() => navUntuk(role.value))
</script>

<template>
  <nav class="sidebar" aria-label="Navigasi utama">
    <div class="sidebar-kepala">
      <NuxtLink :to="item[0]?.to ?? '/'" class="sidebar-nama">Sorogan</NuxtLink>
      <button
        class="kecil"
        :aria-label="theme === 'dark' ? 'Mode terang' : 'Mode gelap'"
        @click="toggle"
      >
        {{ theme === 'dark' ? 'Terang' : 'Gelap' }}
      </button>
    </div>

    <ul class="sidebar-daftar">
      <li v-for="i in item" :key="i.to">
        <NuxtLink
          :to="i.to"
          class="sidebar-item"
          :aria-current="route.path === i.to ? 'page' : undefined"
        >
          {{ i.label }}
        </NuxtLink>
      </li>
    </ul>

    <button class="sidebar-keluar" @click="keluar">Keluar</button>
  </nav>
</template>

<style scoped>
.sidebar {
  position: sticky;
  top: 0;
  align-self: start;
  height: 100dvh;
  width: 216px;
  flex: 0 0 216px;
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
  padding: var(--space-5) var(--space-3);
  background: var(--surface);
  border-right: 1px solid var(--border);
  overflow-y: auto;
}

.sidebar-kepala {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-2);
  padding: 0 var(--space-2);
}

.sidebar-nama {
  font-size: var(--text-md);
  font-weight: 700;
  color: var(--text);
  text-decoration: none;
  letter-spacing: -0.01em;
}

.sidebar-daftar {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
  flex: 1;
}

.sidebar-item {
  display: flex;
  align-items: center;
  min-height: 44px;
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-sm);
  color: var(--muted);
  font-size: var(--text-sm);
  font-weight: 500;
  text-decoration: none;
}
.sidebar-item:hover { background: var(--bg); color: var(--text); }
.sidebar-item[aria-current='page'] {
  background: var(--primary-light);
  color: var(--primary);
  font-weight: 600;
}
.sidebar-item[aria-current='page']:hover {
  background: var(--primary-light);
  color: var(--primary);
}

.sidebar-keluar {
  min-height: 44px;
  color: var(--muted);
  font-size: var(--text-sm);
}
.sidebar-keluar:hover { color: var(--text); }
</style>
