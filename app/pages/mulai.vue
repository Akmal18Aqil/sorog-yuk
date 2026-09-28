<script setup lang="ts">
import {
  JML_SOAL_BK1, MODE, PER_TIPE_BK2,
  isTingkat,
  type Kelompok, type Mode, type Santri, type Tingkat,
} from '#shared/types/sorogan'
import { tipeKurangStok } from '#shared/domain/pembagian'
import { kelasBerisiKelompok, kelompokKelas, kelompokTanpaKelas } from '#shared/domain/kelompok'
import { santriKelompok } from '~/utils/repo'

definePageMeta({ middleware: 'auth' })

// Cukup SATU kunci: kelompok sudah menentukan kelasnya sendiri, jadi
// menyimpan kelas terpisah berarti dua nilai yang bisa saling bertentangan.
const KUNCI_TERAKHIR = 'sorogan.kelompok-terakhir'

const { ustadz, keluar } = useUstadz()
const { acuan, galat, muat } = useAcuan()
const { mulai, pulihkan, selesaiHariIni } = useSesi()

const kelompok = ref<Kelompok | null>(null)
const tingkat = ref<Tingkat>('BK1')
const mode = ref<Mode>('ujian')
const adaKemajuan = ref(false)

const LABEL_TINGKAT: Record<Tingkat, string> = { BK1: 'BK 1 — lafad', BK2: 'BK 2 — tarkib' }
const LABEL_MODE: Record<Mode, string> = { ujian: 'Ujian', harian: 'Sorogan harian' }

// ——— kelas dan kelompoknya ———
// Kelas yang boleh dipilih hanya yang punya kelompok; kelompok yang tampil
// hanya milik kelas terpilih. Aturannya di shared/domain, bukan di sini.
const semuaKelompok = computed<Kelompok[]>(() => acuan.value?.kelompok ?? [])
const kelasTersedia = computed<Tingkat[]>(() => kelasBerisiKelompok(semuaKelompok.value))
const kelompokSatuKelas = computed<Kelompok[]>(() =>
  kelompokKelas(semuaKelompok.value, tingkat.value))
const tanpaKelas = computed<Kelompok[]>(() => kelompokTanpaKelas(semuaKelompok.value))

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
  const terakhir = semuaKelompok.value
    .find(k => k.id === Number(localStorage.getItem(KUNCI_TERAKHIR)))
  const kelasTerakhir = terakhir && isTingkat(terakhir.tingkat) ? terakhir.tingkat : null

  tingkat.value = kelasTerakhir ?? kelasTersedia.value[0] ?? 'BK1'
  // Kalau kelas kelompok terakhir tidak sama dengan kelas terpilih (mis.
  // kelasnya sudah diubah admin), kelompok itu TIDAK dipertahankan: itu akan
  // menilai anak dari rombel yang berbeda dari yang tertulis di layar.
  kelompok.value = (kelasTerakhir === tingkat.value ? terakhir : null)
    ?? kelompokSatuKelas.value[0] ?? null
})

/** Pindah kelas. Kelompok ikut pindah: pilihan lama hampir pasti bukan milik kelas ini. */
function pilihKelas(t: Tingkat) {
  tingkat.value = t
  pilihKelompok(kelompokSatuKelas.value[0] ?? null)
}

function pilihKelompok(k: Kelompok | null) {
  kelompok.value = k
  if (k) localStorage.setItem(KUNCI_TERAKHIR, String(k.id))
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
        <h1 style="margin: 0">Mulai</h1>
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

      <div v-for="s in anggota" :key="s.id" class="kartu" style="padding: 0; overflow: hidden">
        <button type="button" class="list-item" :style="sudah(s) ? 'opacity: 0.6' : ''" @click="jalan(s)">
          <Avatar :name="s.nama" />
          <div class="list-item-content">
            <div class="list-item-title">{{ s.nama }}</div>
            <div class="list-item-sub">
              <Badge v-if="sudah(s)" variant="success" label="Selesai" />
              <span v-else class="text-muted text-xs">{{ jmlSoal }} soal</span>
            </div>
          </div>
        </button>
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
</style>
