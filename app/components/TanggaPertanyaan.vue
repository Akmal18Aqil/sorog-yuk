<script setup lang="ts">
import { LABEL_VERDICT, VERDICT, type Langkah, type Verdict } from '#shared/types/sorogan'
import type { StatusTangga } from '#shared/domain/tangga'

const props = defineProps<{ tangga: StatusTangga; langkah: Langkah | null }>()
const emit = defineEmits<{ jawab: [v: Verdict | null]; mundur: [] }>()

/** Titik-titik kemajuan: warna verdict, abu-abu pucat untuk yang dilewati. */
const titik = computed(() => props.tangga.langkah.map((l, i) => {
  const j = props.tangga.jawaban.find(x => x.langkah_id === l.id)
  if (j) return j.verdict as string
  return i < props.tangga.posisi ? 'lewat' : 'kosong'
}))
</script>

<template>
  <div>
    <div class="titik" role="progressbar" :aria-valuenow="tangga.posisi" :aria-valuemax="tangga.langkah.length">
      <i v-for="(t, i) in titik" :key="i" :class="t" />
    </div>

    <p class="tanya">{{ langkah ? `${langkah.urutan}. ${langkah.pertanyaan}` : '' }}</p>

    <div class="verdict">
      <button
        v-for="v in VERDICT"
        :key="v"
        type="button"
        :class="v"
        @click="emit('jawab', v)"
      >
        {{ LABEL_VERDICT[v].judul }}
        <small>{{ LABEL_VERDICT[v].sub }}</small>
      </button>
    </div>

    <div class="baris" style="margin-top: 10px">
      <!-- Dilewati TIDAK menghasilkan baris jawaban — bukan nilai nol.
           Itu yang membuat langkah bersyarat tidak menghukum santri. -->
      <button type="button" style="flex: 1" @click="emit('jawab', null)">
        Lewati — tidak berlaku
      </button>
      <button type="button" style="flex: 1" :disabled="tangga.posisi === 0" @click="emit('mundur')">
        Ulangi langkah
      </button>
    </div>
  </div>
</template>

<style scoped>
.titik { display: flex; gap: 5px; margin-bottom: 14px; flex-wrap: wrap; }
.titik i { width: 22px; height: 5px; border-radius: 3px; background: var(--garis); }
.titik i.benar { background: var(--benar); }
.titik i.dibantu { background: var(--dibantu); }
.titik i.salah { background: var(--salah); }
.titik i.lewat { background: var(--redup); opacity: .35; }

.tanya { font-size: 1.3rem; font-weight: 600; margin: 18px 0 4px; min-height: 3.2rem; }

.verdict { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px; }
/* --teks-aksen, bukan #fff: di mode gelap --benar/--dibantu/--salah jadi
   terang, dan teks putih di atasnya gagal kontras. */
.verdict button { font-weight: 700; font-size: 1.05rem; min-height: 78px; color: var(--teks-aksen); }
.verdict small { display: block; font-weight: 400; font-size: .7rem; opacity: .9; }
.verdict .benar { background: var(--benar); border-color: var(--benar); }
.verdict .dibantu { background: var(--dibantu); border-color: var(--dibantu); }
.verdict .salah { background: var(--salah); border-color: var(--salah); }
</style>
