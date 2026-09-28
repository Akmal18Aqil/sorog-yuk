<script setup lang="ts">
/**
 * /super-adminn — mengelola siapa saja yang|superadmin.
 *
 * SENGAJA TIDAK ADA DI NAVIGASI. Tautan yang tidak tampil hanya membuat
 * halaman ini sulit ditemukan orang; yang benar-benar menutupnya adalah
 * pemeriksaan di dalam `daftar_superadmin` dan `atur_superadmin` (db/049),
 * yang menolak pemanggil non-superadmin apa pun tautan yang diketik.
 *
 * Halaman ini tidak menambah, hanya mengubah peran orang yang SUDAH ada.
 * Baris dan akun login-nya dibuat di Kelola User, lalu namanya dinaikkan
 * di sini.
 */
import type { Database } from '#shared/types/database'
import { ambilDaftarSuperadmin, aturSuperadmin, type AdminSuper } from '~/utils/repo'
import { periksaSandiBaru, PANJANG_MIN } from '~/utils/sandi'

definePageMeta({ middleware: 'auth' })

const sb = useSupabaseClient<Database>()
const toast = useToast()
const { pengguna, gantiPassword } = useAuth()

const daftar = ref<AdminSuper[]>([])
const semuaUstadz = ref<{ id: number; nama: string; role: string; aktif: boolean; auth_id: string | null }[]>([])
const galat = ref('')
const sibuk = ref(false)
const cari = ref('')

// ——————— Ganti password sendiri ———————
// Password LAMA wajib diisi. Sesi login ada di localStorage, jadi tanpa itu
// siapa pun yang memakai perangkat yang tidak terkunci bisa mengunci asatidz
// keluar dari akunnya sendiri.
const sandi = ref({ lama: '', baru: '', ulang: '' })
const galatSandi = ref('')
const sibukSandi = ref(false)

async function muat() {
  galat.value = ''
  try {
    // Satu Promise.all: kedua daftar dibutuhkan sebelum tombol mana pun boleh
    // tampil, jadi tidak pernah ada keadaan setengah ter-render.
    const [s, u] = await Promise.all([
      ambilDaftarSuperadmin(sb),
      sb.from('ustadz').select('id,nama,role,aktif,auth_id').neq('role', 'superadmin')
        .then(r => { if (r.error) throw new Error(r.error.message); return r.data ?? [] }),
    ])
    daftar.value = s
    semuaUstadz.value = u as any
  } catch (e) { galat.value = (e as Error).message }
}

onMounted(muat)

/** Superadmin aktif selain akun ini. */
const jmlSuperAktifLain = computed(() => daftar.value.filter(d => d.aktif && !d.is_saya).length)

/** Superadmin aktif terakhir TIDAK boleh diturunkan maupun dinonaktifkan. */
function terkunci(a: AdminSuper): boolean {
  return a.aktif && a.role === 'superadmin' && jmlSuperAktifLain.value === 0
}

const calonTersaring = computed(() => {
  const q = cari.value.trim().toLowerCase()
  const sudah = new Set(daftar.value.map(d => d.id))
  const pool = semuaUstadz.value
    .filter(u => !sudah.has(u.id))
    .map(u => ({ id: u.id, nama: u.nama, punya_akun: !!u.auth_id }))
  if (!q) return pool
  return pool.filter(u => u.nama.toLowerCase().includes(q))
})

async function ubah(a: AdminSuper, peran: 'superadmin' | 'ustadz', aktif: boolean, label: string) {
  if (!confirm(`${label} ${a.nama}?`)) return
  sibuk.value = true
  try {
    await aturSuperadmin(sb, { id: a.id, peran, aktif })
    toast.success(`${a.nama} diperbarui.`)
    await muat()
  } catch (e) {
    // Pesan server ditulis khusus untuk situasi ini (db/049) -- tampilkan apa
    // adanya, jangan ringkas jadi "gagal".
    toast.error((e as Error).message)
  } finally { sibuk.value = false }
}

async function angkat(c: { id: number; nama: string }) {
  if (!confirm(`Angkat ${c.nama} menjadi superadmin?`)) return
  sibuk.value = true
  try {
    await aturSuperadmin(sb, { id: c.id, peran: 'superadmin', aktif: true })
    toast.success(`${c.nama} sekarang superadmin.`)
    await muat()
  } catch (e) { toast.error((e as Error).message) }
  finally { sibuk.value = false }
}

async function simpanSandi() {
  galatSandi.value = ''
  if (!sandi.value.lama) {
    galatSandi.value = 'Password lama wajib diisi.'
    return
  }
  // Aturan lengkap (panjang, ulangan, beda dari yang lama) di satu tempat,
  // supaya form ini dan test-nya tidak punya versi masing-masing.
  const masalah = periksaSandiBaru(sandi.value.baru, sandi.value.ulang, sandi.value.lama)
  if (masalah) { galatSandi.value = masalah; return }

  sibukSandi.value = true
  try {
    await gantiPassword(sandi.value.lama, sandi.value.baru)
    // Dikosongkan hanya setelah berhasil: kalau gagal, mengetik ulang password
    // lama jauh lebih menyebalkan daripada field yang masih terisi.
    sandi.value = { lama: '', baru: '', ulang: '' }
    toast.success('Password diganti.')
  } catch (e) {
    galatSandi.value = (e as Error).message
  } finally { sibukSandi.value = false }
}
</script>

<template>
  <div>
    <div style="margin-bottom: var(--space-4)">
      <NuxtLink to="/admin" class="back-btn">← Kembali</NuxtLink>
    </div>
    <h1 style="margin-bottom: var(--space-2)">Kelola Superadmin</h1>
    <p class="text-muted text-sm" style="margin-bottom: var(--space-4)">
      Mengatur siapa saja yang boleh mengelola admin. Halaman ini tidak ada di
      menu; yang menutupnya adalah pemeriksaan di server, bukan ketidaktahuan
      tautan.
    </p>
    <p v-if="galat" class="galat">{{ galat }}</p>

    <div class="section">
      <div class="section-header">
        <h2 class="section-title">Superadmin</h2>
        <Badge :label="`${daftar.filter(d => d.aktif).length} aktif`" />
      </div>

      <div v-for="a in daftar" :key="a.id" class="kartu" style="padding: 0; overflow: hidden">
        <div class="list-item">
          <span class="avatar">🛡️</span>
          <div class="list-item-content">
            <div class="list-item-title">
              {{ a.nama }}
              <span v-if="a.is_saya" class="chip">Anda</span>
              <span v-if="!a.aktif" class="chip chip-kosong">Nonaktif</span>
            </div>
            <div class="list-item-sub">
              {{ a.punya_akun ? 'Punya akun login' : 'Belum punya akun login' }}
            </div>
          </div>
          <div class="list-item-actions">
            <button
              v-if="a.aktif"
              class="kecil"
              :disabled="sibuk || terkunci(a)"
              :title="terkunci(a) ? 'Superadmin aktif terakhir tidak bisa dinonaktifkan' : ''"
              @click="ubah(a, 'superadmin', false, 'Nonaktifkan')"
            >Nonaktifkan</button>
            <button
              v-else
              class="kecil"
              :disabled="sibuk"
              @click="ubah(a, 'superadmin', true, 'Aktifkan kembali')"
            >Aktifkan</button>
            <button
              class="kecil text-error"
              :disabled="sibuk || terkunci(a)"
              :title="terkunci(a) ? 'Superadmin aktif terakhir tidak bisa diturunkan' : ''"
              @click="ubah(a, 'ustadz', a.aktif, 'Turunkan ke ustadz')"
            >Turunkan</button>
          </div>
        </div>
        <p
          v-if="terkunci(a)"
          class="redup"
          style="font-size: .75rem; margin: 0; padding: 0 var(--space-3) var(--space-3)"
        >
          Ini superadmin aktif terakhir. Angkat orang lain dulu, baru turunkan ini —
          kalau tidak, tidak ada akun yang bisa mengelola admin lagi.
        </p>
      </div>

      <EmptyState v-if="!daftar.length" icon="🛡️" message="Belum ada superadmin." />
    </div>

    <div class="section">
      <div class="section-header">
        <h2 class="section-title">Angkat superadmin baru</h2>
        <Badge :label="`${calonTersaring.length} orang`" />
      </div>
      <p class="text-muted text-sm" style="margin-bottom: var(--space-3)">
        Akun login dibuat lebih dulu di Kelola User. Yang belum punya akun tidak
        bisa diangkat.
      </p>

      <div class="search">
        <span class="search-icon">🔍</span>
        <input v-model="cari" type="search" autocomplete="off" placeholder="Ketik nama untuk mencari…">
      </div>

      <div
        v-if="calonTersaring.length"
        class="list"
        style="border: 1px solid var(--border); border-radius: var(--radius-lg)"
      >
        <div v-for="c in calonTersaring" :key="c.id" class="list-item">
          <div class="list-item-content">
            <div class="list-item-title">{{ c.nama }}</div>
            <div class="list-item-sub">
              {{ c.punya_akun ? 'Punya akun login' : 'Belum punya akun login' }}
            </div>
          </div>
          <button
            class="kecil"
            :disabled="sibuk || !c.punya_akun"
            :title="c.punya_akun ? '' : 'Buat akun login di Kelola User dulu'"
            @click="angkat(c)"
          >Angkat</button>
        </div>
      </div>
      <p v-else class="redup" style="font-size: .85rem">
        {{ cari ? 'Tidak ada yang cocok.' : 'Semua sudah jadi superadmin.' }}
      </p>
    </div>

    <div class="section">
      <div class="section-header">
        <h2 class="section-title">Ganti password saya</h2>
      </div>
      <p class="text-muted text-sm" style="margin-bottom: var(--space-3)">
        Untuk akun <b>{{ pengguna?.email ?? 'tidak terbaca' }}</b>. Password lama
        wajib diisi, supaya orang lain yang memakai perangkat ini tidak bisa
        mengunci Anda keluar.
      </p>

      <form class="kartu" @submit.prevent="simpanSandi">
        <label for="s-lama">Password lama</label>
        <input
          id="s-lama" v-model="sandi.lama" type="password"
          autocomplete="current-password" placeholder="Password sekarang"
        >

        <label for="s-baru">Password baru</label>
        <input
          id="s-baru" v-model="sandi.baru" type="password"
          autocomplete="new-password" :placeholder="`Minimal ${PANJANG_MIN} karakter`"
        >

        <label for="s-ulang">Ulangi password baru</label>
        <input
          id="s-ulang" v-model="sandi.ulang" type="password"
          autocomplete="new-password" placeholder="Ketik ulang"
        >

        <p v-if="galatSandi" class="galat" style="margin-top: var(--space-3)">
          {{ galatSandi }}
        </p>

        <button class="utama mt-4" type="submit" :disabled="sibukSandi" style="width: 100%">
          {{ sibukSandi ? 'Menyimpan...' : 'Ganti password' }}
        </button>
      </form>
    </div>
  </div>
</template>
