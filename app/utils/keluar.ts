/**
 * Buang cache identitas dan data acuan dari localStorage.
 *
 * Dipanggil oleh KEDUA jalur logout (`useAuth.keluar` untuk tombol di sidebar
 * dan `useUstadz.keluar` untuk tombol di header halaman). Kalau hanya salah
 * satu yang membersihkannya, logout lewat sidebar -- jalur yang paling sering
 * dipakai di desktop -- meninggalkan `sorogan.ustadz` di localStorage, dan
 * mentor berikutnya yang kebetulan offline akan melihat nama orang
 * sebelumnya, karena `periksa()` jatuh ke cache saat server tidak bisa
 * dihubungi.
 *
 * Di `app/utils`, bukan di dalam composable, supaya bisa diuji tanpa
 * menjalankan Nuxt (lihat `test/logout.test.ts`).
 */
export function bersihkanCacheUstadz() {
  localStorage.removeItem('sorogan.ustadz')
  localStorage.removeItem('sorogan.acuan')
}