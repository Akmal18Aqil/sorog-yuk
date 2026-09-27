<script setup lang="ts">
import type { Ibarat } from '#shared/types/sorogan'

defineProps<{ ibarat: Ibarat | null }>()
const emit = defineEmits<{ pilih: [kata: string]; ganti: [] }>()

const kataDari = (teks: string) => teks.split(/\s+/).filter(Boolean)
</script>

<template>
  <div class="kartu">
    <p class="redup" style="margin: 0 0 6px">Ketuk satu kata untuk dijadikan soal.</p>
    <div v-if="ibarat" class="arab ibarat">
      <!-- Spasi eksplisit: Vue membuang whitespace antar elemen v-for, sehingga
           kotak sentuh dua kata bersebelahan menempel tanpa celah sama sekali.
           Ketukan di perbatasan akan mencatat lafad yang salah. Spasi ini juga
           yang membuat teks tetap benar saat dibaca pembaca layar atau disalin. -->
      <template v-for="(kata, i) in kataDari(ibarat.teks)" :key="`${i}-${kata}`">
        <button type="button" :aria-label="`Pilih lafad ${kata}`" @click="emit('pilih', kata)">
          {{ kata }}
        </button>{{ ' ' }}
      </template>
    </div>
    <p v-else class="redup">Belum ada ibarat termuat.</p>
    <button type="button" class="penuh" style="margin-top: 8px" @click="emit('ganti')">
      Ganti ibarat
    </button>
  </div>
</template>

<style scoped>
.ibarat { font-size: 1.7rem; padding: 14px 10px; }

/* min-width bukan hiasan: kata Arab pendek seperti "دَم" hanya selebar ~27px,
   di bawah ambang target sentuh. Salah ketuk = soal yang salah tercatat. */
.ibarat button {
  background: none;
  border: none;
  border-radius: 8px;
  padding: 4px 10px;
  min-height: 0;
  min-width: 44px;
  font: inherit;
  line-height: 2.1;
}
.ibarat button:hover,
.ibarat button:focus-visible { background: var(--garis); }
</style>
