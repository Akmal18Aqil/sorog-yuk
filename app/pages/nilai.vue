<script setup lang="ts">
import { LABEL_TIPE } from '#shared/types/sorogan'

definePageMeta({ middleware: 'auth' })

const {
  sesi, ibaratKini, target, selesai, langkahSekarang, nilaiBerjalan,
  gantiIbarat, pilihLafad, jawabLangkah, mundurLangkah, sudahi,
} = useSesi()

const ringkasan = ref<{ nama: string; jml: number; nilai: number | null } | null>(null)

onMounted(() => { if (!sesi.value) navigateTo('/mulai') })

const potongan = computed(() => {
  const s = sesi.value?.soal
  if (!s) return []
  return s.teks.split(/\s+/).filter(Boolean).map(kata => ({ kata, sorot: kata === s.lafad }))
})

function akhiri() {
  ringkasan.value = sudahi()
}
</script>

<template>
  <!-- Ringkasan -->
  <section v-if="ringkasan">
    <div class="kartu text-center py-8">
      <p class="angka">{{ ringkasan.nilai ?? '—' }}</p>
      <p class="text-muted text-sm rapat mt-1">{{ ringkasan.jml }} soal dinilai</p>
    </div>
    <button class="utama" @click="navigateTo('/mulai')">Santri Berikutnya</button>
    <button class="penuh mt-2" @click="navigateTo('/hasil')">Lihat Hasil & Leger</button>
  </section>

  <!-- Sesi Aktif -->
  <section v-else-if="sesi">
    <!-- Header -->
    <div class="page-head">
      <div>
        <h1 class="page-title">{{ sesi.santri.nama }}</h1>
        <p class="text-muted text-xs page-sub">
          {{ sesi.kelompok?.nama }} · soal {{ Math.min(sesi.ke + 1, target) }}/{{ target }}
        </p>
      </div>
      <Badge v-if="nilaiBerjalan !== null" variant="primary" :label="`Nilai: ${nilaiBerjalan}`" />
    </div>

    <!-- Selesai -->
    <div v-if="selesai" class="kartu kartu-sukses text-center">
      <p class="tegas">Semua soal selesai</p>
      <p class="text-muted text-sm rapat mt-1">Nilai: {{ nilaiBerjalan ?? '—' }}</p>
    </div>

    <!-- BK1: KetukKata -->
    <KetukKata
      v-else-if="!sesi.soal"
      :ibarat="ibaratKini"
      @pilih="pilihLafad"
      @ganti="gantiIbarat"
    />

    <!-- BK2: Soal + Tangga -->
    <template v-else>
      <div class="kartu">
        <div class="arab soal-teks">
          <template v-for="(p, i) in potongan" :key="i">
            <mark v-if="p.sorot" class="soal-highlight">{{ p.kata }}</mark>
            <template v-else>{{ p.kata }}</template>
            {{ ' ' }}
          </template>
        </div>
        <div class="text-muted text-xs mt-2">
          <template v-if="sesi.soal.nomorBank">
            Soal #{{ sesi.soal.nomorBank }} · {{ LABEL_TIPE[sesi.soal.tipe] }}
          </template>
          <template v-else>
            Lafad · {{ sesi.tangga?.langkah.length }} pertanyaan
          </template>
        </div>
      </div>

      <TanggaPertanyaan
        v-if="sesi.tangga"
        :tangga="sesi.tangga"
        :langkah="langkahSekarang"
        @jawab="jawabLangkah"
        @mundur="mundurLangkah"
      />
    </template>

    <button class="utama mt-4" @click="akhiri">
      {{ selesai ? 'Selesai' : 'Sudahi Sesi Ini' }}
    </button>
  </section>
</template>

<style scoped>
.soal-teks { font-size: 1.75rem; padding: var(--space-2) 0; }
.soal-highlight {
  background: var(--primary);
  color: var(--teks-aksen);
  border-radius: var(--radius-sm);
  padding: 2px 6px;
}
</style>
