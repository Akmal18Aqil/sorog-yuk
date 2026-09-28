<script setup lang="ts">
import type { Database } from '#shared/types/database'
import type { Kesiapan } from '#shared/types/sorogan'
import { ambilKesiapan, catatTesOffline, putuskanKenaikan } from '~/utils/repo'
import { hariIni } from '~/utils/tanggal'

definePageMeta({ middleware: 'auth' })

const sb = useSupabaseClient<Database>()
const { ustadz } = useUstadz()
const toast = useToast()

const daftar = ref<Kesiapan[]>([])
const memuat = ref(true)
const galat = ref('')
const sibuk = ref<number | null>(null)

const isiUntuk = ref<Kesiapan | null>(null)
const nilaiLuring = ref('')
const catatanLuring = ref('')

const siap = computed(() => daftar.value.filter(r => r.siap))
const belum = computed(() => daftar.value.filter(r => !r.siap && r.kelas_berikut))
const puncak = computed(() => daftar.value.filter(r => !r.kelas_berikut))

async function muat() {
  memuat.value = true
  galat.value = ''
  try { daftar.value = await ambilKesiapan(sb) }
  catch (e) { galat.value = (e as Error).message }
  finally { memuat.value = false }
}
onMounted(muat)

async function simpanLuring() {
  const r = isiUntuk.value
  if (!r?.santri_id || !r.kelas_kode || !ustadz.value) return
  const nilai = Number(nilaiLuring.value)
  if (!Number.isFinite(nilai) || nilai < 0 || nilai > 100) {
    galat.value = 'Nilai harus angka 0–100.'
    return
  }
  sibuk.value = r.santri_id
  galat.value = ''
  try {
    await catatTesOffline(sb, {
      santri_id: r.santri_id, kelas_kode: r.kelas_kode, nilai, tanggal: hariIni(),
      dicatat_oleh: ustadz.value.id, catatan: catatanLuring.value.trim() || null,
    })
    isiUntuk.value = null
    nilaiLuring.value = ''
    catatanLuring.value = ''
    toast.success('Nilai luring tersimpan.')
    await muat()
  }
  catch (e) { toast.error((e as Error).message) }
  finally { sibuk.value = null }
}

async function putuskan(r: Kesiapan, setuju: boolean) {
  if (!r.santri_id) return
  let catatan: string | undefined
  if (setuju && !r.siap) {
    const jawab = prompt(`${r.nama} belum memenuhi ambang. Alasan wajib dicatat:`)
    if (!jawab?.trim()) return
    catatan = jawab.trim()
  }
  else if (!setuju) {
    catatan = prompt(`Alasan menahan ${r.nama}:`)?.trim() || undefined
  }
  else if (!confirm(`Naikkan ${r.nama} ke ${r.kelas_berikut_nama}?`)) return

  sibuk.value = r.santri_id
  galat.value = ''
  try {
    await putuskanKenaikan(sb, r.santri_id, setuju, catatan)
    toast.success(setuju ? 'Kenaikan disetujui.' : 'Santri ditahan.')
    await muat()
  }
  catch (e) { toast.error((e as Error).message) }
  finally { sibuk.value = null }
}
</script>

<template>
  <div>
    <!-- Header -->
    <div class="page-head">
      <NuxtLink to="/mulai" class="back-btn">← Kembali</NuxtLink>
      <span class="text-muted text-sm">{{ ustadz?.nama }}</span>
    </div>

    <h1 class="page-title">Kenaikan Kelas</h1>
    <p class="text-muted text-sm page-sub">
      Naik kelas menuntut <b>dua</b> tes: ujian daring dan tes luring tatap muka.
    </p>

    <p v-if="memuat" class="text-muted text-sm">Memuat...</p>
    <p v-if="galat" class="galat">{{ galat }}</p>

    <template v-if="!memuat">
      <!-- Siap Naik -->
      <div class="section">
        <div class="section-header">
          <h2 class="section-title">Siap Naik</h2>
          <Badge variant="success" :label="`${siap.length} santri`" />
        </div>
        <p v-if="!siap.length" class="text-muted text-sm">Belum ada yang memenuhi kedua ambang.</p>

        <div v-for="r in siap" :key="r.santri_id ?? 0" class="kartu kartu-sukses">
          <KesiapanRingkas :baris="r" tampilkan-tujuan />
          <div class="baris" style="margin-top: var(--space-3)">
            <button class="utama" style="flex: 2" :disabled="sibuk === r.santri_id" @click="putuskan(r, true)">
              Setujui Naik
            </button>
            <button style="flex: 1" :disabled="sibuk === r.santri_id" @click="putuskan(r, false)">
              Tahan
            </button>
          </div>
        </div>
      </div>

      <!-- Belum Siap -->
      <div class="section">
        <div class="section-header">
          <h2 class="section-title">Belum Siap</h2>
          <Badge variant="warning" :label="`${belum.length} santri`" />
        </div>

        <div v-for="r in belum" :key="r.santri_id ?? 0" class="kartu">
          <KesiapanRingkas :baris="r" />

          <form v-if="isiUntuk?.santri_id === r.santri_id" style="margin-top: var(--space-3)" @submit.prevent="simpanLuring">
            <label :for="`n${r.santri_id}`">Nilai Tes Luring (0–100)</label>
            <input :id="`n${r.santri_id}`" v-model="nilaiLuring" inputmode="decimal" autocomplete="off" placeholder="0-100">
            <label :for="`c${r.santri_id}`">Catatan (opsional)</label>
            <input :id="`c${r.santri_id}`" v-model="catatanLuring" autocomplete="off" placeholder="Catatan">
            <div class="baris" style="margin-top: var(--space-3)">
              <button class="utama" style="flex: 2" type="submit" :disabled="sibuk === r.santri_id">
                Simpan
              </button>
              <button style="flex: 1" @click="isiUntuk = null">Batal</button>
            </div>
          </form>
          <div v-else class="baris" style="margin-top: var(--space-3)">
            <button style="flex: 2" @click="isiUntuk = r">Catat Tes Luring</button>
            <button style="flex: 1" :disabled="sibuk === r.santri_id" @click="putuskan(r, true)">
              Naikkan Tetap
            </button>
          </div>
        </div>
      </div>

      <!-- Puncak -->
      <div v-if="puncak.length" class="section">
        <div class="section-header">
          <h2 class="section-title">Kelas Tertinggi</h2>
          <Badge :label="`${puncak.length} santri`" />
        </div>
        <p class="text-muted text-sm">{{ puncak.map(r => r.nama).join(', ') }}</p>
      </div>
    </template>
  </div>
</template>
