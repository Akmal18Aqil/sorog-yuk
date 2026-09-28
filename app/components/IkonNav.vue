<script setup lang="ts">
/**
 * Ikon navigasi — SVG garis bawaan, tanpa dependensi ikon dan tanpa emoji.
 * Emoji beda bentuk tiap HP (DESAIN.md §10); satu komponen ini dipakai
 * BottomNav (HP) dan Sidebar (desktop) supaya bentuknya selalu sama.
 */
defineProps<{ nama: string }>()

const JALUR: Record<string, string> = {
  beranda: 'M3 10.5 12 3l9 7.5M5 9.5V21h5v-6h4v6h5V9.5',
  user: 'M12 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21c0-4 3.6-6 8-6s8 2 8 6',
  kelas: 'M12 3l9 5-9 5-9-5 9-5zM3 13l9 5 9-5',
  kuliah: 'M12 4 2 9l10 5 10-5-10-5zM6 11.5V16c0 1.5 2.7 3 6 3s6-1.5 6-3v-4.5M22 9v5',
  kelompok: 'M9 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7zM2.5 20c0-3.5 3-5.5 6.5-5.5s6.5 2 6.5 5.5M16 4.6a2.5 2.5 0 0 1 0 4.8M17.5 14.7c2.4.7 4 2.2 4 5.3',
  kitab: 'M4 5.5A2.5 2.5 0 0 1 6.5 3H20v15H6.5A2.5 2.5 0 0 0 4 20.5V5.5zM4 20.5A2.5 2.5 0 0 1 6.5 18H20',
  laporan: 'M7 3h7l4 4v14H7V3zM14 3v4h4M10 12h5M10 16h5',
  soal: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM9.5 9.5a2.5 2.5 0 1 1 3.6 2.2c-.8.4-1.1.8-1.1 1.8M12 17h.01',
  langkah: 'M4 6h16M4 12h16M4 18h10',
  sorogan: 'M12 3a3 3 0 0 1 3 3v5a3 3 0 0 1-6 0V6a3 3 0 0 1 3-3zM6 11a6 6 0 0 0 12 0M12 17v4',
  hasil: 'M5 20v-6M11 20V5M17 20v-9M3 20h18',
  kenaikan: 'M3 17l6-6 4 4 8-8M15 7h6v6',
}
</script>

<template>
  <svg
    width="22" height="22" viewBox="0 0 24 24" fill="none"
    stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"
    aria-hidden="true"
  >
    <path :d="JALUR[nama] ?? JALUR.beranda" />
  </svg>
</template>
