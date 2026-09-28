import { TINGKAT, isTingkat, type Kelompok, type Tingkat } from '../types/sorogan'

/**
 * Status absen harian. Disepakati teks bebas untuk kendala, tapi status
 * TETAP union tertutup: laporan walikelas menghitung H/I/S/A, dan string
 * bebas ("hadirr", "Hadirr") akan memecah hitungan tanpa ketahuan.
 */
export const STATUS_HADIR = ['hadir', 'izin', 'sakit', 'alpa'] as const
export type StatusHadir = (typeof STATUS_HADIR)[number]

export const isStatusHadir = (v: string | null | undefined): v is StatusHadir =>
  v === 'hadir' || v === 'izin' || v === 'sakit' || v === 'alpa'

export const LABEL_STATUS: Record<StatusHadir, string> = {
  hadir: 'Hadir',
  izin: 'Izin',
  sakit: 'Sakit',
  alpa: 'Alpa',
}


/**
 * Kelompok itu milik kelas, bukan milik pesantren.
 *
 * Tiap kelas sorogan punya kelompoknya sendiri: BK1 punya Kelompok 1, 2, 3,
 * dan BK2 punya Kelompok 1, 2 sendiri. Jadi NAMA kelompok berulang antar
 * kelas, dan "Kelompok 3" tanpa kelasnya tidak bisa dijawab pertanyaannya
 * sendiri: anak-anak kelas mana?
 *
 * Aturannya di sini, bukan di halaman /mulai, karena ada tiga hal yang bisa
 * salah dan semuanya harus diuji tanpa merender apa pun -- sama seperti
 * `pembagian.ts` dan `tangga.ts`.
 */

/**
 * Kelas yang PUNYA kelompok, dan hanya itu.
 *
 * Bukan seluruh master `kelas`: kelas yang belum punya kelompok tidak punya
 * satu pun santri yang bisa dinilai, jadi menampilkan tabnya hanya
 * menyediakan jalan menuju layar kosong. Daftar ini ikut berubah sendiri
 * begitu kelompok baru dibuat -- tidak ada yang perlu diatur ulang.
 *
 * Urutannya dari `TINGKAT`, bukan dari database: itu urutan kelas yang
 * sudah disepakati (BK1 sebelum BK2), dan `kelompok.urutan` tidak
 * menjanjikan apa pun tentang antar-kelas.
 */
export function kelasBerisiKelompok(kelompok: Kelompok[]): Tingkat[] {
  const ada = new Set<string>(kelompok.map(k => k.tingkat).filter(isTingkat))
  return TINGKAT.filter(t => ada.has(t))
}

/** Kelompok milik satu kelas, urutan seperti yang diberikan. */
export function kelompokKelas(kelompok: Kelompok[], tingkat: Tingkat): Kelompok[] {
  return kelompok.filter(k => k.tingkat === tingkat)
}

/**
 * Kelompok yang kelasnya belum diatur atau di luar yang dikenal aplikasi.
 *
 * Dipisahkan, BUKAN dibuang. Kelompok ini tidak bisa dinilai -- format
 * ujiannya ditentukan kelas, dan `useSesi` memilih alur dari `tingkat` --
 * jadi mentor harus diberi tahu kenapa anggotanya tidak muncul di kelas mana
 * pun. Menyembunyikannya sama dengan menghilangkan santri tanpa jejak.
 *
 * NULL itu keadaan yang sah (048:28 -- kelompok terjemah tidak punya tingkat
 * baca kitab), jadi ini peringatan, bukan kesalahan.
 */
export function kelompokTanpaKelas(kelompok: Kelompok[]): Kelompok[] {
  return kelompok.filter(k => !isTingkat(k.tingkat))
}
