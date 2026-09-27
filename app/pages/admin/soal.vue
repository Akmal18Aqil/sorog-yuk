<script setup lang="ts">
import type { Database } from '#shared/types/database'
import { TIPE_BK2, TINGKAT } from '#shared/types/sorogan'
import { ambilSoal, tambahSoal, ubahSoal, hapusSoal } from '~/utils/repo'

definePageMeta({ middleware: 'auth' })

const sb = useSupabaseClient<Database>()
const toast = useToast()

const daftar = ref<any[]>([])
const galat = ref('')
const sibuk = ref(false)
const formVisible = ref(false)
const editItem = ref<any>(null)
const hapusTarget = ref<any>(null)

const filterTingkat = ref('')
const filterTipe = ref('')

const form = ref({ ibarat_id: 0, teks: '', tipe: 'lafad', tingkat: 'BK1', nomor_bank: undefined as number | undefined })

async function muat() {
  try {
    daftar.value = await ambilSoal(sb, {
      tingkat: filterTingkat.value || undefined,
      tipe: filterTipe.value || undefined,
    })
  } catch (e) { galat.value = (e as Error).message }
}

onMounted(muat)
watch([filterTingkat, filterTipe], () => muat())

function bukaTambah() {
  editItem.value = null
  form.value = { ibarat_id: 0, teks: '', tipe: 'lafad', tingkat: 'BK1', nomor_bank: undefined }
  formVisible.value = true
}

function bukaEdit(item: any) {
  editItem.value = item
  form.value = { ibarat_id: item.ibarat_id, teks: item.teks, tipe: item.tipe, tingkat: item.tingkat, nomor_bank: item.nomor_bank ?? undefined }
  formVisible.value = true
}

async function simpan() {
  if (!form.value.teks.trim()) { toast.error('Teks soal wajib diisi.'); return }
  sibuk.value = true
  try {
    if (editItem.value) {
      await ubahSoal(sb, editItem.value.id, form.value)
      toast.success('Soal diperbarui.')
    } else {
      await tambahSoal(sb, form.value)
      toast.success('Soal ditambahkan.')
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
    await hapusSoal(sb, hapusTarget.value.id)
    toast.success('Soal dihapus.')
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
    <h1 style="margin-bottom: var(--space-4)">Soal</h1>
    <p v-if="galat" class="galat">{{ galat }}</p>

    <!-- Filters -->
    <div class="baris mb-3">
      <select v-model="filterTingkat" style="flex: 1">
        <option value="">Semua Tingkat</option>
        <option v-for="t in TINGKAT" :key="t" :value="t">{{ t }}</option>
      </select>
      <select v-model="filterTipe" style="flex: 1">
        <option value="">Semua Tipe</option>
        <option value="lafad">Lafad</option>
        <option v-for="t in TIPE_BK2" :key="t" :value="t">{{ t }}</option>
      </select>
    </div>

    <div v-for="s in daftar" :key="s.id" class="kartu" style="padding: 0; overflow: hidden">
      <div class="list-item">
        <div class="list-item-content">
          <div class="list-item-title" style="font-size: var(--text-sm)">
            <Badge variant="primary" :label="s.tingkat" />
            <Badge :label="s.tipe" style="margin-left: 4px" />
            <span v-if="s.nomor_bank" class="text-muted text-xs" style="margin-left: 4px">#{{ s.nomor_bank }}</span>
          </div>
          <div class="list-item-sub">{{ s.teks }}</div>
        </div>
        <div class="list-item-actions">
          <button class="kecil" @click="bukaEdit(s)">Edit</button>
          <button class="kecil text-error" @click="hapusTarget = s">Hapus</button>
        </div>
      </div>
    </div>

    <EmptyState v-if="!daftar.length" icon="❓" message="Belum ada soal." />

    <Teleport to="body">
      <Transition name="fade">
        <div v-if="formVisible" class="overlay" @click.self="formVisible = false">
          <div class="modal">
            <h2 style="margin: 0 0 var(--space-4)">{{ editItem ? 'Edit' : 'Tambah' }} Soal</h2>
            <label for="teks">Teks Soal</label>
            <textarea id="teks" v-model="form.teks" rows="3"></textarea>
            <label for="tipe">Tipe</label>
            <select id="tipe" v-model="form.tipe">
              <option value="lafad">Lafad</option>
              <option v-for="t in TIPE_BK2" :key="t" :value="t">{{ t }}</option>
            </select>
            <label for="tingkat">Tingkat</label>
            <select id="tingkat" v-model="form.tingkat">
              <option v-for="t in TINGKAT" :key="t" :value="t">{{ t }}</option>
            </select>
            <label for="ibarat_id">Ibarat ID</label>
            <input id="ibarat_id" v-model.number="form.ibarat_id" type="number">
            <label for="nomor_bank">Nomor Bank (opsional)</label>
            <input id="nomor_bank" v-model.number="form.nomor_bank" type="number">
            <div class="baris mt-4">
              <button style="flex: 1" @click="formVisible = false">Batal</button>
              <button class="utama" style="flex: 1" :disabled="sibuk" @click="simpan">{{ sibuk ? 'Menyimpan...' : 'Simpan' }}</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <ConfirmDialog :visible="!!hapusTarget" message="Hapus soal ini?" @confirm="konfirmasiHapus" @cancel="hapusTarget = null" />
  </div>
</template>
