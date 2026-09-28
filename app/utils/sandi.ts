/**
 * Aturan kata sandi untuk halaman ganti password.
 *
 * Terpisah dari komponen supaya bisa diuji tanpa merender apa pun.
 */

/**
 * Panjang minimum. Lebih panjang dari 6 (bawaan Supabase, dan yang dipakai
 * form "buat akun" di Kelola User) karena halaman ini khusus untuk akun yang
 * bisa menghapus data dan menaikkan orang lain jadi superadmin. Rule yang
 * lebih longgar di satu tempat berguna di tempat lain jadi tidak konsisten.
 */
export const PANJANG_MIN = 8

/**
 * Periksa password baru. Kembalikan pesan yang bisa langsung ditampilkan,
 * atau `null` kalau sudah benar.
 *
 * Tiga hal yang diperiksa, dan urutannya penting:
 *  1. Wajib diisi -- biar "kosong" tidak lolos sebagai "terlalu pendek".
 *  2. Panjang minimum.
 *  3. Sama dengan ulangannya -- mencegah salah ketik yang mengunci orang
 *     keluar dari akunnya sendiri.
 *  4. Beda dari yang lama -- kalau tidak, orang think sudah mengganti
 *     padahal tidak ada yang berubah.
 */
export function periksaSandiBaru(baru: string, ulang: string, lama: string): string | null {
  if (!baru) return 'Password baru wajib diisi.'
  if (baru.length < PANJANG_MIN) return `Password baru minimal ${PANJANG_MIN} karakter.`
  if (baru !== ulang) return 'Ulangi password tidak sama.'
  if (baru === lama) return 'Password baru harus berbeda dari yang lama.'
  return null
}
