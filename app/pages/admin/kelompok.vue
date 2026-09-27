<script setup lang="ts">
import type { Database } from '#shared/types/database'
import { ambilKelompok, tambahKelompok, ubahKelompok, hapusKelompok, ambilSemuaSantri, tambahAnggotaKelompok, hapusAnggotaKelompok } from '~/utils/repo'

definePageMeta({ middleware: 'auth' })

const sb = useSupabaseClient<Database>()
const toast = useToast()

const daftar = ref<any[]>([])
const semuaSantri = ref<{ id: number; nama: string; tingkat: string }[]>([])
const galat = ref('')
const sibuk = ref(false)
const formVisible = ref(false)
const editItem = ref<any>(null)
const hapusTarget = ref<any>(null)
const anggotaTarget = ref<any>(null)

const form = ref({ nama: '', urutan: null as number | null })

async function muat() {
  try {
    const [k, s] = await Promise.all([ambilKelompok(sb), ambilSemuaSantri(sb)])
    daftar.value = k
    semuaSantri.value = s as any
  } catch (e) { galat.value = (e as Error).message }
}

onMounted(muat)

function bukaTambah() {
  editItem.value = null
  form.value = { nama: '', urutan: daftar.value.length + 1 }
  formVisible.value = true
}

function bukaEdit(item: any) {
  editItem.value = item
  form.value = { nama: item.nama, urutan: item.urutan }
  formVisible.value = true
}

async function simpan() {
  sibuk.value = true
  try {
    if (editItem.value) {
      await ubahKelompok(sb, editItem.value.id, form.value.nama, form.value.urutan ?? undefined)
      toast.success('Kelompok diperbarui.')
    } else {
      await tambahKelompok(sb, form.value.nama, form.value.urutan ?? undefined)
      toast.success('Kelompok ditambahkan.')
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
    await hapusKelompok(sb, hapusTarget.value.id)
    toast.success('Kelompok dihapus.')
    hapusTarget.value = null
    await muat()
  } catch (e) { toast.error((e as Error).message) }
  finally { sibuk.value = false }
}

function bukaAnggota(k: any) { anggotaTarget.value = k }

const anggotaIds = computed(() => {
  if (!anggotaTarget.value) return new Set<number>()
  return new Set((anggotaTarget.value.kelompok_santri ?? []).map((a: any) => a.santri_id))
})

const santriBelumMasuk = computed(() => semuaSantri.value.filter(s => !anggotaIds.value.has(s.id)))

async function tambahAnggota(santriId: number) {
  if (!anggotaTarget.value) return
  try {
    await tambahAnggotaKelompok(sb, anggotaTarget.value.id, santriId)
    toast.success('Santri ditambahkan.')
    await muat()
    anggotaTarget.value = daftar.value.find(k => k.id === anggotaTarget.value!.id)
  } catch (e) { toast.error((e as Error).message) }
}

async function hapusAnggota(santriId: number) {
  if (!anggotaTarget.value) return
  try {
    await hapusAnggotaKelompok(sb, anggotaTarget.value.id, santriId)
    toast.success('Santri dihapus dari kelompok.')
    await muat()
    anggotaTarget.value = daftar.value.find(k => k.id === anggotaTarget.value!.id)
  } catch (e) { toast.error((e as Error).message) }
}
</script>

<template>
  <div>
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--space-4)">
      <NuxtLink to="/admin" class="back-btn">← Kembali</NuxtLink>
      <button class="utama" style="width: auto; padding: 0 var(--space-4)" @click="bukaTambah">+ Tambah</button>
    </div>
    <h1 style="margin-bottom: var(--space-4)">Kelompok</h1>
    <p v-if="galat" class="galat">{{ galat }}</p>

    <div v-for="k in daftar" :key="k.id" class="kartu" style="padding: 0; overflow: hidden">
      <div class="list-item">
        <span class="avatar">👨‍👩‍👧</span>
        <div class="list-item-content">
          <div class="list-item-title">{{ k.nama }}</div>
          <div class="list-item-sub">{{ (k.kelompok_santri ?? []).length }} anggota</div>
        </div>
        <div class="list-item-actions">
          <button class="kecil" @click="bukaAnggota(k)">Anggota</button>
          <button class="kecil" @click="bukaEdit(k)">Edit</button>
          <button class="kecil text-error" @click="hapusTarget = k">Hapus</button>
        </div>
      </div>
    </div>

    <EmptyState v-if="!daftar.length" icon="👨‍👩‍👧" message="Belum ada kelompok." />

    <!-- Anggota Panel -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="anggotaTarget" class="overlay" @click.self="anggotaTarget = null">
          <div class="modal">
            <h2 style="margin: 0 0 var(--space-4)">Anggota: {{ anggotaTarget.nama }}</h2>
            <div v-if="(anggotaTarget.kelompok_santri ?? []).length" class="mb-4">
              <div v-for="a in anggotaTarget.kelompok_santri" :key="a.santri_id" class="list-item" style="padding: var(--space-2) 0; border-bottom: 1px solid var(--border)">
                <span>{{ semuaSantri.find(s => s.id === a.santri_id)?.nama ?? `#${a.santri_id}` }}</span>
                <button class="kecil text-error" @click="hapusAnggota(a.santri_id)">Hapus</button>
              </div>
            </div>
            <p v-else class="text-muted text-sm">Belum ada anggota.</p>
            <div v-if="santriBelumMasuk.length">
              <label>Tambah Santri</label>
              <select @change="(e) => { tambahAnggota(Number((e.target as HTMLSelectElement).value)); (e.target as HTMLSelectElement).value = '' }">
                <option value="">-- Pilih --</option>
                <option v-for="s in santriBelumMasuk" :key="s.id" :value="s.id">{{ s.nama }} ({{ s.tingkat }})</option>
              </select>
            </div>
            <button class="penuh mt-4" @click="anggotaTarget = null">Tutup</button>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- Form Modal -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="formVisible" class="overlay" @click.self="formVisible = false">
          <div class="modal">
            <h2 style="margin: 0 0 var(--space-4)">{{ editItem ? 'Edit' : 'Tambah' }} Kelompok</h2>
            <label for="nama">Nama</label>
            <input id="nama" v-model="form.nama" placeholder="Kelompok A">
            <label for="urutan">Urutan</label>
            <input id="urutan" v-model.number="form.urutan" type="number">
            <div class="baris mt-4">
              <button style="flex: 1" @click="formVisible = false">Batal</button>
              <button class="utama" style="flex: 1" :disabled="sibuk" @click="simpan">{{ sibuk ? 'Menyimpan...' : 'Simpan' }}</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <ConfirmDialog :visible="!!hapusTarget" :message="`Hapus kelompok ${hapusTarget?.nama}?`" @confirm="konfirmasiHapus" @cancel="hapusTarget = null" />
  </div>
</template>
