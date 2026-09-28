export type Role = 'superadmin' | 'ustadz' | 'santri'

export interface ItemNav {
  label: string
  to: string
  /** Tampil di navigasi bawah HP. Sisanya hanya ada di sidebar desktop. */
  utama: boolean
  /** Nama ikon SVG bawaan (lihat `IkonNav` di BottomNav/Sidebar). Tanpa emoji:
   *  emoji beda bentuk tiap HP (DESAIN.md §10). */
  ikon: string
}

/**
 * Satu daftar navigasi untuk semua role. Sidebar dan BottomNav membacanya dari
 * sini, jadi isinya tidak mungkin berbeda.
 *
 * Setiap `to` harus halaman yang benar-benar ada di `app/pages`. Halaman yang
 * dihapus harus menghapus barisnya di sini juga, tidak boleh meninggalkan
 * tautan mati.
 */
const NAV: Record<Role, ItemNav[]> = {
  superadmin: [
    { label: 'Beranda', to: '/admin', utama: true, ikon: 'beranda' },
    { label: 'User', to: '/admin/kelola-user', utama: true, ikon: 'user' },
    { label: 'Kelas', to: '/admin/kelas', utama: true, ikon: 'kelas' },
    { label: 'Kelas Kuliah', to: '/admin/kelas-kuliah', utama: false, ikon: 'kuliah' },
    { label: 'Kelompok', to: '/admin/kelompok', utama: true, ikon: 'kelompok' },
    { label: 'Kitab', to: '/admin/kitab', utama: true, ikon: 'kitab' },
    // Laporan dipakai BERSAMA musrif (satu halaman /laporan, dibuka superadmin
    // lewat pengecualian di middleware). Sidebar saja: bottom nav sudah 5 item.
    { label: 'Laporan', to: '/laporan', utama: false, ikon: 'laporan' },
    { label: 'Soal', to: '/admin/soal', utama: false, ikon: 'soal' },
    { label: 'Langkah', to: '/admin/langkah', utama: false, ikon: 'langkah' },
  ],
  ustadz: [
    { label: 'Sorogan', to: '/mulai', utama: true, ikon: 'sorogan' },
    { label: 'Laporan', to: '/laporan', utama: true, ikon: 'laporan' },
    { label: 'Hasil', to: '/hasil', utama: true, ikon: 'hasil' },
    // Kenaikan turun ke sidebar: bottom nav HP muat nyaman max 4-5 item,
    // dan Sorogan+Laporan+Hasil dipakai tiap hari sedang Kenaikan musiman.
    { label: 'Kenaikan', to: '/kenaikan', utama: false, ikon: 'kenaikan' },
  ],
  santri: [
    { label: 'Nilai', to: '/santri/dashboard', utama: true, ikon: 'hasil' },
  ],
}

export function navUntuk(role: Role | null): ItemNav[] {
  return role ? NAV[role] : []
}

/** Item navigasi yang muat di bottom nav HP. */
export function navUtama(role: Role | null): ItemNav[] {
  return navUntuk(role).filter(i => i.utama)
}

/**
 * Apakah `path` hanya boleh dibuka superadmin?
 *
 * Di sini, bukan di middleware, karena middleware tidak bisa diuji tanpa
 * menjalankan Nuxt (lihat `test/nav.test.ts`).
 *
 * `/super-adminn` TIDAK berawalan `/admin` -- itu justru sebabnya tidak muncul
 * di navigasi. Tapi konsekuensinya, dia akan jatuh ke cabang "ustadz" di
 * middleware dan superadmin yang membukanya justru diarahkan balik ke
 * `/admin`: halaman jadi mustahil dibuka. Karena itu disebut eksplisit di
 * sini, bukan mengandalkan awalan.
 */
export function hanyaSuperadmin(path: string): boolean {
  return path.startsWith('/admin') || path.startsWith('/super-adminn')
}

/**
 * Halaman yang berdiri sendiri, tanpa kerangka aplikasi. Login dan pendaftaran
 * selalu berdiri sendiri, karena orang yang belum punya sesi tidak punya satu
 * pun tujuan untuk progressing.
 *
 * Daftar ini, bukan `!role`, yang menentukan. `role` null adalah keadaan
 * kebetulan: begitu sesi kedeteksi, `role` terisi dan halaman login sempat
 * berkedip memakai sidebar sebelum middleware dialihkan ke `/mulai`.
 */
const HALAMAN_SENDIRI = new Set(['/', '/daftar-santri'])

export function halamanSendiri(path: string): boolean {
  return HALAMAN_SENDIRI.has(path)
}

/**
 * Apakah kerangka navigasi perlu ditampilkan. Tiga syarat sekaligus, dan
 * semuanya harus benar: cukup lebar untuk sidebar, sudah masuk, dan bukan
 * halaman yang berdiri sendiri.
 */
export function perluSidebar(path: string, role: Role | null, lebar: boolean): boolean {
  return lebar && !!role && !halamanSendiri(path)
}
