<script setup lang="ts">
const { $antrean } = useNuxtApp()
</script>

<template>
  <div v-if="$antrean.jumlah > 0 || $antrean.macet.length > 0" class="bilah-antrean nocetak">
    <template v-if="$antrean.jumlah > 0">
      {{ $antrean.jumlah }} penilaian belum terkirim — tersimpan aman di perangkat ini,
      jangan hapus data browser.
    </template>
    <span v-if="$antrean.macet.length > 0" class="macet">
      {{ $antrean.macet.length }} penilaian macet dan perlu diperiksa.
    </span>
  </div>
</template>

<style scoped>
.bilah-antrean {
  position: fixed; left: 0; right: 0; bottom: 0;
  padding: 9px 16px; font-size: .8rem; text-align: center;
  background: var(--dibantu); color: #000;
}
.macet { display: block; font-weight: 700; }
</style>
