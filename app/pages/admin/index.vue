<script setup lang="ts">
import type { Database } from '#shared/types/database'
import { ambilStatistik } from '~/utils/repo'

definePageMeta({ middleware: 'auth' })

const sb = useSupabaseClient<Database>()
const { keluar } = useAuth()
const { theme, toggle } = useTheme()
const statistik = ref<{ jml_ustadz: number; jml_santri: number; jml_kelas: number; jml_kelompok: number; jml_sesi_bulan_ini: number } | null>(null)
const galat = ref('')

onMounted(async () => {
  try { statistik.value = await ambilStatistik(sb) }
  catch (e) { galat.value = (e as Error).message }
})

const menu = [
  { icon: '👥', label: 'Kelola User', desc: 'Ustadz & Santri', to: '/admin/kelola-user' },
  { icon: '📚', label: 'Kelas', desc: 'Tingkatan & ambang', to: '/admin/kelas' },
  { icon: '🎓', label: 'Kelas Kuliah', desc: 'Semester & naik semester', to: '/admin/kelas-kuliah' },
  { icon: '👨‍👩‍👧', label: 'Kelompok', desc: 'Kelompok & anggota', to: '/admin/kelompok' },
  { icon: '📖', label: 'Kitab', desc: 'Materi & ibarat', to: '/admin/kitab' },
  { icon: '❓', label: 'Soal', desc: 'Bank soal', to: '/admin/soal' },
  { icon: '📝', label: 'Langkah', desc: 'Rubrik penilaian', to: '/admin/langkah' },
]
</script>

<template>
  <div>
    <!-- Header -->
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--space-6)">
      <div>
        <h1 style="margin: 0">Dashboard</h1>
        <p class="subtitle" style="margin: 4px 0 0">Kelola data pesantren</p>
      </div>
      <div class="baris-tengah">
        <button class="kecil" @click="toggle" :title="theme === 'dark' ? 'Mode terang' : 'Mode gelap'">
          {{ theme === 'dark' ? '☀️' : '🌙' }}
        </button>
        <button class="kecil" @click="keluar">Keluar</button>
      </div>
    </div>

    <p v-if="galat" class="galat">{{ galat }}</p>

    <!-- Stats Grid -->
    <div v-if="statistik" class="grid-4 mb-4">
      <StatCard icon="👨‍🏫" :value="statistik.jml_ustadz" label="Ustadz" />
      <StatCard icon="👨‍🎓" :value="statistik.jml_santri" label="Santri" />
      <StatCard icon="📚" :value="statistik.jml_kelas" label="Kelas" />
      <StatCard icon="👨‍👩‍👧" :value="statistik.jml_kelompok" label="Kelompok" />
    </div>

    <!-- Quick Actions -->
    <div class="section">
      <div class="section-header">
        <h2 class="section-title">Kelola Data</h2>
      </div>

      <div class="kartu" style="padding: 0; overflow: hidden">
        <NuxtLink
          v-for="(item, i) in menu" :key="item.to"
          :to="item.to"
          class="list-item"
          :style="{ borderBottom: i < menu.length - 1 ? '1px solid var(--border)' : 'none' }"
        >
          <span class="avatar avatar-sm">{{ item.icon }}</span>
          <div class="list-item-content">
            <div class="list-item-title">{{ item.label }}</div>
            <div class="list-item-sub">{{ item.desc }}</div>
          </div>
        </NuxtLink>
      </div>
    </div>

    <!-- Sesi Info -->
    <div v-if="statistik" class="kartu" style="text-align: center">
      <p class="text-muted text-sm" style="margin: 0">Sesi Bulan Ini</p>
      <p style="font-size: var(--text-3xl); font-weight: 700; margin: var(--space-1) 0 0; color: var(--primary)">
        {{ statistik.jml_sesi_bulan_ini }}
      </p>
    </div>
  </div>
</template>
