<script setup lang="ts">
import type { Database } from '#shared/types/database'
import { JML_SOAL_BK1 } from '#shared/types/sorogan'
import { gabungKelemahan, gabungNilaiSantri } from '#shared/domain/ringkasan'
import { ambilDiagnostik, ambilLeger, type BarisLeger, type Diagnostik } from '~/utils/repo'
import { hariIni, tanggalPanjang } from '~/utils/tanggal'

definePageMeta({ middleware: 'auth' })

const sb = useSupabaseClient<Database>()
const { ustadz } = useUstadz()
const { acuan, muat } = useAcuan()

const data = ref<Diagnostik | null>(null)
const leger = ref<BarisLeger[]>([])
const galat = ref('')
const memuat = ref(true)
const tanggal = hariIni()

const namaSantri = computed(() =>
  new Map((acuan.value?.santri ?? []).map(s => [s.id, s.nama])))

const nilaiSantri = computed(() => gabungNilaiSantri(data.value?.nilaiSantri ?? []))
const kelemahan = computed(() => gabungKelemahan(data.value?.kelemahan ?? []).slice(0, 8))
const kalibrasi = computed(() => data.value?.kalibrasi ?? [])
const soalSulit = computed(() => data.value?.soalSulit ?? [])

const barisLeger = computed(() => {
  const per = new Map<number, Map<number, number>>()
  for (const b of leger.value) {
    if (!per.has(b.santri_id)) per.set(b.santri_id, new Map())
    per.get(b.santri_id)!.set(b.urutan, b.nilai)
  }
  return [...per.entries()].map(([santri_id, kolom]) => {
    const nilai = [...kolom.values()]
    return {
      santri_id,
      nama: namaSantri.value.get(santri_id) ?? `#${santri_id}`,
      kolom,
      rata: Math.round(nilai.reduce((a, b) => a + b, 0) / nilai.length),
    }
  })
})

const jmlKolom = computed(() =>
  Math.max(JML_SOAL_BK1, ...barisLeger.value.flatMap(b => [...b.kolom.keys()]), 1))

onMounted(async () => {
  await muat()
  if (!navigator.onLine) {
    galat.value = 'Perlu sinyal untuk melihat laporan.'
    memuat.value = false
    return
  }
  try {
    const [d, l] = await Promise.all([
      ambilDiagnostik(sb),
      ustadz.value ? ambilLeger(sb, ustadz.value.id, tanggal) : Promise.resolve([]),
    ])
    data.value = d
    leger.value = l
  }
  catch (e) { galat.value = (e as Error).message }
  finally { memuat.value = false }
})

const cetak = () => window.print()
</script>

<template>
  <div>
    <!-- Header -->
    <div class="nocetak" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--space-4)">
      <NuxtLink to="/mulai" class="back-btn">← Kembali</NuxtLink>
      <button class="kecil" @click="cetak">Cetak</button>
    </div>

    <h1 class="nocetak" style="margin-bottom: var(--space-4)">Hasil</h1>

    <p v-if="memuat" class="text-muted text-sm">Memuat...</p>
    <p v-else-if="galat" class="galat">{{ galat }}</p>

    <template v-if="data">
      <!-- Nilai Santri -->
      <div class="section nocetak">
        <h2 class="section-title">Nilai Santri</h2>
        <div class="gulir">
          <table>
            <tr><th class="kiri">Santri</th><th>Soal</th><th>Nilai</th></tr>
            <tr v-for="r in nilaiSantri" :key="r.santri_id">
              <td class="kiri">{{ namaSantri.get(r.santri_id) ?? `#${r.santri_id}` }}</td>
              <td>{{ r.jml_soal }}</td>
              <td><b>{{ r.nilai }}</b></td>
            </tr>
          </table>
        </div>
      </div>

      <!-- Kelemahan -->
      <div class="section nocetak">
        <h2 class="section-title">Anak-Tangga Terlemah</h2>
        <div class="gulir">
          <table>
            <tr><th class="kiri">Pertanyaan</th><th>N</th><th>Nilai</th></tr>
            <tr v-for="k in kelemahan" :key="k.kunci">
              <td class="kiri">{{ k.pertanyaan }}<br><span class="text-muted text-xs">{{ k.tipe }}</span></td>
              <td>{{ k.n }}</td>
              <td><div class="meter"><div class="meter-fill" :style="{ width: `${k.nilai}%` }" /></div>{{ k.nilai }}</td>
            </tr>
          </table>
        </div>
      </div>

      <!-- Kalibrasi -->
      <template v-if="kalibrasi.length > 1">
        <div class="section nocetak">
          <h2 class="section-title">Kalibrasi Penguji</h2>
          <div class="gulir">
            <table>
              <tr><th class="kiri">Penguji</th><th>Dinilai</th><th>Rata</th><th>Pembanding</th><th>Terkalibrasi</th></tr>
              <tr v-for="r in kalibrasi" :key="r.ustadz_id ?? 0">
                <td class="kiri">{{ r.nama }}</td>
                <td>{{ r.jml_santri }}</td>
                <td class="text-muted">{{ r.rata_penguji }}</td>
                <td>{{ r.jml_pembanding }}</td>
                <td v-if="r.selisih_terkalibrasi === null" class="text-muted">—</td>
                <td v-else :class="{ 'text-error': Math.abs(r.selisih_terkalibrasi) > 10 }">
                  {{ r.selisih_terkalibrasi > 0 ? '+' : '' }}{{ r.selisih_terkalibrasi }}
                </td>
              </tr>
            </table>
          </div>
        </div>
      </template>

      <!-- Soal Sulit -->
      <template v-if="soalSulit.length">
        <div class="section nocetak">
          <h2 class="section-title">Soal Tersulit</h2>
          <div class="gulir">
            <table>
              <tr><th class="kiri">Soal</th><th>Nilai</th></tr>
              <tr v-for="r in soalSulit" :key="r.soal_id ?? 0">
                <td class="kiri arab" style="font-size: 1.2rem">{{ r.teks }}</td>
                <td>{{ Math.round(r.nilai ?? 0) }}</td>
              </tr>
            </table>
          </div>
        </div>
      </template>
    </template>

    <!-- Leger -->
    <div v-if="barisLeger.length" class="leger">
      <h1 style="text-align: center; font-size: var(--text-xl)">Leger Penilaian</h1>
      <p style="text-align: center" class="text-muted text-sm">
        Penguji: {{ ustadz?.nama }} · {{ tanggalPanjang(tanggal) }}
      </p>
      <div class="gulir">
        <table>
          <tr>
            <th>No.</th><th class="kiri">Nama</th>
            <th v-for="i in jmlKolom" :key="i">{{ i }}</th>
            <th>Nilai</th>
          </tr>
          <tr v-for="(b, i) in barisLeger" :key="b.santri_id">
            <td>{{ i + 1 }}</td>
            <td class="kiri">{{ b.nama }}</td>
            <td v-for="k in jmlKolom" :key="k">
              {{ b.kolom.has(k) ? Math.round(b.kolom.get(k)!) : '' }}
            </td>
            <td><b>{{ b.rata }}</b></td>
          </tr>
        </table>
      </div>
    </div>
  </div>
</template>

<style scoped>
.leger { margin-top: var(--space-6); }
</style>
