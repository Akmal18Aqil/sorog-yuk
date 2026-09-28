<script setup lang="ts">
import type { Database } from '#shared/types/database'
import { ambilIbarat, tambahIbarat, ubahIbarat, hapusIbarat } from '~/utils/repo'

definePageMeta({ middleware: 'auth' })

const route = useRoute()
const kitabId = Number(route.params.kitabId)

const sb = useSupabaseClient<Database>()
const toast = useToast()

const daftar = ref<any[]>([])
const galat = ref('')
const sibuk = ref(false)
const formVisible = ref(false)
const editItem = ref<any>(null)
const hapusTarget = ref<any>(null)

const form = ref({ urutan: 0, halaman: undefined as number | undefined, teks: '' })

async function muat() {
  try { daftar.value = await ambilIbarat(sb, kitabId) }
  catch (e) { galat.value = (e as Error).message }
}

onMounted(muat)

function bukaTambah() {
  editItem.value = null
  form.value = { urutan: daftar.value.length + 1, halaman: undefined, teks: '' }
  formVisible.value = true
}

function bukaEdit(item: any) {
  editItem.value = item
  form.value = { urutan: item.urutan ?? 0, halaman: item.halaman ?? undefined, teks: item.teks }
  formVisible.value = true
}

async function simpan() {
  if (!form.value.teks.trim()) { toast.error('Teks ibarat wajib diisi.'); return }
  sibuk.value = true
  try {
    if (editItem.value) {
      await ubahIbarat(sb, editItem.value.id, form.value)
      toast.success('Ibarat diperbarui.')
    } else {
      await tambahIbarat(sb, { kitab_id: kitabId, ...form.value })
      toast.success('Ibarat ditambahkan.')
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
    await hapusIbarat(sb, hapusTarget.value.id)
    toast.success('Ibarat dihapus.')
    hapusTarget.value = null
    await muat()
  } catch (e) { toast.error((e as Error).message) }
  finally { sibuk.value = false }
}
</script>

<template>
  <div>
    <div class="page-head">
      <NuxtLink to="/admin/kitab" class="back-btn">← Kembali</NuxtLink>
      <div class="toolbar" role="group" aria-label="Tambah ibarat">
        <button class="utama btn-tambah" @click="bukaTambah">+ Tambah</button>
      </div>
    </div>
    <h1 class="page-title">Ibarat</h1>
    <p v-if="galat" class="galat">{{ galat }}</p>

    <div v-for="(ib, i) in daftar" :key="ib.id" class="kartu">
      <div style="display: flex; justify-content: space-between; align-items: flex-start">
        <div style="flex: 1; min-width: 0">
          <span class="text-muted text-sm">{{ i + 1 }}.</span>
          <span v-if="ib.halaman" class="text-muted text-xs"> p.{{ ib.halaman }}</span>
          <p class="arab" style="margin: 4px 0 0; font-size: 1.1rem">{{ ib.teks }}</p>
        </div>
        <div class="list-item-actions">
          <button class="kecil" @click="bukaEdit(ib)">Edit</button>
          <button class="kecil text-error" @click="hapusTarget = ib">Hapus</button>
        </div>
      </div>
    </div>

    <EmptyState v-if="!daftar.length" icon="📖" message="Belum ada ibarat." />

    <Teleport to="body">
      <Transition name="fade">
        <div v-if="formVisible" class="overlay" @click.self="formVisible = false">
          <div class="modal">
            <h2 style="margin: 0 0 var(--space-4)">{{ editItem ? 'Edit' : 'Tambah' }} Ibarat</h2>
            <label for="urutan">Urutan</label>
            <input id="urutan" v-model.number="form.urutan" type="number">
            <label for="halaman">Halaman</label>
            <input id="halaman" v-model.number="form.halaman" type="number">
            <label for="teks">Teks (Arab)</label>
            <textarea id="teks" v-model="form.teks" rows="4" class="arab" style="direction: rtl; text-align: right"></textarea>
            <div class="baris mt-4">
              <button style="flex: 1" @click="formVisible = false">Batal</button>
              <button class="utama" style="flex: 1" :disabled="sibuk" @click="simpan">{{ sibuk ? 'Menyimpan...' : 'Simpan' }}</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <ConfirmDialog :visible="!!hapusTarget" message="Hapus ibarat ini?" @confirm="konfirmasiHapus" @cancel="hapusTarget = null" />
  </div>
</template>
