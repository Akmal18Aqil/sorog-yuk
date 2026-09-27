<script setup lang="ts">
import type { Database } from '#shared/types/database'

definePageMeta({ middleware: 'auth' })

const sb = useSupabaseClient<Database>()

const email = ref('')
const sandi = ref('')
const nama = ref('')
const tingkat = ref('BK1')
const galat = ref('')
const sukses = ref('')
const sibuk = ref(false)

async function daftar() {
  if (!email.value.trim() || !sandi.value || !nama.value.trim()) {
    galat.value = 'Semua field wajib diisi.'
    return
  }
  sibuk.value = true
  galat.value = ''
  sukses.value = ''
  try {
    // 1. Buat akun Supabase Auth
    const { data, error } = await sb.auth.signUp({
      email: email.value.trim(),
      password: sandi.value,
    })
    if (error) throw new Error(error.message)
    if (!data.session) {
      sukses.value = 'Akun dibuat. Cek email untuk konfirmasi, lalu masuk.'
      sibuk.value = false
      return
    }

    // 2. Insert santri record
    const { error: rpcError } = await sb.rpc('daftar_santri', {
      p_nama: nama.value.trim(),
      p_tingkat: tingkat.value,
    })
    if (rpcError) throw new Error(rpcError.message)

    await navigateTo('/santri/dashboard')
  }
  catch (e) {
    galat.value = (e as Error).message
  }
  finally { sibuk.value = false }
}
</script>

<template>
  <div class="wadah">
    <h1>Daftar sebagai Santri</h1>
    <p class="redup">Buat akun untuk melihat nilai dan jadwal ujian.</p>

    <form class="kartu" @submit.prevent="daftar">
      <label for="em">Email</label>
      <input id="em" v-model="email" type="email" autocomplete="email" inputmode="email" placeholder="email@contoh.com">

      <label for="pw">Kata sandi</label>
      <input id="pw" v-model="sandi" type="password" autocomplete="new-password" placeholder="Minimal 6 karakter">

      <label for="nm">Nama</label>
      <input id="nm" v-model="nama" type="text" autocomplete="name" placeholder="Nama lengkap">

      <label for="tk">Tingkat</label>
      <select id="tk" v-model="tingkat">
        <option value="BK1">BK1</option>
        <option value="BK2">BK2</option>
      </select>

      <button class="utama" style="margin-top: 14px" type="submit" :disabled="sibuk">
        {{ sibuk ? 'Mendaftarkan...' : 'Daftar' }}
      </button>
      <p v-if="galat" class="galat">{{ galat }}</p>
      <p v-if="sukses" style="color: var(--benar); font-size: .85rem; margin-top: 8px">{{ sukses }}</p>
    </form>

    <NuxtLink to="/" class="penuh" style="margin-top: 8px; text-align: center; text-decoration: none; display: block">
      Kembali ke Masuk
    </NuxtLink>
  </div>
</template>
