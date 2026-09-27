/**
 * Mesin keadaan tangga pertanyaan. Murni dan tak berubah (immutable):
 * tiap aksi mengembalikan status baru.
 *
 * Ini sengaja BUKAN state komponen. Urutan tangga, aturan "cukup sekali per
 * sesi", dan perilaku "lewati" adalah aturan ilmu alat yang datang dari lembar
 * asatidz — bukan detail tampilan. Ditaruh di sini supaya bisa diuji tanpa
 * merender apa pun, dan supaya tidak ikut berubah setiap kali UI dirombak.
 */
import type { Langkah, TipeSoal, Verdict } from '../types/sorogan'
import type { JawabanLangkah } from './nilai'

export interface StatusTangga {
  readonly langkah: readonly Langkah[]
  readonly posisi: number
  readonly jawaban: readonly JawabanLangkah[]
}

/**
 * Tangga untuk satu soal.
 *
 * Pertanyaan definisi ("Apa pengertian mubtada'?") ditandai `sekali_per_sesi`
 * dan dibuang kalau sudah pernah keluar — persis catatan "Opsional/cukup
 * sekali" di lembar asatidz. Tanpa ini, santri ditanya definisi yang sama
 * 15 kali dalam satu sesi.
 */
export function susunTangga(
  semua: readonly Langkah[],
  tipe: TipeSoal,
  sudahDitanya: ReadonlySet<number> = new Set(),
): Langkah[] {
  return semua
    .filter(l => l.tipe === tipe)
    .filter(l => !(l.sekali_per_sesi && sudahDitanya.has(l.id)))
    .sort((a, b) => a.urutan - b.urutan)
}

export const mulaiTangga = (langkah: readonly Langkah[]): StatusTangga => ({
  langkah,
  posisi: 0,
  jawaban: [],
})

export const langkahKini = (s: StatusTangga): Langkah | null => s.langkah[s.posisi] ?? null

export const tanggaSelesai = (s: StatusTangga): boolean => s.posisi >= s.langkah.length

/**
 * Jawab langkah sekarang dan maju.
 *
 * `verdict === null` berarti DILEWATI (langkah bersyarat yang tidak berlaku:
 * BK1 no. 6–7 hanya untuk isim, no. 9 hanya untuk isim mabni). Yang dilewati
 * TIDAK menghasilkan baris jawaban sama sekali — bukan nilai nol. Perbedaan
 * itulah yang membuat rata-rata tetap adil.
 */
export function jawab(s: StatusTangga, verdict: Verdict | null, detik?: number): StatusTangga {
  const l = langkahKini(s)
  if (!l) return s
  const lain = s.jawaban.filter(j => j.langkah_id !== l.id)
  return {
    ...s,
    posisi: s.posisi + 1,
    jawaban: verdict === null
      ? lain
      : [...lain, { langkah_id: l.id, verdict, ...(detik === undefined ? {} : { detik }) }],
  }
}

/** Mundur satu langkah dan buang jawabannya — penguji salah ketuk itu wajar. */
export function mundur(s: StatusTangga): StatusTangga {
  if (s.posisi === 0) return s
  const sebelum = s.langkah[s.posisi - 1]!
  return {
    ...s,
    posisi: s.posisi - 1,
    jawaban: s.jawaban.filter(j => j.langkah_id !== sebelum.id),
  }
}

/** Langkah `sekali_per_sesi` yang sudah benar-benar ditanyakan (bukan dilewati). */
export function tandaiSudahDitanya(s: StatusTangga, sudah: ReadonlySet<number>): Set<number> {
  const baru = new Set(sudah)
  for (const j of s.jawaban) {
    const l = s.langkah.find(x => x.id === j.langkah_id)
    if (l?.sekali_per_sesi) baru.add(l.id)
  }
  return baru
}
