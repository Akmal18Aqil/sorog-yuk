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
    <div class="kartu" style="text-align: center; padding: var(--space-8)">
      <p style="font-size: var(--text-3xl); font-weight: 700; margin: 0; color: var(--primary)">{{ ringkasan.nilai ?? '—' }}</p>
      <p class="text-muted text-sm" style="margin: var(--space-1) 0 0">{{ ringkasan.jml }} soal dinilai</p>
    </div>
    <button class="utama" @click="navigateTo('/mulai')">Santri Berikutnya</button>
    <button class="penuh" style="margin-top: var(--space-2)" @click="navigateTo('/hasil')">Lihat Hasil & Leger</button>
  </section>

  <!-- Sesi Aktif -->
  <section v-else-if="sesi">
    <!-- Header -->
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--space-4)">
      <div>
        <h1 style="margin: 0; font-size: var(--text-lg)">{{ sesi.santri.nama }}</h1>
        <p class="text-muted text-xs" style="margin: 2px 0 0">
          {{ sesi.kelompok?.nama }} · soal {{ Math.min(sesi.ke + 1, target) }}/{{ target }}
        </p>
      </div>
      <Badge v-if="nilaiBerjalan !== null" variant="primary" :label="`Nilai: ${nilaiBerjalan}`" />
    </div>

    <!-- Selesai -->
    <div v-if="selesai" class="kartu" style="text-align: center; border-left: 3px solid var(--success)">
      <p style="font-weight: 600; margin: 0">Semua soal selesai</p>
      <p class="text-muted text-sm" style="margin: 4px 0 0">Nilai: {{ nilaiBerjalan ?? '—' }}</p>
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
        <div class="arab" style="font-size: 1.75rem; padding: var(--space-2) 0">
          <template v-for="(p, i) in potongan" :key="i">
            <mark v-if="p.sorot" class="soal-highlight">{{ p.kata }}</mark>
            <template v-else>{{ p.kata }}</template>
            {{ ' ' }}
          </template>
        </div>
        <div class="text-muted text-xs" style="margin-top: var(--space-2)">
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

    <button class="utama" style="margin-top: var(--space-4)" @click="akhiri">
      {{ selesai ? 'Selesai' : 'Sudahi Sesi Ini' }}
    </button>
  </section>
</template>

<style scoped>
.soal-highlight {
  background: var(--primary);
  color: var(--teks-aksen);
  border-radius: var(--radius-sm);
  padding: 2px 6px;
}
</style>
