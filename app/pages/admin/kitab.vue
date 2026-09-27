<script setup lang="ts">
import type { Database } from '#shared/types/database'
import { ambilKitab, tambahKitab, ubahKitab, hapusKitab } from '~/utils/repo'

definePageMeta({ middleware: 'auth' })

const sb = useSupabaseClient<Database>()
const toast = useToast()

const daftar = ref<any[]>([])
const galat = ref('')
const sibuk = ref(false)
const formVisible = ref(false)
const editItem = ref<any>(null)
const hapusTarget = ref<any>(null)

const form = ref({ nama: '', pengarang: '' })

async function muat() {
  try { daftar.value = await ambilKitab(sb) }
  catch (e) { galat.value = (e as Error).message }
}

onMounted(muat)

function bukaTambah() {
  editItem.value = null
  form.value = { nama: '', pengarang: '' }
  formVisible.value = true
}

function bukaEdit(item: any) {
  editItem.value = item
  form.value = { nama: item.nama, pengarang: item.pengarang ?? '' }
  formVisible.value = true
}

async function simpan() {
  if (!form.value.nama.trim()) { toast.error('Nama kitab wajib diisi.'); return }
  sibuk.value = true
  try {
    if (editItem.value) {
      await ubahKitab(sb, editItem.value.id, form.value.nama, form.value.pengarang || undefined)
      toast.success('Kitab diperbarui.')
    } else {
      await tambahKitab(sb, form.value.nama, form.value.pengarang || undefined)
      toast.success('Kitab ditambahkan.')
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
    await hapusKitab(sb, hapusTarget.value.id)
    toast.success('Kitab dihapus.')
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
    <h1 style="margin-bottom: var(--space-4)">Kitab</h1>
    <p v-if="galat" class="galat">{{ galat }}</p>

    <div v-for="k in daftar" :key="k.id" class="kartu" style="padding: 0; overflow: hidden">
      <div class="list-item">
        <span class="avatar">📖</span>
        <div class="list-item-content">
          <div class="list-item-title">{{ k.nama }}</div>
          <div v-if="k.pengarang" class="list-item-sub">{{ k.pengarang }}</div>
        </div>
        <div class="list-item-actions">
          <NuxtLink :to="`/admin/ibarat/${k.id}`" class="kecil" style="text-decoration: none">Ibarat</NuxtLink>
          <button class="kecil" @click="bukaEdit(k)">Edit</button>
          <button class="kecil text-error" @click="hapusTarget = k">Hapus</button>
        </div>
      </div>
    </div>

    <EmptyState v-if="!daftar.length" icon="📖" message="Belum ada kitab." />

    <Teleport to="body">
      <Transition name="fade">
        <div v-if="formVisible" class="overlay" @click.self="formVisible = false">
          <div class="modal">
            <h2 style="margin: 0 0 var(--space-4)">{{ editItem ? 'Edit' : 'Tambah' }} Kitab</h2>
            <label for="nama">Nama</label>
            <input id="nama" v-model="form.nama" placeholder="Alfiyah">
            <label for="pengarang">Pengarang</label>
            <input id="pengarang" v-model="form.pengarang" placeholder="Ibnu Malik">
            <div class="baris mt-4">
              <button style="flex: 1" @click="formVisible = false">Batal</button>
              <button class="utama" style="flex: 1" :disabled="sibuk" @click="simpan">{{ sibuk ? 'Menyimpan...' : 'Simpan' }}</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <ConfirmDialog :visible="!!hapusTarget" :message="`Hapus kitab ${hapusTarget?.nama}?`" @confirm="konfirmasiHapus" @cancel="hapusTarget = null" />
  </div>
</template>
