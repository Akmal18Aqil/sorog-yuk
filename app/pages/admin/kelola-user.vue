<script setup lang="ts">
import type { Database, JenisAkun } from '#shared/types/database'
import {
  type UstadzAdmin, type SantriAdmin,
  ambilSemuaUstadz, ambilSemuaSantri, ambilKelompok,
  ubahUstadz, hapusUstadz, ubahSantri, hapusSantri, tambahUstadz,
  setAktifUstadz, setAktifSantri,
  buatAkun, tautkanAkun, lepasAkun,
} from '~/utils/repo'

definePageMeta({ middleware: 'auth' })

const sb = useSupabaseClient<Database>()
const toast = useToast()

const tab = ref<'ustadz' | 'santri'>('ustadz')
const daftarUstadz = ref<UstadzAdmin[]>([])
const daftarSantri = ref<SantriAdmin[]>([])
const galat = ref('')
const sibuk = ref(false)
const search = ref('')

// Form tambah
const formVisible = ref(false)
const formRole = ref<'ustadz' | 'santri'>('ustadz')
// Email + kata sandi untuk AKUN, bukan untuk baris. Barisnya sudah ada
// (144 mahasantri); yang belum ada hanya akunnya.
const form = ref({ email: '', password: '' })

// Form edit
const editVisible = ref(false)
const editItem = ref<any>(null)
const editRole = ref<'ustadz' | 'santri'>('ustadz')
const editForm = ref({ nama: '', tingkat: '' })

const hapusTarget = ref<{ type: 'ustadz' | 'santri'; item: any } | null>(null)

// D1: nonaktifkan, jangan hapus. Nonaktif disembunyikan dari daftar (toggle
// di bawah), riwayat nilainya tetap utuh.
const tampilkanNonaktif = ref(false)

const aktifTarget = ref<{ type: 'ustadz' | 'santri'; item: any } | null>(null)

// Lepas: `auth_id` jadi NULL, akun auth-nya sendiri tidak dihapus.
const lepasTarget = ref<{ type: JenisAkun; item: any } | null>(null)

async function muat() {
  try {
    // Kelas ikut diambil: opsi filter "per kelas" tidak bisa menebak
    // daftar kelas dari dataBoard yang sudah dimuat.
    const [u, s, k] = await Promise.all([
      ambilSemuaUstadz(sb), ambilSemuaSantri(sb), ambilKelompok(sb),
    ])
    daftarUstadz.value = u
    daftarSantri.value = s as SantriAdmin[]
    kelasSorogan.value = (k as { id: number, nama: string }[])
      .filter(x => x.nama)
      .sort((a, b) => a.nama.localeCompare(b.nama, 'id'))
  }
  catch (e) { galat.value = (e as Error).message }
}

onMounted(muat)

//
// Satu daftar, satu definisi "apa yang sedang dilihat" -- jadi angka di
// tab dan isi tabel tidak bisa berbeda.
//
// 0 = semua pada filter angka. Dipakai untuk "belum ada semester" maupun
// "belum ada kelas" -- ID kelompok yang bisa saja 0 jadi tidak bentrok.
const fSemester = ref(0)
const fKelas = ref(0)
const fAkun = ref<'semua' | 'ada' | 'belum'>('semua')
const kelasSorogan = ref<{ id: number, nama: string }[]>([])
const urutanUstadz = ref<'nama' | 'kode'>('nama')
const urutanSantri = ref<'nama' | 'semester' | 'kelas' | 'akun'>('nama')
const arahSemester = ref<'naik' | 'turun'>('naik')

/** Bandingkan nilai opsional. `null` selalu paling akhir, naik maupun turun. */
function bandingNilai(a: string | number | null, b: string | number | null, turun = false) {
  const ka = a == null, kb = b == null
  if (ka && kb) return 0
  // null tidak pernah "lebih besar": ia selalu paling akhir, supaya
  // "semester 1" tidak pernah tercampur dengan yang belum diisi.
  if (ka) return 1
  if (kb) return -1
  if (a === b) return 0
  return (a! < b! ? -1 : 1) * (turun ? -1 : 1)
}

const namaUrut = (a: { nama: string }, b: { nama: string }) =>
  a.nama.localeCompare(b.nama, 'id')

const bolehUstadz = (u: UstadzAdmin) => {
  if (!tampilkanNonaktif.value && !u.aktif) return false
  if (fAkun.value === 'ada' && !u.auth_id) return false
  if (fAkun.value === 'belum' && u.auth_id) return false
  const q = search.value.trim().toLowerCase()
  if (!q) return true
  return u.nama.toLowerCase().includes(q) || (u.kode ?? '').toLowerCase().includes(q)
}

const bolehSantri = (s: SantriAdmin) => {
  if (!tampilkanNonaktif.value && !s.aktif) return false
  if (fSemester.value && (s.semester ?? 0) !== fSemester.value) return false
  if (fKelas.value && (s.kelas_id ?? 0) !== fKelas.value) return false
  if (fAkun.value === 'ada' && !s.auth_id) return false
  if (fAkun.value === 'belum' && s.auth_id) return false
  const q = search.value.trim().toLowerCase()
  if (!q) return true
  return s.nama.toLowerCase().includes(q) || s.kode.toLowerCase().includes(q)
}

const daftarUstadzTampil = computed(() => {
  const arr = daftarUstadz.value.filter(bolehUstadz)
  if (urutanUstadz.value === 'kode') arr.sort((a, b) => (a.kode ?? '').localeCompare(b.kode ?? '', 'id'))
  else arr.sort(namaUrut)
  return arr
})

const daftarSantriTampil = computed(() => {
  const arr = daftarSantri.value.filter(bolehSantri)
  switch (urutanSantri.value) {
    case 'semester':
      arr.sort((a, b) => bandingNilai(a.semester, b.semester, arahSemester.value === 'turun'))
      break
    case 'kelas':
      // "belum ada kelas" tetap di akhir walau arahnya turun -- yang
      // belum itu belum, bukan "lebih besar".
      arr.sort((a, b) => {
        const x = a.kelas_sorogan, y = b.kelas_sorogan
        if (x == null || y == null) return bandingNilai(x, y)
        return x.localeCompare(y, 'id')
      })
      break
    case 'akun':
      // Tanpa akun dulu: itu antrean yang paling perlu dikerjakan.
      arr.sort((a, b) => {
        const aa = a.auth_id ? 1 : 0, ab = b.auth_id ? 1 : 0
        return aa !== ab ? aa - ab : namaUrut(a, b)
      })
      break
    default:
      arr.sort(namaUrut)
  }
  return arr
})

// Yang sedang ditampilkan. Dipisah dua, bukan satu `computed` gabungan:
// gabungan jadi union `UstadzAdmin | SantriAdmin`, dan di dalam `v-for`
// TypeScript tidak bisa mempersempit itu dari `tab` -- sehingga `s.tingkat`
// dan `u.kode` jadi "tidak ada di tipe ini". Dua daftar lebih memanjang
// tapi tipenya benar, dan itu yang menghilangkan error kompilasi.
const tampilUstadz = computed(() => daftarUstadzTampil.value)
const tampilSantri = computed(() => daftarSantriTampil.value)
const total = computed(() => tab.value === 'ustadz' ? daftarUstadz.value.length : daftarSantri.value.length)
const jmlNonaktif = computed(() => (tab.value === 'ustadz'
  ? daftarUstadz.value.filter(u => !u.aktif).length
  : daftarSantri.value.filter(s => !s.aktif).length))
const jmlBelumAda = computed(() => (tab.value === 'ustadz'
  ? daftarUstadz.value.filter(u => !u.auth_id).length
  : daftarSantri.value.filter(s => !s.auth_id).length))

const opsiSemester = computed(() => {
  const set = new Set<number>()
  for (const s of daftarSantri.value) if (s.semester != null) set.add(s.semester)
  return [...set].sort((a, b) => a - b)
})

const adaFilter = computed(() =>
  fSemester.value !== 0 || fKelas.value !== 0 || fAkun.value !== 'semua' || search.value.trim() !== '')

function bersihkanFilter() {
  search.value = ''
  fSemester.value = 0
  fKelas.value = 0
  fAkun.value = 'semua'
}

const lencanaSemester = (s: SantriAdmin) => s.semester == null ? 'Sem ?' : `Sem ${s.semester}`

// ——————— Tambah (buat akun, lalu tautkan ke baris yang dipilih) ———————

// Baris yang dipilih untuk ditautkan. Wajib: akun tanpa baris adalah akun
// mati -- orang bisa masuk tapi tidak melihat apa pun.
const targetId = ref<number | null>(null)
const cariTarget = ref('')

// Mentor yang BENAR-BENAR baru: belum punya baris sama sekali. Tanpa mode ini,
// admin tidak bisa menambah siapa pun -- hanya menautkan akun ke nama yang
// sudah ada.
const namaBaru = ref('')
const buatBaru = ref(false)

const kandidat = computed(() => {
  const q = cariTarget.value.trim().toLowerCase()
  const pool = formRole.value === 'ustadz' ? daftarUstadz.value : daftarSantri.value
  // Hanya yang BELUM punya akun. Menawarkan yang sudah punya menghasilkan
  // "akun sudah dipakai oleh X" -- membingungkan kalau tidak tahu caranya.
  const belumAda = pool.filter(x => !x.auth_id)
  if (!q) return belumAda
  return belumAda.filter(x => x.nama.toLowerCase().includes(q))
})

function bukaTambah(role: 'ustadz' | 'santri') {
  formRole.value = role
  form.value = { email: '', password: '' }
  targetId.value = null
  cariTarget.value = ''
  namaBaru.value = ''
  buatBaru.value = false
  formVisible.value = true
}

function pilihModeBaru(nilai: boolean) {
  buatBaru.value = nilai
  targetId.value = null
  namaBaru.value = ''
  galat.value = ''
}

async function simpanTambah() {
  if (!form.value.email.trim() || !form.value.password) {
    toast.error('Email dan kata sandi wajib diisi.'); return
  }
  if (form.value.password.length < 6) {
    toast.error('Kata sandi minimal 6 karakter.'); return
  }
  if (buatBaru.value && !namaBaru.value.trim()) {
    toast.error('Nama mentornya wajib diisi.'); return
  }
  if (!buatBaru.value && targetId.value == null) {
    toast.error('Pilih orangnya dulu — akun harus menempel ke nama.'); return
  }

  sibuk.value = true
  try {
    // Baris dibuat lebih dulu kalau memang baru. Alasannya soal kegagalan:
    // kalau baris dibuat belakangan dan langkah akunnya gagal, yang tertinggal
    // adalah akun tanpa nama -- tidak terlihat di mana-mana dan tidak bisa
    // dibersihkan dari UI. Baris tanpa akun justru tidak masalah: ia muncul di
    // daftar "pilih orang" seperti Ust. Akmal sekarang, dan tinggal dicoba
    // lagi.
    const idBaris = buatBaru.value
      ? await tambahUstadz(sb, namaBaru.value.trim())
      : targetId.value!

    // Akun dulu, baru tautkan. Kalau tautkan dulu, `auth_id` menunjuk akun
    // yang belum ada.
    const akun = await buatAkun(sb, {
      email: form.value.email.trim(),
      password: form.value.password,
    })
    await tautkanAkun(sb, formRole.value, idBaris, akun.auth_id)
    toast.success(buatBaru.value
      ? `${namaBaru.value.trim()} ditambahkan dan akunnya dibuat.`
      : 'Akun dibuat dan ditautkan.')
    formVisible.value = false
    await muat()
  } catch (e) {
    // Kegagalan di tengah tidak dihapus paksa. Kalau baris sudah terbuat dan
    // tautkan gagal, baris itu masih berguna -- dan pesannya menyebut apa
    // yang belum selesai, bukan sekadar "gagal".
    toast.error((e as Error).message)
  }
  finally { sibuk.value = false }
}

// ——————— Edit ———————

function bukaEdit(item: any, role: 'ustadz' | 'santri') {
  editItem.value = item
  editRole.value = role
  editForm.value = { nama: item.nama, tingkat: item.tingkat ?? 'BK1' }
  editVisible.value = true
}

async function simpanEdit() {
  if (!editForm.value.nama.trim()) { toast.error('Nama wajib diisi.'); return }
  sibuk.value = true
  try {
    if (editRole.value === 'ustadz') {
      await ubahUstadz(sb, editItem.value.id, editForm.value.nama)
    } else {
      await ubahSantri(sb, editItem.value.id, editForm.value.nama, editForm.value.tingkat)
    }
    toast.success('Data diperbarui.')
    editVisible.value = false
    await muat()
  } catch (e) { toast.error((e as Error).message) }
  finally { sibuk.value = false }
}

// ——————— Hapus ———————

function bukaHapus(item: any, type: 'ustadz' | 'santri') {
  hapusTarget.value = { type, item }
}

async function konfirmasiHapus() {
  if (!hapusTarget.value) return
  sibuk.value = true
  try {
    if (hapusTarget.value.type === 'ustadz') {
      await hapusUstadz(sb, hapusTarget.value.item.id)
    } else {
      await hapusSantri(sb, hapusTarget.value.item.id)
    }
    toast.success('Data dihapus.')
    hapusTarget.value = null
    await muat()
  } catch (e) { toast.error((e as Error).message) }
  finally { sibuk.value = false }
}

// ——————— Aktif / Nonaktif (D1) ———————

function bukaAktif(item: any, type: 'ustadz' | 'santri') {
  aktifTarget.value = { type, item }
}

async function konfirmasiAktif() {
  if (!aktifTarget.value) return
  const { type, item } = aktifTarget.value
  const baru = !item.aktif
  sibuk.value = true
  try {
    if (type === 'ustadz') await setAktifUstadz(sb, item.id, baru)
    else await setAktifSantri(sb, item.id, baru)
    toast.success(baru ? `${item.nama} diaktifkan.` : `${item.nama} dinonaktifkan.`)
    aktifTarget.value = null
    await muat()
  } catch (e) { toast.error((e as Error).message) }
  finally { sibuk.value = false }
}

// ——————— Lepas akun ———————

// Lepas TIDAK menghapus akun auth-nya: itu menghapus kata sandi orang, yang
// tidak selalu diinginkan. Barisnya tetap ada, riwayatnya tetap utuh.
function bukaLepas(item: any, type: JenisAkun) {
  lepasTarget.value = { type, item }
}

async function konfirmasiLepas() {
  if (!lepasTarget.value) return
  sibuk.value = true
  try {
    await lepasAkun(sb, lepasTarget.value.type, lepasTarget.value.item.id)
    toast.success('Akun dilepas. Baris dan riwayatnya tetap ada.')
    lepasTarget.value = null
    await muat()
  } catch (e) { toast.error((e as Error).message) }
  finally { sibuk.value = false }
}

function copyKode(kode: string) {
  navigator.clipboard.writeText(kode)
  toast.success('Kode disalin!')
}



</script>

<template>
  <div>
    <!-- Header -->
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--space-4)">
      <NuxtLink to="/admin" class="back-btn">← Kembali</NuxtLink>
      <button class="utama" style="width: auto; padding: 0 var(--space-4)" @click="bukaTambah(tab)">
        + Tambah
      </button>
    </div>
    <h1 style="margin-bottom: var(--space-4)">Kelola User</h1>

    <!-- Tabs -->
    <div class="tabs">
      <button class="tab" :class="{ active: tab === 'ustadz' }" @click="tab = 'ustadz'; bersihkanFilter()">
        Mentor ({{ daftarUstadz.length }})
      </button>
      <button class="tab" :class="{ active: tab === 'santri' }" @click="tab = 'santri'; bersihkanFilter()">
        Santri ({{ daftarSantri.length }})
      </button>
    </div>

    <p v-if="galat" class="galat">{{ galat }}</p>

    <!-- Search + filter + urutan -->
    <div class="search">
      <span class="search-icon">🔍</span>
      <input v-model="search" :placeholder="tab === 'ustadz' ? 'Cari mentor atau kode...' : 'Cari santri atau kode...'">
    </div>

    <div class="baris-saring">
      <select v-if="tab === 'santri'" v-model.number="fSemester" aria-label="Saring per semester">
        <option :value="0">Semua semester</option>
        <option v-for="s in opsiSemester" :key="s" :value="s">Semester {{ s }}</option>
      </select>

      <select v-if="tab === 'santri'" v-model.number="fKelas" aria-label="Saring per kelas sorogan">
        <option :value="0">Semua kelas</option>
        <option v-for="k in kelasSorogan" :key="k.id" :value="k.id">{{ k.nama }}</option>
        <option :value="-1">Belum ada kelas</option>
      </select>

      <select v-model="fAkun" aria-label="Saring per status akun">
        <option value="semua">Semua akun</option>
        <option value="belum">Belum punya akun</option>
        <option value="ada">Sudah punya akun</option>
      </select>

      <select v-if="tab === 'ustadz'" v-model="urutanUstadz" aria-label="Urutkan">
        <option value="nama">Nama A–Z</option>
        <option value="kode">Kode</option>
      </select>

      <select v-else v-model="urutanSantri" aria-label="Urutkan">
        <option value="nama">Nama A–Z</option>
        <option value="semester">Semester</option>

        <option value="kelas">Kelas sorogan</option>
        <option value="akun">Belum punya akun dulu</option>
      </select>

      <button
        v-if="tab === 'santri' && urutanSantri === 'semester'" class="kecil"
        :title="arahSemester === 'naik' ? 'Urutkan naik' : 'Urutkan turun'"
        @click="arahSemester = arahSemester === 'naik' ? 'turun' : 'naik'"
      >{{ arahSemester === 'naik' ? '\u2191' : '\u2193' }}</button>

      <button v-if="adaFilter" class="kecil" @click="bersihkanFilter">Reset</button>
    </div>

    <p class="redup" style="font-size: .8rem; margin: 0 0 var(--space-3)">
      Menampilkan {{ (tab === 'ustadz' ? tampilUstadz : tampilSantri).length }} dari {{ total }}
      <template v-if="jmlNonaktif"> \u00b7 {{ jmlNonaktif }} nonaktif</template>
      <template v-if="jmlBelumAda"> \u00b7 {{ jmlBelumAda }} belum punya akun</template>
    </p>

    <label v-if="jmlNonaktif" class="baris-tengah" style="gap: var(--space-2); margin-bottom: var(--space-3); font-size: var(--text-sm)">
      <input v-model="tampilkanNonaktif" type="checkbox">
      <span>Tampilkan {{ jmlNonaktif }} nonaktif</span>
    </label>
    <!-- Mentor List -->
    <template v-if="tab === 'ustadz'">
      <div v-for="u in tampilUstadz" :key="u.id" class="kartu" style="padding: 0; overflow: hidden">
        <div class="list-item">
          <Avatar :name="u.nama" />
          <div class="list-item-content">
            <div class="list-item-title" :style="u.aktif ? undefined : 'opacity:.5'">{{ u.nama }}</div>
            <div class="list-item-sub">
              <span style="opacity:.6">{{ u.kode }}</span>
              <Badge v-if="!u.aktif" variant="error" label="Nonaktif" style="margin-left: 4px" />
              <Badge v-else-if="u.auth_id" variant="success" label="Aktif" style="margin-left: 4px" />
              <Badge v-else variant="warning" label="Belum daftar" style="margin-left: 4px" />
            </div>
          </div>
          <div class="list-item-actions">
            <button v-if="u.kode" class="kecil" @click.stop="copyKode(u.kode)">Kode</button>
            <button class="kecil" @click.stop="bukaEdit(u, 'ustadz')">Edit</button>
            <button v-if="u.auth_id" class="kecil" @click.stop="bukaLepas(u, 'ustadz')">Lepas</button>
            <button class="kecil" @click.stop="bukaAktif(u, 'ustadz')">
              {{ u.aktif ? 'Nonaktifkan' : 'Aktifkan' }}
            </button>
            <button class="kecil text-error" @click.stop="bukaHapus(u, 'ustadz')">Hapus</button>
          </div>
        </div>
      </div>
      <EmptyState v-if="!tampilUstadz.length" icon="👥"
                  :message="jmlNonaktif ? 'Semua mentor nonaktif. Centang di atas untuk melihatnya.' : 'Belum ada mentor.'" />
    </template>

    <!-- Santri List -->
    <template v-else>
      <div v-for="s in tampilSantri" :key="s.id" class="kartu" style="padding: 0; overflow: hidden">
        <div class="list-item">
          <Avatar :name="s.nama" />
          <div class="list-item-content">
            <div class="list-item-title" :style="s.aktif ? undefined : 'opacity:.5'">{{ s.nama }}</div>
            <div class="list-item-sub">
              {{ s.tingkat }}
              <span class="chip">{{ lencanaSemester(s) }}</span>
              <span v-if="s.kelas_sorogan" class="chip">{{ s.kelas_sorogan }}</span>
              <span v-else class="chip chip-kosong">Belum ada kelas</span>
              <Badge v-if="!s.aktif" variant="error" label="Nonaktif" style="margin-left: 4px" />
              <Badge v-else-if="s.auth_id" variant="success" label="Aktif" style="margin-left: 4px" />
              <Badge v-else variant="warning" label="Belum daftar" style="margin-left: 4px" />
            </div>
          </div>
          <div class="list-item-actions">
            <button class="kecil" @click.stop="bukaEdit(s, 'santri')">Edit</button>
            <button v-if="s.auth_id" class="kecil" @click.stop="bukaLepas(s, 'santri')">Lepas</button>
            <button class="kecil" @click.stop="bukaAktif(s, 'santri')">
              {{ s.aktif ? 'Nonaktifkan' : 'Aktifkan' }}
            </button>
            <button class="kecil text-error" @click.stop="bukaHapus(s, 'santri')">Hapus</button>
          </div>
        </div>
      </div>
      <EmptyState v-if="!tampilSantri.length" icon="👨‍🎓" message="Tidak ada yang cocok dengan saringan." />
    </template>

    <!-- Form Tambah: buat AKUN, lalu tautkan ke baris yang sudah ada -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="formVisible" class="overlay" @click.self="formVisible = false">
          <div class="modal">
            <h2 style="margin: 0 0 var(--space-2)">Buat Akun {{ formRole === 'ustadz' ? 'Mentor' : 'Santri' }}</h2>
            <p class="redup" style="margin: 0 0 var(--space-4); font-size: .85rem">
              <template v-if="buatBaru">
                Mentor <b>baru</b>: barisnya dibuat sekarang, lalu akunnya
                menempel ke baris itu. Riwayat penilaian tidak ada -- ini orang
                yang belum pernah mengajar.
              </template>
              <template v-else>
                Akun menempel ke orang yang sudah terdaftar. Baris dan riwayat
                nilainya tidak dibuat ulang.
              </template>
            </p>

            <!-- Mode: pakai nama yang sudah ada -->
            <template v-if="!buatBaru">
              <label for="f-cari">Pilih orang</label>
              <input id="f-cari" v-model="cariTarget" type="search" placeholder="Ketik nama untuk mencari…">
              <div v-if="kandidat.length" class="list" style="max-height: 180px; overflow-y: auto">
                <button
                  v-for="k in kandidat.slice(0, 20)" :key="k.id" type="button" class="list-item"
                  :style="{ borderColor: targetId === k.id ? 'var(--utama)' : 'transparent' }"
                  @click="targetId = k.id"
                >
                  <div class="list-item-content">
                    <div class="list-item-title">{{ k.nama }}</div>
                    <div class="list-item-sub">{{ 'kode' in k ? k.kode : '' }}</div>
                  </div>
                </button>
              </div>
              <p v-else class="redup" style="font-size: .85rem">
                {{ cariTarget ? 'Tidak ada yang cocok.' : `Semua ${formRole === 'ustadz' ? 'mentor' : 'santri'} sudah punya akun.` }}
              </p>

              <!-- Hanya untuk mentor. Santri berasal dari impor, bukan dari
                   ketikan admin: satu orang bisa mendaftar sendiri dengan nama
                   yang mirip, dan itu tidak bisa dibedakan dari yang asli. -->
              <button
                v-if="formRole === 'ustadz'"
                class="penuh"
                style="margin-top: var(--space-3)"
                @click="pilihModeBaru(true)"
              >+ Tambah mentor baru</button>
            </template>

            <!-- Mode: nama baru -->
            <template v-else>
              <label for="f-baru">Nama mentor</label>
              <input
                id="f-baru" v-model="namaBaru" type="text" autocomplete="off"
                placeholder="Ust. Nama Lengkap"
              >
              <p class="redup" style="font-size: .75rem; margin: 4px 0 0">
                Tulis persis seperti akan dipanggil. Nama ini tidak bisa diubah
                dari halaman ini setelah akunnya jadi.
              </p>
              <button
                class="penuh"
                style="margin-top: var(--space-3)"
                @click="pilihModeBaru(false)"
              >← Pilih dari daftar</button>
            </template>

            <label for="f-email" style="display: block; margin-top: var(--space-3)">Email</label>
            <input id="f-email" v-model="form.email" type="email" placeholder="email@contoh.com">
            <label for="f-pass">Kata Sandi</label>
            <input id="f-pass" v-model="form.password" type="password" placeholder="Minimal 6 karakter">

            <div class="baris mt-4">
              <button style="flex: 1" @click="formVisible = false">Batal</button>
              <button
                class="utama"
                style="flex: 1"
                :disabled="sibuk || (!buatBaru && targetId == null) || (buatBaru && !namaBaru.trim())"
                @click="simpanTambah"
              >
                {{ sibuk ? 'Menyimpan...' : 'Buat & Tautkan' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- Form Edit -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="editVisible" class="overlay" @click.self="editVisible = false">
          <div class="modal">
            <h2 style="margin: 0 0 var(--space-4)">Edit {{ editRole === 'ustadz' ? 'Mentor' : 'Santri' }}</h2>
            <label for="e-nama">Nama</label>
            <input id="e-nama" v-model="editForm.nama" placeholder="Nama">
            <template v-if="editRole === 'santri'">
              <label for="e-tk">Tingkat</label>
              <select id="e-tk" v-model="editForm.tingkat">
                <option value="BK1">BK1</option>
                <option value="BK2">BK2</option>
              </select>
            </template>
            <div class="baris mt-4">
              <button style="flex: 1" @click="editVisible = false">Batal</button>
              <button class="utama" style="flex: 1" :disabled="sibuk" @click="simpanEdit">
                {{ sibuk ? 'Menyimpan...' : 'Simpan' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <ConfirmDialog
      :visible="!!hapusTarget"
      :message="`Hapus ${hapusTarget?.type === 'ustadz' ? 'mentor' : 'santri'} ${hapusTarget?.item?.nama}?${hapusTarget?.item?.aktif === false ? ' (sudah nonaktif)' : ''}`"
      @confirm="konfirmasiHapus"
      @cancel="hapusTarget = null"
    />

    <ConfirmDialog
      :visible="!!aktifTarget"
      :confirm-text="aktifTarget?.item?.aktif ? 'Ya, Nonaktifkan' : 'Ya, Aktifkan'"
      :message="aktifTarget?.item?.aktif
        ? `Nonaktifkan ${aktifTarget.item.nama}? Ia hilang dari daftar, tapi riwayatnya tetap utuh.`
        : `Aktifkan kembali ${aktifTarget?.item?.nama}? Ia akan muncul lagi di daftar.`"
      @confirm="konfirmasiAktif"
      @cancel="aktifTarget = null"
    />

    <ConfirmDialog
      :visible="!!lepasTarget"
      confirm-text="Ya, Lepas"
      :message="`Lepas akun ${lepasTarget?.item?.nama}? Akunnya masih ada di daftar Auth tapi tidak lagi terhubung ke nama ini. Baris dan riwayat nilainya tetap utuh.`"
      @confirm="konfirmasiLepas"
      @cancel="lepasTarget = null"
    />
  </div>
</template>
