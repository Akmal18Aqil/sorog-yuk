<script setup lang="ts">
/**
 * Laporan walikelas/kurikulum — baca saja, tanpa input nilai.
 *
 * Fase 0+1 (dasar): filter Semester x BK di atas `v_laporan_sorogan`.
 * Nilai = rata harian TERAKHIR per anak (isi view db/057); anak tanpa nilai
 * tetap tampil dengan strip + status H/I/S/A (keputusan yang dikunci).
 * Filter periode minggu/bulan + mode ujian menyusul Fase 2 (butuh RPC
 * agregasi rentang — view ini cuma simpan satu angka terakhir per anak).
 */
import type { Database } from '#shared/types/database'
import { ambilLaporan, ambilRekapMusrif, type BarisLaporan, type RekapMusrif } from '~/utils/repo'
import { hariIni, tanggalPanjang } from '~/utils/tanggal'

definePageMeta({ middleware: 'auth' })

const sb = useSupabaseClient<Database>()
const toast = useToast()
const { role } = useAuth()

/** Halaman bersama: tombol kembali ikut role yang membuka. */
const isAdmin = computed(() => role.value === 'superadmin')
const kembaliKe = computed(() => isAdmin.value ? '/admin' : '/mulai')

const semua = ref<BarisLaporan[]>([])
const galat = ref('')
const memuat = ref(true)
const fSemester = ref(0) // 0 = semua semester
const fBK = ref('') // '' = semua BK

const opsiSemester = computed(() =>
  [...new Set(semua.value.map(r => r.semester).filter((s): s is number => s != null))].sort((a, b) => a - b))

const opsiBK = computed(() =>
  [...new Set(semua.value.map(r => r.bk).filter((b): b is string => b != null))].sort())

/**
 * Ringkasan silang BK x semester: "di BK2 ada berapa anak Smt 1, Smt 5, ...".
 *
 * Dihitung dari data yang SAMA dengan tabel (`semua`), bukan query kedua:
 * angkanya tidak mungkin beda dengan yang disaring di bawah. Sel diklik =
 * pasang kedua filter sekaligus (bukan halaman baru — musrif tetap di konteks
 * yang sama, tinggal klik "Semua" untuk kembali).
 */
const ringkasan = computed(() => {
  const sel = new Map<string, number>()
  for (const r of semua.value) {
    const kunci = `${r.bk ?? '–'}|${r.semester ?? 0}`
    sel.set(kunci, (sel.get(kunci) ?? 0) + 1)
  }
  return {
    bk: opsiBK.value,
    semester: opsiSemester.value,
    jumlah: (bk: string, semester: number) => sel.get(`${bk}|${semester}`) ?? 0,
    totalBK: (bk: string) => semua.value.filter(r => (r.bk ?? '–') === bk).length,
    totalSemester: (s: number) => semua.value.filter(r => r.semester === s).length,
    total: semua.value.length,
  }
})

/** Urutan ikut repo (semester → urutan BK → nama); di sini tinggal saring. */
const baris = computed(() => semua.value.filter(r =>
  (!fSemester.value || r.semester === fSemester.value)
  && (!fBK.value || r.bk === fBK.value)))

const nilaiTeks = (r: BarisLaporan) => r.nilai_terakhir == null ? '–' : String(r.nilai_terakhir)

/** Judul dokumen: ikut filter yang sedang aktif, supaya hasil cetak/Excel
 *  menjelaskan dirinya sendiri tanpa bertanya "ini saringan yang mana". */
const judulFilter = computed(() => {
  const s = fSemester.value ? `Semester ${fSemester.value}` : 'Semua semester'
  const b = fBK.value ? fBK.value.replace('BK', 'BK ') : 'Semua BK'
  return `${s} · ${b}`
})
const judulDokumen = computed(() => `Laporan Sorogan — ${judulFilter.value}`)
const namaFile = computed(() => {
  const s = fSemester.value ? `smt${fSemester.value}` : 'semua-smt'
  const b = fBK.value ? fBK.value.toLowerCase() : 'semua-bk'
  return `laporan-sorogan-${s}-${b}-${hariIni()}.csv`
})

/**
 * Rekap per musrif — dimuat HANYA untuk superadmin. Musrif tidak memanggilnya:
 * RLS `sesi` memperbolehkan semua ustadz membaca semua sesi (kebutuhan
 * kalibrasi), jadi pemisah di sini adalah satu-satunya penutupnya.
 */
const rekap = ref<RekapMusrif[]>([])
watch(() => role.value, async (r) => {
  if (r !== 'superadmin') return
  try { rekap.value = await ambilRekapMusrif(sb, hariIni().slice(0, 7)) }
  catch (e) { galat.value = (e as Error).message }
}, { immediate: true })

onMounted(async () => {
  if (!navigator.onLine) {
    galat.value = 'Perlu sinyal untuk melihat laporan.'
    memuat.value = false
    return
  }
  try { semua.value = await ambilLaporan(sb) }
  catch (e) { galat.value = (e as Error).message }
  finally { memuat.value = false }
})

const cetak = () => {
  // Kelas penanda di <body>: aturan print halaman ini hanya berlaku saat
  // tombol Cetak di halaman ini ditekan — bukan saat mencetak dari /hasil.
  // `afterprint` membersihkan, termasuk bila user membatalkan dialog.
  document.body.classList.add('laporan-cetak')
  const bersih = () => {
    document.body.classList.remove('laporan-cetak')
    window.removeEventListener('afterprint', bersih)
  }
  window.addEventListener('afterprint', bersih)
  window.print()
}

/**
 * Ekspor Excel (.csv, bukan .xlsx) — tanpa dependensi baru.
 *
 * .csv dibuka Excel/Sheets/LibreOffice langsung, dan penulisannya ~15 baris
 * stdlib (Blob + URL). Lib `xlsx` (±800KB) hanya dibayar kalau nanti butuh
 * multi-sheet / format sel — belum dibutuhkan.
 *
 * Isi = tabel santri yang sedang tersaring (bukan seluruh DB), BOM `\uFEFF`
 * supaya Excel Windows membaca huruf Arab/aksen dengan benar.
 */
function keCsv(v: string | number | null | undefined): string {
  const t = v == null ? '' : String(v)
  return /[",\n;]/.test(t) ? `"${t.replace(/"/g, '""')}"` : t
}

function unduhExcel() {
  const kepala = ['No', 'Nama', 'Kode', 'Semester', 'BK', 'Kelompok', 'Nilai', 'Tanggal nilai', 'Status', 'Kendala']
  const isi = baris.value.map((r, i) => [
    i + 1, r.nama ?? '', r.kode ?? '', r.semester ?? '', r.bk ?? '',
    r.kelompok_nama ?? '', r.nilai_terakhir ?? '', r.tanggal_nilai ?? '',
    r.status_terakhir ?? '', r.kendala_terakhir ?? '',
  ])
  const csv = '﻿' + [kepala, ...isi].map(b => b.map(keCsv).join(';')).join('\r\n')
  const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }))
  const a = document.createElement('a')
  a.href = url
  a.download = namaFile.value
  a.click()
  URL.revokeObjectURL(url)
  toast.success(`${baris.value.length} baris diunduh.`)
}

async function salin() {
  const teks = baris.value.map((r, i) =>
    `${i + 1}. ${r.nama} (Smt ${r.semester ?? '–'} · ${r.bk ?? '–'} · ${r.kelompok_nama ?? '–'})`
    + ` — Nilai: ${nilaiTeks(r)}${r.tanggal_nilai ? ` (${tanggalPanjang(r.tanggal_nilai)})` : ''}`
    + ` — ${r.status_terakhir ?? 'belum dinilai'}${r.kendala_terakhir ? ` — Kendala: ${r.kendala_terakhir}` : ''}`,
  ).join('\n')
  try {
    await navigator.clipboard.writeText(teks)
    toast.success(`${baris.value.length} baris disalin.`)
  }
  catch { toast.error('Gagal menyalin.') }
}
</script>

<template>
  <div>
    <div class="nocetak" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--space-4)">
      <NuxtLink :to="kembaliKe" class="back-btn">← Kembali</NuxtLink>
      <div style="display: flex; gap: 8px">
        <button class="kecil" @click="salin">Salin WA</button>
        <button class="kecil" @click="unduhExcel">Excel</button>
        <button class="kecil" @click="cetak">Cetak</button>
      </div>
    </div>

    <h1 class="nocetak" style="margin-bottom: var(--space-2)">Laporan</h1>
    <p class="nocetak text-muted text-xs" style="margin-top: 0">
      Nilai = rata sorogan harian terakhir. Filter minggu/bulan/tahun menyusul Fase 2.
    </p>

    <p v-if="memuat" class="text-muted text-sm">Memuat...</p>
    <p v-else-if="galat" class="galat">{{ galat }}</p>

    <template v-else>
      <div class="kartu nocetak">
        <div class="pilih-baris">
          <div class="pilih-grup">
            <span class="pilih-label" id="lbl-semester">Semester</span>
            <div class="tabs" role="group" aria-labelledby="lbl-semester">
              <button class="tab" :class="{ active: !fSemester }" @click="fSemester = 0">Semua</button>
              <button
                v-for="s in opsiSemester" :key="s"
                class="tab" :class="{ active: fSemester === s }"
                @click="fSemester = s"
              >{{ s }}</button>
            </div>
          </div>
          <div class="pilih-grup">
            <span class="pilih-label" id="lbl-bk">BK</span>
            <div class="tabs" role="group" aria-labelledby="lbl-bk">
              <button class="tab" :class="{ active: !fBK }" @click="fBK = ''">Semua</button>
              <button
                v-for="b in opsiBK" :key="b"
                class="tab" :class="{ active: fBK === b }"
                @click="fBK = b"
              >{{ b.replace('BK', 'BK ') }}</button>
            </div>
          </div>
        </div>
      </div>

      <!-- Ringkasan silang: baris = BK, kolom = semester. Sel diklik langsung
           jadi filter (klik lagi / "Semua" untuk lepas). Angka ikut data yang
           sama dengan tabel di bawah, jadi tidak mungkin selisih. -->
      <div v-if="ringkasan.total" class="kartu nocetak">
        <span class="pilih-label">Sebaran santri</span>
        <div class="gulir">
          <table class="ringkas">
            <tr>
              <th class="kiri">BK \ Smt</th>
              <th v-for="s in ringkasan.semester" :key="s">Smt {{ s }}</th>
              <th>Total</th>
            </tr>
            <tr v-for="b in ringkasan.bk" :key="b">
              <th class="kiri">{{ b.replace('BK', 'BK ') }}</th>
              <td v-for="s in ringkasan.semester" :key="s">
                <button
                  class="sel" :class="{ aktif: fBK === b && fSemester === s, nol: !ringkasan.jumlah(b, s) }"
                  :title="`Tampilkan ${b} semester ${s}`"
                  @click="fBK === b && fSemester === s ? (fBK = '', fSemester = 0) : (fBK = b, fSemester = s)"
                >{{ ringkasan.jumlah(b, s) || '–' }}</button>
              </td>
              <td><b>{{ ringkasan.totalBK(b) }}</b></td>
            </tr>
            <tr>
              <th class="kiri">Total</th>
              <td v-for="s in ringkasan.semester" :key="s"><b>{{ ringkasan.totalSemester(s) }}</b></td>
              <td><b>{{ ringkasan.total }}</b></td>
            </tr>
          </table>
        </div>
      </div>

      <!-- Rekap per musrif: khusus superadmin. SENGAJA standalone, bukan filter
           tabel santri — `dicatat_oleh` di view hanya pencatat absen TERAKHIR,
           jadi mengaitkannya bisa menuduh musrif yang salah. -->
      <div v-if="isAdmin" class="section">
        <div class="section-header">
          <h2 class="section-title">Rekap musrif ({{ rekap.length }})</h2>
        </div>
        <div v-if="!rekap.length" class="text-muted text-sm">Belum ada aktivitas tercatat.</div>
        <div v-else class="gulir">
          <table>
            <tr><th class="kiri">Musrif</th><th>Sesi bln ini</th><th>Total sesi</th><th>Hadir dicatat</th><th>Kendala</th><th class="kiri">Terakhir aktif</th></tr>
            <tr v-for="m in rekap" :key="m.ustadz_id">
              <td class="kiri">{{ m.nama }}</td>
              <td>{{ m.sesi_bulan_ini }}</td>
              <td>{{ m.jml_sesi }}</td>
              <td>{{ m.jml_hadir }}</td>
              <td>{{ m.jml_kendala }}</td>
              <td class="kiri">{{ m.terakhir_aktif ? tanggalPanjang(m.terakhir_aktif) : '–' }}</td>
            </tr>
          </table>
        </div>
      </div>

      <div class="section dokumen">
        <div class="section-header">
          <h2 class="section-title">Santri ({{ baris.length }})</h2>
        </div>
        <!-- Kop dokumen: hanya muncul di cetakan. Di layar disembunyikan supaya
             tidak dobel dengan <h1> + tombol di atas. -->
        <div class="kop">
          <h1>{{ judulDokumen }}</h1>
          <p>Dicetak {{ tanggalPanjang(hariIni()) }} · {{ baris.length }} santri</p>
        </div>
        <div v-if="!baris.length" class="text-muted text-sm">Tidak ada santri pada filter ini.</div>
        <div v-else class="gulir">
          <table class="tabel-laporan">
            <thead>
              <tr><th>No.</th><th class="kiri">Nama</th><th class="kiri">Kelompok</th><th>Nilai</th><th class="kiri">Status</th><th class="kiri">Kendala</th></tr>
            </thead>
            <tbody>
              <tr v-for="(r, i) in baris" :key="r.santri_id ?? i">
                <td>{{ i + 1 }}</td>
                <td class="kiri">{{ r.nama }}<br><span class="text-muted text-xs">Smt {{ r.semester ?? '–' }} · {{ r.bk ?? '–' }}</span></td>
                <td class="kiri">{{ r.kelompok_nama ?? '–' }}</td>
                <td><b>{{ nilaiTeks(r) }}</b><br v-if="r.tanggal_nilai"><span v-if="r.tanggal_nilai" class="text-muted text-xs">{{ tanggalPanjang(r.tanggal_nilai) }}</span></td>
                <td class="kiri">{{ r.status_terakhir ?? '–' }}</td>
                <td class="kiri">{{ r.kendala_terakhir ?? '–' }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Tanda tangan: hanya di cetakan. Laporan ke walikelas tanpa kolom
           paraf akan diminta balik untuk ditandatangani. -->
      <div class="ttd">
        <div class="ttd-kotak">
          <p>Mengetahui,<br>Walikelas</p>
          <p class="ttd-nama">( .................... )</p>
        </div>
        <div class="ttd-kotak">
          <p>{{ tanggalPanjang(hariIni()) }}<br>Musrif</p>
          <p class="ttd-nama">( .................... )</p>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
/* Tabel ringkasan silang: sel berupa tombol supaya bisa diklik jadi filter.
   Sel nol diredupkan (tapi tetap diklik — "0 anak" juga informasi). */
.ringkas { min-width: 100%; }
.ringkas th, .ringkas td { text-align: center; white-space: nowrap; }
.ringkas th.kiri { text-align: left; }
.sel {
  min-width: 44px; min-height: 44px; padding: 0 10px;
  border-radius: var(--radius-full); font-weight: 700;
  background: transparent; color: inherit;
}
.sel.nol { color: var(--muted); font-weight: 400; }
.sel.aktif { background: var(--primary); border-color: var(--primary); color: var(--teks-aksen); }

/* Kop + tanda tangan: hanya untuk cetakan, disembunyikan di layar. */
.kop, .ttd { display: none; }
</style>

<style>
/* Aturan cetak KHUSUS halaman laporan. Scoped style tidak menembus
   `@media print` dengan andal di semua browser, jadi ditaruh global tanpa
   `scoped` — selektornya diawali `.dokumen`/`.kop`/`.ttd` supaya tidak
   menyentuh halaman lain. */
@media print {
  /* Kertas A4 portrait, margin hemat — tabel 6 kolom harus muat 1 halaman lebar. */
  @page { size: A4 portrait; margin: 12mm 10mm; }
  /* Sembunyikan SEMUA section kecuali dokumen santri: rekap musrif dan sebaran
     adalah alat kerja layar (ada tombol klik di dalamnya), bukan untuk walikelas.
     Tanpa ini cetakan 1 filter = 6 halaman campur aduk. */
  body.laporan-cetak .section:not(.dokumen) { display: none !important; }
  .kop { display: block; text-align: center; margin-bottom: 12px; }
  .kop h1 { font-size: 16pt; margin: 0 0 4px; }
  .kop p { font-size: 10pt; color: #444; margin: 0; }
  /* Header tabel berulang tiap halaman — laporan 50+ anak tidak kepotong judul. */
  .tabel-laporan thead { display: table-header-group; }
  .tabel-laporan tr { break-inside: avoid; }
  .tabel-laporan th, .tabel-laporan td { font-size: 10pt; padding: 4px 6px; }
  .ttd { display: flex; justify-content: space-between; margin-top: 24px; }
  .ttd-kotak { text-align: center; font-size: 10pt; }
  .ttd-nama { margin-top: 48px; }
}
</style>
