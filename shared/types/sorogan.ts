/**
 * Batas anti-korupsi antara database dan domain.
 *
 * Di Postgres, `tipe`/`verdict`/`tingkat` adalah `text` dengan CHECK constraint,
 * jadi TypeScript melihatnya sebagai `string` — dan `string` membiarkan salah
 * ketik lolos sampai runtime. Di sini nilainya dipersempit jadi union, dan
 * repository wajib menyempitkannya saat data masuk.
 *
 * Nama kolom sengaja TIDAK diubah ke camelCase: penggantian nama itu murni
 * kosmetik dan hanya menambah lapisan pemetaan yang bisa salah. Yang dibeli
 * di sini adalah keamanan tipe, bukan gaya penulisan.
 */
import type { Tables } from './database'

export const VERDICT = ['benar', 'dibantu', 'salah'] as const
export type Verdict = (typeof VERDICT)[number]

export const TIPE_BK2 = ['ismiyah', 'filiyah', 'nawasikh', 'tabi'] as const
export type TipeBK2 = (typeof TIPE_BK2)[number]
export type TipeSoal = 'lafad' | TipeBK2

export const TINGKAT = ['BK1', 'BK2'] as const
export type Tingkat = (typeof TINGKAT)[number]

export const MODE = ['ujian', 'harian'] as const
export type Mode = (typeof MODE)[number]

const anggota = <T extends readonly string[]>(daftar: T) =>
  (v: string | null | undefined): v is T[number] =>
    typeof v === 'string' && (daftar as readonly string[]).includes(v)

export const isVerdict = anggota(VERDICT)
export const isTipeSoal = (v: string | null | undefined): v is TipeSoal =>
  v === 'lafad' || anggota(TIPE_BK2)(v)
export const isTingkat = anggota(TINGKAT)
export const isMode = anggota(MODE)

// ——— Entitas domain: baris database dengan kolom yang dipersempit ———
export type Langkah = Omit<Tables<'langkah'>, 'tipe'> & { tipe: TipeSoal }
export type Soal = Omit<Tables<'soal'>, 'tipe' | 'tingkat'> & { tipe: TipeSoal; tingkat: Tingkat }
export type Santri = Omit<Tables<'santri'>, 'tingkat'> & { tingkat: Tingkat }
export type Ibarat = Tables<'ibarat'>
export type Ustadz = Pick<Tables<'ustadz'>, 'id' | 'nama'>
export type Kelompok = Tables<'kelompok'>
export type Kelas = Tables<'kelas'>
export type Kesiapan = Tables<'v_kesiapan_naik'>

export const LABEL_TIPE: Record<TipeSoal, string> = {
  lafad: 'lafad',
  ismiyah: 'jumlah ismiyah',
  filiyah: "jumlah fi'liyah",
  nawasikh: 'amil nawasikh',
  tabi: "tabi'",
}

export const LABEL_VERDICT: Record<Verdict, { judul: string; sub: string }> = {
  benar: { judul: 'Benar', sub: 'lancar sendiri' },
  dibantu: { judul: 'Dibantu', sub: 'ditunjuki dulu' },
  salah: { judul: 'Salah', sub: 'belum bisa' },
}

/** Berapa soal per santri. BK1 = 10 kolom leger kertas. BK2 = 2 × 4 tipe. */
export const JML_SOAL_BK1 = 10
export const PER_TIPE_BK2 = 2
