<script setup lang="ts">
import type { Database } from '#shared/types/database'
import { TIPE_BK2 } from '#shared/types/sorogan'
import { ambilLangkah, tambahLangkah, ubahLangkah, hapusLangkah } from '~/utils/repo'

definePageMeta({ middleware: 'auth' })

const sb = useSupabaseClient<Database>()
const toast = useToast()

const daftar = ref<any[]>([])
const galat = ref('')
const sibuk = ref(false)
const formVisible = ref(false)
const editItem = ref<any>(null)
const hapusTarget = ref<any>(null)

const filterTipe = ref('')
const semuaTipe = ['lafad', ...TIPE_BK2]

const form = ref({ tipe: 'lafad', urutan: 1, pertanyaan: '', bersyarat: '', sekali_per_sesi: false })

async function muat() {
  try { daftar.value = await ambilLangkah(sb, filterTipe.value || undefined) }
  catch (e) { galat.value = (e as Error).message }
}

onMounted(muat)
watch(filterTipe, () => muat())

function bukaTambah() {
  editItem.value = null
  const maxUrutan = daftar.value.filter(l => l.tipe === (filterTipe.value || form.value.tipe)).length
  form.value = { tipe: filterTipe.value || 'lafad', urutan: maxUrutan + 1, pertanyaan: '', bersyarat: '', sekali_per_sesi: false }
  formVisible.value = true
}

function bukaEdit(item: any) {
  editItem.value = item
  form.value = { tipe: item.tipe, urutan: item.urutan, pertanyaan: item.pertanyaan, bersyarat: item.bersyarat ?? '', sekali_per_sesi: item.sekali_per_sesi }
  formVisible.value = true
}

async function simpan() {
  if (!form.value.pertanyaan.trim()) { toast.error('Pertanyaan wajib diisi.'); return }
  sibuk.value = true
  try {
    const payload = { ...form.value, bersyarat: form.value.bersyarat || undefined }
    if (editItem.value) {
      await ubahLangkah(sb, editItem.value.id, payload)
      toast.success('Langkah diperbarui.')
    } else {
      await tambahLangkah(sb, payload)
      toast.success('Langkah ditambahkan.')
    }
    formVisible.value = false
    await muat()
  } catch (e) { toast.error((e as Error).message) }
  finally { sibuk.value = false }
}

async function konfirmasiHapus() {
  if (!hapusTarget.value) return
  sibuk.value = true
  try {
    await hapusLangkah(sb, hapusTarget.value.id)
    toast.success('Langkah dihapus.')
    hapusTarget.value = null
    await muat()
  } catch (e) { toast.error((e as Error).message) }
  finally { sibuk.value = false }
}
</script>

<template>
  <div>
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--space-4)">
      <NuxtLink to="/admin" class="back-btn">← Kembali</NuxtLink>
      <button class="utama" style="width: auto; padding: 0 var(--space-4)" @click="bukaTambah">+ Tambah</button>
    </div>
    <h1 style="margin-bottom: var(--space-4)">Langkah</h1>
    <p v-if="galat" class="galat">{{ galat }}</p>

    <!-- Filter -->
    <div class="baris mb-3">
      <select v-model="filterTipe" style="flex: 1">
        <option value="">Semua Tipe</option>
        <option v-for="t in semuaTipe" :key="t" :value="t">{{ t }}</option>
      </select>
    </div>

    <div v-for="l in daftar" :key="l.id" class="kartu" style="padding: 0; overflow: hidden">
      <div class="list-item">
        <div class="list-item-content">
          <div class="list-item-title" style="font-size: var(--text-sm)">
            <Badge variant="primary" :label="l.tipe" />
            <span class="text-muted text-xs" style="margin-left: 4px">#{{ l.urutan }}</span>
            <Badge v-if="l.sekali_per_sesi" variant="warning" label="sekali/sesi" style="margin-left: 4px" />
          </div>
          <div class="list-item-sub">{{ l.pertanyaan }}</div>
          <div v-if="l.bersyarat" class="text-muted text-xs mt-1">Bersyarat: {{ l.bersyarat }}</div>
        </div>
        <div class="list-item-actions">
          <button class="kecil" @click="bukaEdit(l)">Edit</button>
          <button class="kecil text-error" @click="hapusTarget = l">Hapus</button>
        </div>
      </div>
    </div>

    <EmptyState v-if="!daftar.length" icon="📝" message="Belum ada langkah." />

    <Teleport to="body">
      <Transition name="fade">
        <div v-if="formVisible" class="overlay" @click.self="formVisible = false">
          <div class="modal">
            <h2 style="margin: 0 0 var(--space-4)">{{ editItem ? 'Edit' : 'Tambah' }} Langkah</h2>
            <label for="tipe">Tipe</label>
            <select id="tipe" v-model="form.tipe">
              <option v-for="t in semuaTipe" :key="t" :value="t">{{ t }}</option>
            </select>
            <label for="urutan">Urutan</label>
            <input id="urutan" v-model.number="form.urutan" type="number">
            <label for="pertanyaan">Pertanyaan</label>
            <textarea id="pertanyaan" v-model="form.pertanyaan" rows="3"></textarea>
            <label for="bersyarat">Bersyarat (opsional)</label>
            <input id="bersyarat" v-model="form.bersyarat" placeholder="isim, marifat, dll">
            <label style="display: flex; align-items: center; gap: var(--space-2); margin-top: var(--space-3)">
              <input v-model="form.sekali_per_sesi" type="checkbox">
              Sekali per sesi
            </label>
            <div class="baris mt-4">
              <button style="flex: 1" @click="formVisible = false">Batal</button>
              <button class="utama" style="flex: 1" :disabled="sibuk" @click="simpan">{{ sibuk ? 'Menyimpan...' : 'Simpan' }}</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <ConfirmDialog :visible="!!hapusTarget" message="Hapus langkah ini?" @confirm="konfirmasiHapus" @cancel="hapusTarget = null" />
  </div>
</template>
