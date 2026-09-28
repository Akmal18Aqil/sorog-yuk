<script setup lang="ts">
/**
 * Kelas kuliah — mengelompokkan Santri berdasarkan `semester`.
 *
 * BUKAN tabel baru. "Kelas kuliah" di sini adalah pengelompokan, bukan entitas:
 * `santri.semester` sudah menyimpan angkanya (lihat db/048). Tabel kedua untuk
 * angka yang sama hanya menambah satu tempat yang bisa salah.
 *
 * Isinya: melihat siapa ada di semester berapa, dan menaikkan semester
 * saat sudah waktunya. Kapan semester berganti tidak bisa ditebak dari
 * tanggal -- tergantung kalender sekolah -- jadi keputusannya di tangan admin.
 */
import type { Database } from '#shared/types/database'
import { ambilSemuaSantri, naikSemester } from '~/utils/repo'

definePageMeta({ middleware: 'auth' })

const sb = useSupabaseClient<Database>()
const toast = useToast()

const daftar = ref<{ id: number; nama: string; kode: string; semester: number | null; aktif: boolean }[]>([])
const galat = ref('')
const sibuk = ref(false)

// Semester tujuan, diisi sebelum konfirmasi. Sengaja BUKAN `+1` otomatis:
// ada sekolah yang memakai semester ganjil saja, dan ada yang Mundur satu.
const naikTarget = ref<Record<number, number>>({})
const konfirmasi = ref<{ dari: number; ke: number; jml: number } | null>(null)

/** Batas atas, sama dengan yang divalidasi `naik_semester` di server (db/048). */
const SEMESTER_MAX = 12

async function muat() {
  try {
    daftar.value = await ambilSemuaSantri(sb) as any
  } catch (e) { galat.value = (e as Error).message }
}

onMounted(muat)

/**
 * Dikelompokkan di memori, bukan lewat query kedua: `ambilSemuaSantri` sudah
 * memuat semua Santri ke memori untuk halaman ini, jadi query tambahan hanya
 * menambah satu round-trip tanpa menambah data. Daftar ini acuan, bukan nilai,
 * jadi tidak melanggar R6.
 */
const perSemester = computed(() => {
  const map = new Map<number, { semester: number; Santri: typeof daftar.value }>()
  for (const s of daftar.value) {
    // `null` bukan semester 0. Santri yang belum ditentukan semesternya tetap
    // terlihat sebagai kelompok tersendiri -- kalau disembunyikan, masalahnya
    // ikut tersembunyi.
    const key = s.semester ?? 0
    if (!map.has(key)) map.set(key, { semester: s.semester ?? 0, Santri: [] })
    map.get(key)!.Santri.push(s)
  }
  return [...map.values()].sort((a, b) => a.semester - b.semester)
})

const totalTanpaSemester = computed(() => daftar.value.filter(s => s.semester == null).length)

/** Kata kunci per semester, supaya mengetik di satu kotak tidak menggeser yang lain. */
const cariNama = ref<Record<number, string>>({})

/** Sama seperti "Pilih orang" di kelola-user: cocok nama ATAU kode. */
function saringNama(g: { semester: number; Santri: typeof daftar.value }) {
  const q = (cariNama.value[g.semester] ?? '').trim().toLowerCase()
  if (!q) return g.Santri
  return g.Santri.filter(s =>
    s.nama.toLowerCase().includes(q) || (s.kode ?? '').toLowerCase().includes(q))
}

/** Opsi tujuan: semua semester di atas asal, sampai batas atas. */
const opsiTujuan = (dari: number) =>
  Array.from({ length: SEMESTER_MAX - dari }, (_, i) => dari + i + 1)

const targetUntuk = (dari: number) => naikTarget.value[dari] ?? dari + 1

async function eksekusiNaik() {
  const t = konfirmasi.value
  if (!t) return
  sibuk.value = true
  try {
    const hasil = await naikSemester(sb, t.dari, t.ke)
    // `dilewati` dilaporkan, bukan disembunyikan: admin perlu tahu ada alumni
    // yang TIDAK ikut naik, kalau tidak ia mengira semua sudah naik.
    toast.success(hasil.dilewati > 0
      ? `${hasil.dipindah} naik ke semester ${t.ke}. ${hasil.dilewati} nonaktif tidak dinaikkan.`
      : `${hasil.dipindah} naik ke semester ${t.ke}.`)
    konfirmasi.value = null
    await muat()
  } catch (e) {
    toast.error((e as Error).message)
  } finally { sibuk.value = false }
}
</script>

<template>
  <div>
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--space-4)">
      <NuxtLink to="/admin" class="back-btn">← Kembali</NuxtLink>
    </div>
    <h1 style="margin-bottom: var(--space-2)">Kelas Kuliah</h1>
    <p class="text-muted text-sm" style="margin-bottom: var(--space-4)">
      Dikelompokkan berdasarkan semester. Naik semester berlaku untuk Santri aktif
      di semester tersebut.
    </p>
    <p v-if="galat" class="galat">{{ galat }}</p>

    <div v-for="g in perSemester" :key="g.semester" class="kartu" style="padding: 0; overflow: hidden">
      <div class="list-item">
        <span class="avatar">{{ g.semester === 0 ? '?' : g.semester }}</span>
        <div class="list-item-content">
          <div class="list-item-title">
            <template v-if="g.semester === 0">Belum ada semester</template>
            <template v-else>Semester {{ g.semester }}</template>
          </div>
          <div class="list-item-sub">
            {{ g.Santri.length }} santri
            <template v-if="g.Santri.filter(s => !s.aktif).length">
              · {{ g.Santri.filter(s => !s.aktif).length }} nonaktif
            </template>
          </div>
        </div>
      </div>

      <details style="padding: 0 var(--space-3) var(--space-3)">
        <summary class="text-muted text-sm" style="cursor: pointer">Lihat nama</summary>
        <!-- Satu semester bisa 46 nama. Digabung dalam satu paragraf, "cari
             Afif" berarti membaca semuanya dari awal -- pola yang sama dengan
             "Pilih orang" di kelola-user, dipakai ulang di sini. -->
        <div class="search" style="margin: var(--space-2) 0">
          <span class="search-icon">🔍</span>
          <input
            v-model="cariNama[g.semester]"
            type="search"
            autocomplete="off"
            placeholder="Ketik nama atau kode…"
          >
        </div>
        <p v-if="cariNama[g.semester] && !saringNama(g).length" class="redup" style="font-size: .85rem; margin: 0">
          Tidak ada yang cocok.
        </p>
        <p v-else style="margin: 0; font-size: .85rem">
          {{ saringNama(g).map(s => s.nama).join(', ') }}
        </p>
      </details>

      <div v-if="g.semester > 0 && g.semester < SEMESTER_MAX" class="baris" style="padding: 0 var(--space-3) var(--space-3)">
        <label :for="`naik-${g.semester}`" class="text-muted text-sm">Naik ke</label>
        <select :id="`naik-${g.semester}`" v-model.number="naikTarget[g.semester]">
          <option v-for="o in opsiTujuan(g.semester)" :key="o" :value="o">Semester {{ o }}</option>
        </select>
        <button
          class="utama"
          :disabled="sibuk || g.Santri.length === 0"
          @click="konfirmasi = { dari: g.semester, ke: targetUntuk(g.semester), jml: g.Santri.length }"
        >
          Naik
        </button>
      </div>
      <p v-else-if="g.semester === SEMESTER_MAX" class="redup" style="font-size: .75rem; padding: 0 var(--space-3) var(--space-3); margin: 0">
        Semester tertinggi — sudah tidak ada tujuan naik.
      </p>
    </div>

    <EmptyState v-if="!perSemester.length" icon="🎓" message="Belum ada santri." />

    <p v-if="totalTanpaSemester" class="redup" style="font-size: .75rem; margin-top: var(--space-3)">
      {{ totalTanpaSemester }} santri belum punya semester. Isi dulu di Kelola User.
    </p>

    <ConfirmDialog
      :visible="!!konfirmasi"
      :message="konfirmasi ? `Naikkan ${konfirmasi.jml} santri dari semester ${konfirmasi.dari} ke ${konfirmasi.ke}?` : ''"
      @confirm="eksekusiNaik"
      @cancel="konfirmasi = null"
    />
  </div>
</template>
