<script setup lang="ts">
import type { Database } from '#shared/types/database'
import { ambilKelompok, tambahKelompok, ubahKelompok, hapusKelompok, ambilSemuaSantri, tambahAnggotaKelompok, hapusAnggotaKelompok, ambilKelas } from '~/utils/repo'

definePageMeta({ middleware: 'auth' })

const sb = useSupabaseClient<Database>()
const toast = useToast()

const daftar = ref<any[]>([])
const semuaSantri = ref<{ id: number; nama: string; tingkat: string; kode: string }[]>([])
// Kelas sorogan (BK1..BK3) untuk dipilih sebagai "kelompok ini melayani kelas apa".
// Dibaca dari master data `kelas`, bukan ditulis manual di sini: kalau daftar
// kelas berubah, daftar ini ikut berubah tanpa disentuh.
const daftarKelas = ref<{ kode: string; nama: string }[]>([])
const galat = ref('')
const sibuk = ref(false)
const formVisible = ref(false)
const editItem = ref<any>(null)
const hapusTarget = ref<any>(null)
const anggotaTarget = ref<any>(null)

const form = ref({ nama: '', urutan: null as number | null, tingkat: '' as string | null })

/**
 * Urutan berikutnya DALAM kelas yang dipilih, bukan dalam seluruh daftar.
 * Tiap kelas punya kelompok 1, 2, 3 sendiri, jadi BK2 yang baru dimulai
 * seharusnya mengusulkan 1, bukan 5 karena sudah ada 4 kelompok BK1.
 * Tanpa ini, urutan BK2 selalu ganjil dan harus diperbaiki manual.
 */
const urutanBerikutKelas = computed(() =>
  daftar.value
    .filter(k => (k.tingkat ?? null) === (form.value.tingkat ?? null))
    .reduce((m, k) => Math.max(m, Number(k.urutan) || 0), 0) + 1)

// Ikut kelas yang dipilih di form: mengganti kelas mereset default urutan.
watch(() => form.value.tingkat, () => {
  if (!editItem.value) form.value.urutan = urutanBerikutKelas.value
})

async function muat() {
  try {
    const [k, s, kl] = await Promise.all([ambilKelompok(sb), ambilSemuaSantri(sb), ambilKelas(sb)])
    daftar.value = k
    semuaSantri.value = s as any
    daftarKelas.value = kl as any
  } catch (e) { galat.value = (e as Error).message }
}

onMounted(muat)

// ——— Tampilan dikelompokkan per kelas ———
// Daftar mentah cuma urut `urutan` global, jadi "Kelompok 1 BK2" bisa muncul
// di bawah "Kelompok 4 BK1". Itu daftar gudang, bukan daftar per kelas yang
// dipakai mentor di /mulai. Dikelompokkan di sini dengan data yang sama,
// tanpa memanggil database sekali pun lagi.
const namaKelas = computed(() =>
  new Map(daftarKelas.value.map(k => [k.kode, k.nama])))

const daftarPerKelas = computed(() => {
  const urutKelas = new Map(daftarKelas.value.map((k, i) => [k.kode, i]))
  const kunci = (tingkat: string | null | undefined) =>
    tingkat == null || tingkat === '' ? null : tingkat
  const perKelas = new Map<string | null, any[]>()
  for (const k of daftar.value) {
    const t = kunci(k.tingkat)
    if (!perKelas.has(t)) perKelas.set(t, [])
    perKelas.get(t)!.push(k)
  }
  return [...perKelas.entries()]
    // Kelas dikenal dulu, urut master; "Tanpa kelas" selalu paling bawah.
    .sort(([a], [b]) =>
      a === b ? 0 : a === null ? 1 : b === null ? -1
      : (urutKelas.get(a) ?? 9999) - (urutKelas.get(b) ?? 9999))
    .map(([tingkat, isi]) => ({
      tingkat,
      judul: tingkat === null ? 'Tanpa kelas'
        : namaKelas.value.get(tingkat) ?? tingkat,
      isi,
    }))
})

function bukaTambah() {
  editItem.value = null
  form.value = { nama: '', urutan: urutanBerikutKelas.value, tingkat: null }
  formVisible.value = true
}

function bukaEdit(item: any) {
  editItem.value = item
  form.value = { nama: item.nama, urutan: item.urutan, tingkat: item.tingkat ?? null }
  formVisible.value = true
}

async function simpan() {
  sibuk.value = true
  try {
    if (editItem.value) {
      await ubahKelompok(sb, editItem.value.id, form.value.nama, form.value.urutan ?? undefined, form.value.tingkat)
      toast.success('Kelompok diperbarui.')
    } else {
      await tambahKelompok(sb, form.value.nama, form.value.urutan ?? undefined, form.value.tingkat)
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

/**
 * Pencari. Dulu daftar ini `<select>` — dan native select tidak bisa diketik,
 * jadi dari 103 nama harus digulir sambil membaca. Pola yang sama sudah dipakai
 * di "Pilih orang" (kelola-user), jadi ini menyalin yang ada, bukan membuat
 * widget baru.
 *
 * Cocok dengan kode juga: admin sering tahu kodenya (MS-0042) sebelum namanya.
 */
const cariAnggota = ref('')

const kandidat = computed(() => {
  const q = cariAnggota.value.trim().toLowerCase()
  if (!q) return santriBelumMasuk.value
  return santriBelumMasuk.value.filter(s =>
    s.nama.toLowerCase().includes(q) || (s.kode ?? '').toLowerCase().includes(q))
})

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

    <!-- Daftar per kelas. Kelompok berkumpul dengan kelasnya sendiri (BK1
         dengan BK1, BK2 dengan BK2), persis cara mentor melihatnya di /mulai.
         Tanpa ini, "Kelompok 1 BK2" muncul di bawah "Kelompok 4 BK1" hanya
         karena urutan global -- dan dengan nama yang sama antar kelas,
         mustahil membaca mana milik siapa. -->
    <template v-for="g in daftarPerKelas" :key="g.tingkat ?? 'tanpa-kelas'">
      <div class="section-header mt-4">
        <h2 class="section-title">{{ g.judul }}</h2>
        <Badge :label="`${g.isi.length} kelompok`" />
      </div>

      <div v-for="k in g.isi" :key="k.id" class="kartu" style="padding: 0; overflow: hidden">
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
    </template>

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
              <label for="cari-anggota">Tambah Santri</label>
              <div class="search" style="margin-bottom: var(--space-2)">
                <span class="search-icon">🔍</span>
                <input
                  id="cari-anggota"
                  v-model="cariAnggota"
                  type="search"
                  autocomplete="off"
                  placeholder="Ketik nama atau kode…"
                >
              </div>
              <!-- Dua hal yang disengaja di sini:
                   - 50 pertama, bukan 103. Tanpa pencarian, 50 baris sudah
                     lebih dari yang bisa dibaca; dengan pencarian, sisanya
                     bisa dijangkau lewat mengetik.
                   - `border-color` transparan, bukan `border: none`. Aturan
                     global `button` memberi border dan background, dan
                     `.list-item:hover` memberi highlight -- yang hilang kalau
                     background ditimpa jadi `none`. Pola sama di "Pilih orang". -->
              <div v-if="kandidat.length" class="list" style="max-height: 220px; overflow-y: auto; border: 1px solid var(--border); border-radius: var(--radius-lg)">
                <button
                  v-for="s in kandidat.slice(0, 50)"
                  :key="s.id"
                  type="button"
                  class="list-item"
                  style="width: 100%; text-align: left; border-color: transparent"
                  @click="tambahAnggota(s.id)"
                >
                  <div class="list-item-content">
                    <div class="list-item-title">{{ s.nama }}</div>
                    <div class="list-item-sub">{{ s.kode }} · {{ s.tingkat }}</div>
                  </div>
                  <span class="list-item-actions">+</span>
                </button>
              </div>
              <p v-else class="redup" style="font-size: .85rem">
                Tidak ada yang cocok.
              </p>
              <p v-if="kandidat.length > 50" class="redup" style="font-size: .75rem; margin-top: 4px">
                Menampilkan 50 dari {{ kandidat.length }}. Ketik untuk mempersempit.
              </p>
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
            <label for="tingkat">Kelas yang dilayani</label>
            <select id="tingkat" v-model="form.tingkat">
              <option :value="null">— Belum ditentukan —</option>
              <option v-for="k in daftarKelas" :key="k.kode" :value="k.kode">{{ k.kode }} — {{ k.nama }}</option>
            </select>
            <p class="redup" style="font-size: .75rem; margin: 4px 0 0">
              Menentukan anak-anak kelas mana yang ditangani kelompok ini.
            </p>
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
