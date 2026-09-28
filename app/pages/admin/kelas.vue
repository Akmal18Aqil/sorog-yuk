<script setup lang="ts">
import type { Database } from '#shared/types/database'
import { ambilKelas, tambahKelas, ubahKelas, hapusKelas } from '~/utils/repo'

definePageMeta({ middleware: 'auth' })

const sb = useSupabaseClient<Database>()
const toast = useToast()

const daftar = ref<any[]>([])
const galat = ref('')
const sibuk = ref(false)
const formVisible = ref(false)
const editItem = ref<any>(null)
const hapusTarget = ref<any>(null)

const form = ref({ kode: '', nama: '', urutan: 0, ambang_online: 70, ambang_offline: 70 })

// Kode yang sudah dipakai, ditampilkan di bawah input. Muncul dari daftar
// yang sudah dimuat, jadi tidak perlu panggilan tambahan -- dan tujuannya
// mencegah kesalahan, bukan sekadar memberi tahu setelahnya.
const kodeTerpakai = computed(() => daftar.value.map(k => k.kode as string))

// Urutan berikutnya: yang terbesar + 1, bukan jumlah baris. Kalau ada urutan
// yang bolong (mis. 1,2,5), jumlah baris menghasilkan 3 yang sudah terpakai
// dan pemakainya tidak akan mengertinya.
const urutanBerikut = computed(() =>
  daftar.value.reduce((m, k) => Math.max(m, Number(k.urutan) || 0), 0) + 1)

async function muat() {
  try { daftar.value = await ambilKelas(sb) }
  catch (e) { galat.value = (e as Error).message }
}

onMounted(muat)

function bukaTambah() {
  editItem.value = null
  form.value = { kode: '', nama: '', urutan: urutanBerikut.value, ambang_online: 70, ambang_offline: 70 }
  galat.value = ''
  formVisible.value = true
}

function bukaEdit(item: any) {
  editItem.value = item
  form.value = { kode: item.kode, nama: item.nama, urutan: item.urutan, ambang_online: item.ambang_online, ambang_offline: item.ambang_offline }
  galat.value = ''
  formVisible.value = true
}

// Galat disimpan terpisah dari toast: toast hilang dalam 3 detik, dan
// "kode sudah dipakai kelas mana" adalah informasi yang perlu dibaca pelan.
async function simpan() {
  sibuk.value = true
  galat.value = ''
  try {
    if (editItem.value) {
      await ubahKelas(sb, { id: editItem.value.id, ...form.value })
      toast.success('Kelas diperbarui.')
    } else {
      await tambahKelas(sb, form.value)
      toast.success('Kelas ditambahkan.')
    }
    formVisible.value = false
    await muat()
  } catch (e) {
    // Pesan server sudah ditulis supaya bisa dibaca (lihat 045), jadi
    // cukup ditampilkan apa adanya.
    galat.value = (e as Error).message
    toast.error(galat.value)
  }
  finally { sibuk.value = false }
}

async function konfirmasiHapus() {
  if (!hapusTarget.value) return
  sibuk.value = true
  try {
    await hapusKelas(sb, hapusTarget.value.id)
    toast.success('Kelas dihapus.')
    hapusTarget.value = null
    await muat()
  } catch (e) { toast.error((e as Error).message) }
  finally { sibuk.value = false }
}
</script>

<template>
  <div>
    <div class="page-head">
      <NuxtLink to="/admin" class="back-btn">← Kembali</NuxtLink>
      <div class="toolbar" role="group" aria-label="Tambah kelas">
        <button class="utama btn-tambah" @click="bukaTambah">+ Tambah</button>
      </div>
    </div>
    <h1 class="page-title">Kelas</h1>
    <p v-if="galat" class="galat">{{ galat }}</p>

    <div v-for="k in daftar" :key="k.id" class="kartu kartu-rapat">
      <div class="list-item">
        <span class="avatar">{{ k.kode }}</span>
        <div class="list-item-content">
          <div class="list-item-title">{{ k.nama }}</div>
          <div class="list-item-sub">
            Urutan {{ k.urutan }} · Online ≥{{ k.ambang_online }} · Offline ≥{{ k.ambang_offline }}
          </div>
        </div>
        <div class="list-item-actions">
          <button class="kecil" @click="bukaEdit(k)">Edit</button>
          <button class="kecil text-error" @click="hapusTarget = k">Hapus</button>
        </div>
      </div>
    </div>

    <EmptyState v-if="!daftar.length" icon="📚" message="Belum ada kelas." />

    <Teleport to="body">
      <Transition name="fade">
        <div v-if="formVisible" class="overlay" @click.self="formVisible = false">
          <div class="modal">
            <h2 style="margin: 0 0 var(--space-4)">{{ editItem ? 'Edit' : 'Tambah' }} Kelas</h2>
            <label for="kode">Kode</label>
            <input id="kode" v-model="form.kode" placeholder="BK3" autocapitalize="characters">
            <p class="redup" style="font-size: .75rem; margin: 4px 0 0">
              Sudah dipakai: {{ kodeTerpakai.join(', ') || '—' }}
            </p>
            <label for="nama">Nama</label>
            <input id="nama" v-model="form.nama" placeholder="Kelas 3 — Baca Kitab 3">
            <label for="urutan">Urutan</label>
            <input id="urutan" v-model.number="form.urutan" type="number">
            <p class="redup" style="font-size: .75rem; margin: 4px 0 0">
              Menentukan kelas "berikutnya" saat kenaikan, jadi harus unik.
            </p>
            <label for="amb_o">Ambang Online (nilai minimum naik kelas)</label>
            <input id="amb_o" v-model.number="form.ambang_online" type="number" min="0" max="100" step="0.5">
            <label for="amb_f">Ambang Offline (tes luring)</label>
            <input id="amb_f" v-model.number="form.ambang_offline" type="number" min="0" max="100" step="0.5">
            <p class="redup" style="font-size: .75rem; margin: 4px 0 0">
              Dua-duanya harus terlampaui. Angka 0–100.
            </p>

            <p v-if="galat" class="galat" style="margin-top: var(--space-3)">{{ galat }}</p>

            <div class="baris mt-4">
              <button style="flex: 1" @click="formVisible = false">Batal</button>
              <button class="utama" style="flex: 1" :disabled="sibuk" @click="simpan">{{ sibuk ? 'Menyimpan...' : 'Simpan' }}</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <ConfirmDialog :visible="!!hapusTarget" :message="`Hapus kelas ${hapusTarget?.kode}?`" @confirm="konfirmasiHapus" @cancel="hapusTarget = null" />
  </div>
</template>
