<script setup lang="ts">
import {
  JML_SOAL_BK1, MODE, PER_TIPE_BK2,
  isTingkat,
  type Kelompok, type Mode, type Santri, type Tingkat,
} from '#shared/types/sorogan'
import { tipeKurangStok } from '#shared/domain/pembagian'
import {
  LABEL_STATUS, STATUS_HADIR, isStatusHadir,
  kelasBerisiKelompok, kelompokKelas, kelompokTanpaKelas,
  type StatusHadir,
} from '#shared/domain/kelompok'
import type { Database } from '#shared/types/database'
import { ambilHadirHariIni, santriKelompok } from '~/utils/repo'
import { hariIni } from '~/utils/tanggal'

definePageMeta({ middleware: 'auth' })

// Cukup SATU kunci: kelompok sudah menentukan kelasnya sendiri, jadi
// menyimpan kelas terpisah berarti dua nilai yang bisa saling bertentangan.
const KUNCI_TERAKHIR = 'sorogan.kelompok-terakhir'

const sb = useSupabaseClient<Database>()
const { $antrean } = useNuxtApp()
const toast = useToast()
const { ustadz, keluar } = useUstadz()
const { acuan, galat, muat } = useAcuan()
const { mulai, pulihkan, selesaiHariIni } = useSesi()

const kelompok = ref<Kelompok | null>(null)
const tingkat = ref<Tingkat>('BK1')
const mode = ref<Mode>('ujian')
const adaKemajuan = ref(false)
// Absen hari ini per santri_id. Dari server saat online; dari antrean lokal
// tidak perlu — yang diketuk barusan langsung terlihat karena di-set di sini.
const hadir = ref(new Map<number, { status: string; kendala: string | null }>())

const LABEL_TINGKAT: Record<Tingkat, string> = { BK1: 'BK 1 — lafad', BK2: 'BK 2 — tarkib' }
const LABEL_MODE: Record<Mode, string> = { ujian: 'Ujian', harian: 'Sorogan harian' }

// ——— kelas dan kelompoknya ———
// Kelas yang boleh dipilih hanya yang punya kelompok; kelompok yang tampil
// hanya milik kelas terpilih. Aturannya di shared/domain, bukan di sini.
//
// Scope tugas: tabel tugas KOSONG = semua terbuka (hari ini). Berisi = hanya
// kelompok musrif ini. Filter di sini (UX) + cek di RPC (keamanan).
const semuaKelompok = computed<Kelompok[]>(() => acuan.value?.kelompok ?? [])
const kelompokBoleh = computed<Kelompok[]>(() => {
  const tugas = acuan.value?.tugas ?? []
  return tugas.length ? semuaKelompok.value.filter(k => tugas.includes(k.id)) : semuaKelompok.value
})
const kelasTersedia = computed<Tingkat[]>(() => kelasBerisiKelompok(kelompokBoleh.value))
const kelompokSatuKelas = computed<Kelompok[]>(() =>
  kelompokKelas(kelompokBoleh.value, tingkat.value))
const tanpaKelas = computed<Kelompok[]>(() => kelompokTanpaKelas(kelompokBoleh.value))

const jmlSoal = computed(() => tingkat.value === 'BK1' ? JML_SOAL_BK1 : PER_TIPE_BK2 * 4)

const anggota = computed<Santri[]>(() =>
  acuan.value && kelompok.value ? santriKelompok(acuan.value, kelompok.value.id) : [])

const sudah = (s: Santri) => selesaiHariIni.value.includes(s.id)
const jmlSudah = computed(() => anggota.value.filter(sudah).length)

/**
 * Berapa santri di kelompok ini yang BELUM dinilai hari ini.
 *
 * Dihitung dari `acuan`, bukan dari daftar yang sedang tampil, supaya tab
 * kelompok bisa menampilkan sisa pekerjaan tanpa harus diklik dulu. Tanpa
 * ini mentor harus memilih tiap kelompok hanya untuk tahu mana yang masih
 * ada kerjaannya.
 */
function sisa(k: Kelompok): number {
  return acuan.value
    ? santriKelompok(acuan.value, k.id).filter(s => !sudah(s)).length
    : 0
}

/** Sisa kelompok yang sedang dipilih, untuk judul daftar Santri. */
const sisaAktif = computed(() =>
  (anggota.value.length ? anggota.value.filter(s => !sudah(s)).length : 0))

const kurangStok = computed(() =>
  tingkat.value === 'BK2' && acuan.value
    ? tipeKurangStok(acuan.value.soal, PER_TIPE_BK2)
    : [])

onMounted(async () => {
  await muat()
  adaKemajuan.value = pulihkan()

  // Kelompok terakhir yang dipakai membawa kelasnya sendiri: itu sebabnya
  // hanya satu kunci yang disimpan, dan dua pilihan tidak bisa bertentangan.
  // Kelompok di luar tugas (mis. tugas baru diatur) tidak dipulihkan.
  const terakhir = kelompokBoleh.value
    .find(k => k.id === Number(localStorage.getItem(KUNCI_TERAKHIR)))
  const kelasTerakhir = terakhir && isTingkat(terakhir.tingkat) ? terakhir.tingkat : null

  tingkat.value = kelasTerakhir ?? kelasTersedia.value[0] ?? 'BK1'
  // Kalau kelas kelompok terakhir tidak sama dengan kelas terpilih (mis.
  // kelasnya sudah diubah admin), kelompok itu TIDAK dipertahankan: itu akan
  // menilai anak dari rombel yang berbeda dari yang tertulis di layar.
  kelompok.value = (kelasTerakhir === tingkat.value ? terakhir : null)
    ?? kelompokSatuKelas.value[0] ?? null
  await muatHadir()
})

/** Pindah kelas. Kelompok ikut pindah: pilihan lama hampir pasti bukan milik kelas ini. */
function pilihKelas(t: Tingkat) {
  tingkat.value = t
  pilihKelompok(kelompokSatuKelas.value[0] ?? null)
}

function pilihKelompok(k: Kelompok | null) {
  kelompok.value = k
  if (k) localStorage.setItem(KUNCI_TERAKHIR, String(k.id))
  void muatHadir()
}

/** Absen kelompok terpilih hari ini. Offline = map kosong, tidak menghalangi. */
async function muatHadir() {
  hadir.value = new Map()
  if (!kelompok.value || !navigator.onLine) return
  try {
    hadir.value = await ambilHadirHariIni(sb, kelompok.value.id, hariIni())
  }
  catch { /* offline / RLS: biarkan kosong, absen tetap bisa diketuk */ }
}

const statusAnak = (s: Santri) => hadir.value.get(s.id)?.status ?? null
const kendalaAnak = (s: Santri) => hadir.value.get(s.id)?.kendala ?? null

/**
 * Satu ketuk absen. Langsung terlihat (optimis) + masuk antrean offline.
 * Hadir = default implisit: anak yang dinilai tanpa diketuk absennya tetap
 * tercatat hadir saat sesi nilai ditutup (lihat useSesi.tutupSoal).
 */
function tandaiHadir(s: Santri, status: StatusHadir) {
  hadir.value.set(s.id, { status, kendala: hadir.value.get(s.id)?.kendala ?? null })
  $antrean.tambahHadir({
    tanggal: hariIni(), santri_id: s.id, status,
    ...(kelompok.value ? { kelompok_id: kelompok.value.id } : {}),
    ...(hadir.value.get(s.id)?.kendala ? { kendala: hadir.value.get(s.id)!.kendala } : {}),
  })
  toast.success(`${s.nama}: ${LABEL_STATUS[status]}.`)
}

/**
 * Catat kendala teks bebas per anak. Grain absen adalah (tanggal, santri)
 * dan `catat_hadir` wajib membawa status, jadi kendala selalu menumpang pada
 * status yang sudah ada — atau 'hadir' bila belum diketuk sama sekali.
 * Kosongkan untuk menghapus. Masuk antrean offline yang sama seperti absen.
 *
 * ponytail: `prompt` bawaan browser sengaja dipakai (1 baris, konsisten
 * dengan `confirm` di `jalan`). Upgrade path ke bottom-sheet bila musrif
 * butuh melihat riwayat kendala saat mengetik.
 */
function simpanKendala(s: Santri) {
  const isi = prompt(`Kendala ${s.nama} (kosongkan untuk hapus):`, kendalaAnak(s) ?? '')
  if (isi === null) return
  const kendala = isi.trim() || null
  const kini = statusAnak(s)
  const status: StatusHadir = isStatusHadir(kini) ? kini : 'hadir'
  hadir.value.set(s.id, { status, kendala })
  $antrean.tambahHadir({
    tanggal: hariIni(), santri_id: s.id, status,
    ...(kelompok.value ? { kelompok_id: kelompok.value.id } : {}),
    ...(kendala ? { kendala } : {}),
  })
  toast.success(kendala ? `Kendala ${s.nama} dicatat.` : `Kendala ${s.nama} dihapus.`)
}

function jalan(santri: Santri) {
  if (sudah(santri)
    && !confirm(`${santri.nama} sudah dinilai hari ini. Mulai ulang akan menimpa nilainya. Lanjut?`)) return
  mulai(santri, tingkat.value, mode.value, kelompok.value)
  navigateTo('/nilai')
}
</script>

<template>
  <div>
    <!-- Header -->
    <div class="section-header">
      <div>
        <h1 style="margin: 0">Sorogan</h1>
        <p class="subtitle" style="margin: 2px 0 0">{{ ustadz?.nama }}</p>
      </div>
      <!-- Desktop punya "Keluar" di sidebar; di HP sidebar tidak tampil. -->
      <button class="kecil hanya-hp" @click="keluar">Keluar</button>
    </div>

    <p v-if="galat" class="galat">{{ galat }}</p>

    <!-- Resume Session -->
    <div v-if="adaKemajuan" class="kartu" style="border-left: 3px solid var(--warning); margin-bottom: var(--space-4)">
      <p style="margin: 0; font-weight: 600; font-size: var(--text-sm)">Ada sesi yang belum selesai</p>
      <p class="text-muted text-xs" style="margin: 4px 0 var(--space-3)">Melanjutkan menjaga penomoran soal tetap benar.</p>
      <button class="utama" @click="navigateTo('/nilai')">Lanjutkan</button>
    </div>

    <!-- Satu keputusan, bukan tiga section: kelas + kelompok + keperluan
         dipilih berurutan sebelum ada santri yang bisa dinilai.
         Urutannya KELAS dulu, baru kelompok: tiap kelas punya kelompok 1, 2, 3
         sendiri, jadi daftar kelompok yang tidak disaring kelasnya akan
         memuat beberapa "Kelompok 1" yang berbeda tanpa cara membedakannya. -->
    <div class="kartu pilih">
      <div class="pilih-baris">
        <div class="pilih-grup">
          <span class="pilih-label" id="lbl-kelas">Kelas</span>
          <div v-if="!acuan" class="text-muted text-sm">Memuat...</div>
          <div v-else-if="!kelasTersedia.length" class="text-muted text-sm">
            Belum ada satu pun kelompok. Tambahkan di Kelola Kelompok.
          </div>
          <div v-else class="tabs" role="group" aria-labelledby="lbl-kelas">
            <button
              v-for="t in kelasTersedia" :key="t"
              class="tab" :class="{ active: tingkat === t }"
              :aria-pressed="tingkat === t"
              @click="pilihKelas(t)"
            >
              {{ LABEL_TINGKAT[t] }}
            </button>
          </div>
        </div>

        <div class="pilih-grup pilih-grup-luas">
          <span class="pilih-label" id="lbl-kelompok">Kelompok</span>
          <div v-if="!acuan" class="text-muted text-sm">Memuat...</div>
          <div v-else-if="!kelompokSatuKelas.length" class="text-muted text-sm">
            {{ LABEL_TINGKAT[tingkat] }} belum punya kelompok.
          </div>
          <div v-else class="tabs" role="group" aria-labelledby="lbl-kelompok">
            <button
              v-for="k in kelompokSatuKelas" :key="k.id"
              class="tab" :class="{ active: kelompok?.id === k.id }"
              :aria-pressed="kelompok?.id === k.id"
              @click="pilihKelompok(k)"
            >
              {{ k.nama }}
              <!-- Sisa yang belum dinilai hari ini. Tanpa ini mentor tidak
                   tahu kelompok mana yang masih ada kerjaannya. -->
              <span v-if="sisa(k) > 0" class="tab-sisa">{{ sisa(k) }}</span>
            </button>
          </div>
        </div>

        <div class="pilih-grup">
          <span class="pilih-label" id="lbl-keperluan">Keperluan</span>
          <div class="tabs" role="group" aria-labelledby="lbl-keperluan">
            <button
              v-for="m in MODE" :key="m"
              class="tab" :class="{ active: mode === m }"
              :aria-pressed="mode === m"
              @click="mode = m"
            >
              {{ LABEL_MODE[m] }}
            </button>
          </div>
        </div>
      </div>

      <p v-if="kurangStok.length" class="galat" style="margin: var(--space-3) 0 0">
        Bank soal kurang untuk tipe: {{ kurangStok.join(', ') }}.
      </p>

      <!-- Kelompok yang kelasnya belum diatur tidak bisa dinilai -- format
           ujiannya ditentukan kelas. Disebutkan supaya anggotanya tidak
           seolah-olah hilang, bukan dibiarkan dicari sendiri. -->
      <p v-if="tanpaKelas.length" class="galat" style="margin: var(--space-2) 0 0">
        {{ tanpaKelas.map(k => k.nama).join(', ') }} belum punya kelas, jadi tidak muncul
        di kelas mana pun. Atur di Kelola Kelompok.
      </p>
    </div>

    <!-- Santri List -->
    <div class="section">
      <div class="section-header">
        <h2 class="section-title">Santri</h2>
        <Badge
          v-if="anggota.length"
          :variant="jmlSudah === anggota.length ? 'success' : 'primary'"
          :label="jmlSudah === anggota.length
            ? 'Kelompok selesai hari ini'
            : `${jmlSudah}/${anggota.length} · sisa ${sisaAktif}`"
        />
      </div>

      <div v-if="acuan && !anggota.length" class="text-muted text-sm">Kelompok ini belum berisi santri.</div>
      <div v-else-if="sisaAktif === 0" class="kartu-flat text-sm text-success" style="margin-bottom: var(--space-3)">
        Semua santri di kelompok ini sudah dinilai hari ini.
      </div>

      <!-- Baris santri: ketuk nama = nilai; ketuk status = absen.
           Absen terpisah dari tombol nilai supaya anak izin/sakit/alpa bisa
           dicatat tanpa membuka sesi penilaian. -->
      <div v-for="s in anggota" :key="s.id" class="kartu" style="padding: 0; overflow: hidden">
        <div class="list-item" :style="sudah(s) ? 'opacity: 0.6' : ''">
          <button type="button" class="list-item" style="flex: 1; border: none; background: none; padding: 0; text-align: left" @click="jalan(s)">
            <Avatar :name="s.nama" />
            <div class="list-item-content">
              <div class="list-item-title">{{ s.nama }}</div>
              <div class="list-item-sub">
                <Badge v-if="sudah(s)" variant="success" label="Selesai" />
                <span v-else class="text-muted text-xs">{{ jmlSoal }} soal</span>
                <span v-if="s.semester != null" class="text-muted text-xs"> · Smt {{ s.semester }}</span>
                <!-- Kendala hari ini ikut terlihat di daftar: musrif tahu mana
                     yang kemarin bermasalah tanpa membuka satu per satu. -->
                <span v-if="kendalaAnak(s)" class="text-muted text-xs" style="display: block">⚠ {{ kendalaAnak(s) }}</span>
              </div>
            </div>
          </button>
          <div style="display: flex; gap: 4px; padding-right: 8px" role="group" :aria-label="`Absen ${s.nama}`">
            <button
              v-for="st in STATUS_HADIR" :key="st" type="button"
              class="absen" :class="{ aktif: statusAnak(s) === st, [st]: true }"
              :aria-pressed="statusAnak(s) === st"
              :title="LABEL_STATUS[st]"
              @click="tandaiHadir(s, st)"
            >{{ LABEL_STATUS[st][0] }}</button>
            <!-- Kendala: satu ketuk untuk catat teks bebas. Aktif berisi bila
                 hari ini ada kendalanya — tanpa ini kendala hanya bisa dibaca
                 (dari server) tapi tidak pernah ditulis dari layar ini. -->
            <button
              type="button"
              class="absen" :class="{ aktif: !!kendalaAnak(s) }"
              :title="kendalaAnak(s) ? `Kendala: ${kendalaAnak(s)}` : 'Catat kendala'"
              @click="simpanKendala(s)"
            >⚠</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Pemilih kelompok/tingkat/keperluan: satu kartu, bukan tiga section.
   Di desktop bertumpuk horizontal supaya daftar Santri langsung terlihat di
   bawahnya; di HP tetap satu kolom karena labelnya yang penting, bukan
   hemat tinggi. */
.pilih-baris {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--space-4);
  align-items: start;
}
@media (min-width: 900px) {
  /* Kelompok dapat kolom terlebar: itulah satu-satunya daftar yang boleh
     panjang (satu tab per rombel di kelas itu). Kelas dapat minmax dengan
     minimum kontennya: persis di ambang 900px dua tab kelas butuh ~210px
     tapi kolomnya cuma dapat ~197px, jadi tanpa ini ada serpihan 14px yang
     bisa digeser. Keperluan muat dengan 1fr biasa. */
  .pilih-baris { grid-template-columns: minmax(max-content, 1fr) 2fr 1fr; }
}

.pilih-grup { min-width: 0; }
.pilih-label {
  display: block;
  font-size: var(--text-xs);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--muted);
  margin-bottom: var(--space-2);
}
/* `.tabs` bawa margin-bottom untuk berdiri sendiri sebagai section; di dalam
   kartu itu hanya jadi jarak aneh ke tepi kartu. */
.pilih-grup :deep(.tabs) { margin-bottom: 0; }

/* Sisa pekerjaan per kelompok, di dalam label tab. `.tab` ada di CSS global,
   jadi di style scoped harus lewat :deep atau selektor ini tidak akan
   menyentuh elemen itu. */
.pilih-grup :deep(.tab-sisa) {
  display: inline-block;
  margin-left: 6px;
  padding: 0 6px;
  border-radius: var(--radius-full);
  background: var(--primary-light);
  color: var(--primary);
  font-size: var(--text-xs);
  font-weight: 700;
  line-height: 1.5;
}
.pilih-grup :deep(.tab.active .tab-sisa) { background: var(--primary); color: var(--teks-aksen); }

/* Tombol absen 1 huruf (H/I/S/A), min 44px sesuai R13. Yang aktif berisi,
   yang tidak hanya bergaris — supaya daftar tetap terbaca kertas. */
.absen {
  width: 44px; height: 44px; border-radius: var(--radius-full);
  font-weight: 700; font-size: .9rem; flex-shrink: 0;
  background: transparent; color: var(--muted);
}
.absen.aktif.hadir { background: var(--benar); border-color: var(--benar); color: var(--teks-aksen); }
.absen.aktif.izin { background: var(--dibantu); border-color: var(--dibantu); color: var(--teks-aksen); }
.absen.aktif.sakit { background: var(--dibantu); border-color: var(--dibantu); color: var(--teks-aksen); filter: hue-rotate(180deg); }
.absen.aktif.alpa { background: var(--salah); border-color: var(--salah); color: var(--teks-aksen); }
</style>
