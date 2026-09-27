<script setup lang="ts">
import type { Database } from '#shared/types/database'
import type { Ustadz } from '#shared/types/sorogan'
import { ambilUstadzBelumTerpakai } from '~/utils/repo'

const sb = useSupabaseClient<Database>()
const { login, deteksiRole, idSesi, keluar } = useAuth()
const { ustadz, periksa, hubungkan } = useUstadz()
const { theme, toggle } = useTheme()

const email = ref('')
const sandi = ref('')
const galat = ref('')
const sibuk = ref(false)
const tahap = ref<'masuk' | 'pilih' | 'kode'>('masuk')
const pilihan = ref<Ustadz[]>([])
const belumTerpakaiLoading = ref(false)

// Kode undangan ustad
const kode = ref('')

onMounted(lanjutkan)

async function lanjutkan() {
  const uid = await idSesi()
  if (!uid) return

  const role = await deteksiRole()
  if (role === 'superadmin') return navigateTo('/admin')
  if (role === 'ustadz') return navigateTo('/mulai')
  if (role === 'santri') return navigateTo('/santri/dashboard')

  // Backward compat
  if (await periksa()) return navigateTo('/mulai')

  tahap.value = 'pilih'
  await muatPilihan()
}

async function muatPilihan() {
  belumTerpakaiLoading.value = true
  try { pilihan.value = await ambilUstadzBelumTerpakai(sb) }
  catch {}
  belumTerpakaiLoading.value = false
}

async function masuk() {
  if (!email.value.trim() || !sandi.value) {
    galat.value = 'Email dan kata sandi harus diisi.'
    return
  }
  sibuk.value = true
  galat.value = ''
  try {
    await login(email.value.trim(), sandi.value)
    await lanjutkan()
  }
  catch (e) {
    galat.value = (e as Error).message
  }
  finally { sibuk.value = false }
}

async function pilih(u: Ustadz) {
  if (!confirm(`Hubungkan akun ini dengan ${u.nama}? Ini permanen.`)) return
  sibuk.value = true
  galat.value = ''
  try {
    await hubungkan(u.id)
    await navigateTo('/mulai')
  }
  catch (e) {
    const pesan = (e as Error).message
    if (pesan.includes('sudah terhubung') && await periksa()) return navigateTo('/mulai')
    galat.value = pesan
    await muatPilihan()
  }
  finally { sibuk.value = false }
}

async function daftarKode() {
  if (!kode.value.trim()) {
    galat.value = 'Kode undangan harus diisi.'
    return
  }
  sibuk.value = true
  galat.value = ''
  try {
    const { daftarUstadz } = useAuth()
    await daftarUstadz(kode.value.trim())
    await periksa()
    await navigateTo('/mulai')
  }
  catch (e) {
    galat.value = (e as Error).message
  }
  finally { sibuk.value = false }
}
</script>

<template>
  <div class="login-page">
    <!-- Login Form -->
    <section v-if="tahap === 'masuk'" class="login-section">
      <div class="login-header">
        <div style="position: absolute; top: var(--space-4); right: var(--space-4)">
          <button class="kecil" @click="toggle" :title="theme === 'dark' ? 'Mode terang' : 'Mode gelap'">
            {{ theme === 'dark' ? '☀️' : '🌙' }}
          </button>
        </div>
        <span class="login-icon">🕌</span>
        <h1>Sorogan Digital</h1>
        <p class="subtitle">Leger tes lisan baca kitab</p>
      </div>

      <form class="kartu login-form" @submit.prevent="masuk">
        <label for="em">Email</label>
        <input id="em" v-model="email" type="email" autocomplete="email" inputmode="email" placeholder="email@contoh.com">

        <label for="pw">Kata Sandi</label>
        <input id="pw" v-model="sandi" type="password" autocomplete="current-password" placeholder="Masukkan kata sandi">

        <button class="utama mt-4" type="submit" :disabled="sibuk">
          {{ sibuk ? 'Masuk...' : 'Masuk' }}
        </button>
        <p v-if="galat" class="galat">{{ galat }}</p>
      </form>

      <NuxtLink to="/daftar-santri" class="login-link">
        Daftar sebagai Santri →
      </NuxtLink>
    </section>

    <!-- Pilih Nama Ustadz (backward compat) -->
    <section v-else-if="tahap === 'pilih'" class="login-section">
      <div class="login-header">
        <span class="login-icon">👤</span>
        <h1>Anda ustadz yang mana?</h1>
        <p class="subtitle">Pilih nama Anda dari daftar</p>
      </div>

      <div v-if="belumTerpakaiLoading" class="text-center text-muted mt-4">Memuat...</div>
      <div v-else-if="pilihan.length" class="kartu">
        <button
          v-for="u in pilihan" :key="u.id"
          type="button" class="pilihan-item"
          :disabled="sibuk" @click="pilih(u)"
        >
          <Avatar :name="u.nama" />
          <span>{{ u.nama }}</span>
        </button>
      </div>
      <p v-else class="text-center text-muted mt-4">
        Semua nama sudah dipakai. Gunakan kode undangan.
      </p>

      <p v-if="galat" class="galat">{{ galat }}</p>

      <button class="penuh mt-3" @click="tahap = 'kode'">Punya kode undangan?</button>
      <button class="penuh mt-2" @click="keluar">Keluar</button>
    </section>

    <!-- Daftar Pakai Kode -->
    <section v-else class="login-section">
      <div class="login-header">
        <span class="login-icon">🔑</span>
        <h1>Daftar Ustad</h1>
        <p class="subtitle">Masukkan kode undangan dari admin</p>
      </div>

      <form class="kartu login-form" @submit.prevent="daftarKode">
        <label for="kode">Kode Undangan</label>
        <input id="kode" v-model="kode" type="text" autocomplete="off" placeholder="Contoh: A1B2C3" style="text-transform: uppercase; letter-spacing: 2px; text-align: center; font-size: var(--text-lg); font-weight: 600">
        <button class="utama mt-4" type="submit" :disabled="sibuk">
          {{ sibuk ? 'Memproses...' : 'Daftar' }}
        </button>
        <p v-if="galat" class="galat">{{ galat }}</p>
      </form>

      <button class="penuh mt-2" @click="tahap = 'masuk'">Kembali</button>
    </section>
  </div>
</template>

<style scoped>
.login-page {
  /* 100vh + padding kerangka akan melewati batas bawah. flex:1 mengisi
     tinggi yang tersedia dari .app-main, tanpa memaksa scroll. */
  flex: 1;
  display: flex; align-items: center; justify-content: center;
  padding: var(--space-4) 0;
}
.login-section { width: 100%; max-width: 400px; }
.login-header { text-align: center; margin-bottom: var(--space-6); }
.login-icon { font-size: 48px; display: block; margin-bottom: var(--space-3); }
.login-header h1 { margin: 0; font-size: var(--text-2xl); }
.login-form { padding: var(--space-6); }
.login-link {
  display: block; text-align: center; margin-top: var(--space-4);
  color: var(--primary); text-decoration: none; font-size: var(--text-sm); font-weight: 500;
}
.login-link:hover { text-decoration: underline; }

.pilihan-item {
  display: flex; align-items: center; gap: var(--space-3);
  width: 100%; text-align: left; padding: var(--space-3);
  border: none; background: transparent; border-radius: var(--radius-md);
  transition: background 0.15s ease;
}
.pilihan-item:hover { background: var(--bg); }
.pilihan-item + .pilihan-item { border-top: 1px solid var(--border); }
</style>
