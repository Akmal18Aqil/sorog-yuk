/**
 * Di mana setiap halaman harus kembali digulir.
 *
 * Perilaku bawaan router adalah `top: 0` untuk SETIAP navigasi. Itu benar
 * untuk situs yang panjang, dan salah untuk aplikasi: kembali ke halaman yang
 * tadi dibaca harus berakhir di tempat yang sama, bukan di paling atas --
 * itu yang membedakan aplikasi dari dokumen web.
 *
 * Modul ini sengaja terpisah dari `nuxt.config` supaya bisa diuji tanpa
 * menjalankan Nuxt (lihat `test/scroll.test.ts`).
 */

export interface PosisiScroll { top: number; left: number }

export interface RuteMinimal { path: string }

/**
 * Disimpan per rute. Jumlahnya dibatasi jumlah halaman, jadi tidak perlu ada
 * pembersih berkala.
 */
const posisi = new Map<string, PosisiScroll>()

/** Hanya untuk test: isi memori tidak boleh bocor antar kasus. */
export function lupaPosisi(): void {
  posisi.clear()
}

export type HasilScroll = PosisiScroll | false | Promise<PosisiScroll | false>

/**
 * `scrollBehavior` milik router.
 *
 * Empat aturan, berurutan dari yang paling berwenang:
 *
 *  1. `savedPosition` (tombol back/forward browser) selalu menang. Browser
 *     yang tahu, dan mengabaikannya membuat tombol back terasa rusak.
 *  2. Rute yang sama: jangan bergerak sama sekali. Tanpa ini, menekan item
 *     nav yang sedang aktif akan melempar halaman ke atas.
 *  3. Halaman yang SUDAH pernah dibuka: kembali ke posisi terakhirnya.
 *  4. Halaman baru: ke atas. Bukan pilihan estetika -- halaman yang lebih
 *     pendek dari offset sekarang akan menampilkan ruang kosong.
 */
export function scrollBehavior(
  to: RuteMinimal,
  from: RuteMinimal,
  savedPosition: PosisiScroll | null,
): HasilScroll {
  if (savedPosition) return savedPosition
  if (to.path === from.path) return false

  // Disimpan posisi yang DITINGGALKAN. Router memanggil ini sebelum browser
  // menggulir, jadi `scrollY` di sini masih yang lama -- inilah satu-satunya
  // tempat yang bisa menangkapnya tanpa listener scroll per halaman.
  if (typeof window !== 'undefined' && from.path) {
    posisi.set(from.path, { top: window.scrollY, left: window.scrollX })
  }

  const tersimpan = posisi.get(to.path)
  if (tersimpan !== undefined) {
    // Ditunda satu tick: halaman baru harus selesai dirender dulu. Kalau tidak,
    // posisinya diterapkan saat kontainer masih kosong dan browser memotongnya
    // kembali ke atas -- jadi restore-nya jadi tidak berguna.
    return new Promise<PosisiScroll>(resolve =>
      setTimeout(() => resolve(tersimpan), 0))
  }

  return { top: 0, left: 0 }
}
