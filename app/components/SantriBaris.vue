<script setup lang="ts">
import type { Santri } from '#shared/types/sorogan'

defineProps<{ santri: Santri; sudah: boolean; keterangan: string }>()
defineEmits<{ pilih: [] }>()
</script>

<template>
  <button type="button" class="santri" :class="{ sudah }" @click="$emit('pilih')">
    <span class="nama">{{ santri.nama }}</span>
    <span class="tanda">{{ sudah ? '✓ sudah' : keterangan }}</span>
  </button>
</template>

<style scoped>
.santri {
  display: flex; justify-content: space-between; align-items: center;
  gap: 12px; text-align: left; width: 100%;
}
/* Nama panjang harus mengalah, bukan mendorong keterangan keluar layar. */
.nama { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.tanda { font-size: .8rem; color: var(--redup); white-space: nowrap; flex-shrink: 0; }
.santri.sudah { border-color: var(--benar); }
.santri.sudah .tanda { color: var(--benar); font-weight: 600; }
</style>
