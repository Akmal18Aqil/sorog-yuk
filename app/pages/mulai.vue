<script setup lang="ts">
import {
  JML_SOAL_BK1, MODE, PER_TIPE_BK2, TINGKAT,
  type Kelompok, type Mode, type Santri, type Tingkat,
} from '#shared/types/sorogan'
import { tipeKurangStok } from '#shared/domain/pembagian'
import { santriKelompok } from '~/utils/repo'

definePageMeta({ middleware: 'auth' })

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

const jmlSoal = computed(() => tingkat.value === 'BK1' ? JML_SOAL_BK1 : PER_TIPE_BK2 * 4)

const anggota = computed<Santri[]>(() =>
  acuan.value && kelompok.value ? santriKelompok(acuan.value, kelompok.value.id) : [])

const sudah = (s: Santri) => selesaiHariIni.value.includes(s.id)
const jmlSudah = computed(() => anggota.value.filter(sudah).length)

const kurangStok = computed(() =>
  tingkat.value === 'BK2' && acuan.value
    ? tipeKurangStok(acuan.value.soal, PER_TIPE_BK2)
    : [])

onMounted(async () => {
  await muat()
  adaKemajuan.value = pulihkan()
  const terakhir = Number(localStorage.getItem(KUNCI_TERAKHIR))
  kelompok.value = acuan.value?.kelompok.find(k => k.id === terakhir)
    ?? acuan.value?.kelompok[0] ?? null
})

function pilihKelompok(k: Kelompok) {
  kelompok.value = k
  localStorage.setItem(KUNCI_TERAKHIR, String(k.id))
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

    <!-- Kelompok -->
    <div class="section">
      <h2 class="section-title">Kelompok</h2>
      <div v-if="!acuan" class="text-muted text-sm">Memuat...</div>
      <div v-else class="tabs">
        <button
          v-for="k in acuan.kelompok" :key="k.id"
          class="tab" :class="{ active: kelompok?.id === k.id }"
          :aria-pressed="kelompok?.id === k.id"
          @click="pilihKelompok(k)"
        >
          {{ k.nama }}
        </button>
      </div>
    </div>

    <!-- Tingkat -->
    <div class="section">
      <h2 class="section-title">Tingkat</h2>
      <div class="tabs">
        <button
          v-for="t in TINGKAT" :key="t"
          class="tab" :class="{ active: tingkat === t }"
          :aria-pressed="tingkat === t"
          @click="tingkat = t"
        >
          {{ LABEL_TINGKAT[t] }}
        </button>
      </div>
      <p v-if="kurangStok.length" class="galat" style="margin-top: calc(-1 * var(--space-2))">
        Bank soal kurang untuk tipe: {{ kurangStok.join(', ') }}.
      </p>
    </div>

    <!-- Mode -->
    <div class="section">
      <h2 class="section-title">Keperluan</h2>
      <div class="tabs">
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

    <!-- Santri List -->
    <div class="section">
      <div class="section-header">
        <h2 class="section-title">Santri</h2>
        <Badge
          v-if="anggota.length"
          :variant="jmlSudah === anggota.length ? 'success' : 'primary'"
          :label="`${jmlSudah}/${anggota.length} selesai`"
        />
      </div>

      <div v-if="acuan && !anggota.length" class="text-muted text-sm">Kelompok ini belum berisi santri.</div>

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
