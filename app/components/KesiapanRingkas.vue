<script setup lang="ts">
import type { Kesiapan } from '#shared/types/sorogan'

/**
 * Kepala kartu kesiapan: nama + tujuan kenaikan + dua nilai tes.
 * Diekstrak karena blok ini muncul dua kali di halaman /kenaikan (yang siap
 * dan yang belum), dan supaya tata letaknya bisa diukur tanpa melewati auth.
 */
const props = defineProps<{ baris: Kesiapan; tampilkanTujuan?: boolean }>()

const angka = (n: number | null) => n === null ? '—' : n
const tujuan = computed(() =>
  props.tampilkanTujuan && props.baris.kelas_berikut
    ? `${props.baris.kelas_kode} → ${props.baris.kelas_berikut}`
    : props.baris.kelas_kode ?? '')
</script>

<template>
  <div>
    <div class="atas">
      <b class="nama">{{ baris.nama }}</b>
      <span class="meta redup">{{ tujuan }}</span>
    </div>
    <div class="nilai">
      <span :class="baris.lolos_online ? 'lolos' : 'kurang'">
        daring {{ angka(baris.nilai_online) }} / {{ baris.ambang_online }}
      </span>
      <span :class="baris.lolos_offline ? 'lolos' : 'kurang'">
        luring {{ angka(baris.nilai_offline) }} / {{ baris.ambang_offline }}
      </span>
    </div>
  </div>
</template>

<style scoped>
.atas { display: flex; justify-content: space-between; align-items: baseline; gap: 12px; }
/* Nama panjang mengalah dengan ellipsis; tujuan kenaikan tidak boleh terdorong
   keluar layar. Pola sama dengan SantriBaris — kegagalan yang sudah terbukti. */
.nama { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.meta { flex-shrink: 0; white-space: nowrap; font-size: .85rem; }
.nilai { display: flex; gap: 14px; flex-wrap: wrap; margin-top: 6px; font-size: .85rem; }
.lolos { color: var(--benar); font-weight: 600; }
.kurang { color: var(--salah); }
</style>
