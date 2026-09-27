/**
 * Aturan nilai. Murni — tanpa I/O, tanpa Vue, tanpa Supabase.
 *
 * Rumus ini hidup di DUA tempat: di sini (untuk nilai berjalan di layar) dan
 * di view `v_nilai_soal` / `v_nilai_santri` (untuk laporan). Duplikasi itu
 * disengaja — layar harus tetap menunjukkan nilai saat tidak ada sinyal —
 * tapi duplikasi berarti keduanya bisa menyimpang diam-diam.
 * `test/nilai.test.ts` memakukan keduanya ke angka yang sama persis.
 */
import type { Verdict } from '../types/sorogan'

export const BOBOT: Record<Verdict, number> = { benar: 1, dibantu: 0.5, salah: 0 }

export interface JawabanLangkah {
  langkah_id: number
  verdict: Verdict
  detik?: number
}

/** Cermin `round(x, 1)` di Postgres. */
const bulat1 = (n: number) => Math.round(n * 10) / 10

/**
 * Nilai satu soal = rata-rata langkah YANG TERCATAT pada soal itu.
 *
 * Langkah yang dilewati tidak ada barisnya, jadi tidak ikut membagi. Itu
 * sebabnya "tidak berlaku" tidak pernah menghukum santri.
 */
export function nilaiSoal(jawaban: readonly JawabanLangkah[]): number | null {
  if (jawaban.length === 0) return null
  const total = jawaban.reduce((a, j) => a + BOBOT[j.verdict], 0)
  return bulat1((total / jawaban.length) * 100)
}

/**
 * Nilai santri = rata-rata NILAI SOAL — bukan rata-rata seluruh langkah.
 *
 * Tangga tiap tipe beda panjang (lafad 9, ismiyah 9, fi'liyah 8, nawasikh 7,
 * tabi' 8). Kalau seluruh langkah dirata-ratakan datar, soal bertangga panjang
 * otomatis berbobot lebih besar, dan hasilnya TETAP terlihat wajar di layar.
 * Itulah kenapa urutannya dipagari test, bukan sekadar komentar.
 */
export function nilaiSesi(nilaiPerSoal: readonly (number | null)[]): number | null {
  const ada = nilaiPerSoal.filter((n): n is number => n !== null)
  if (ada.length === 0) return null
  return bulat1(ada.reduce((a, b) => a + b, 0) / ada.length)
}

/** Rumus yang KELIRU, disimpan untuk dibandingkan di test. Jangan dipakai. */
export function nilaiDatarKeliru(semuaJawaban: readonly JawabanLangkah[]): number | null {
  if (semuaJawaban.length === 0) return null
  const total = semuaJawaban.reduce((a, j) => a + BOBOT[j.verdict], 0)
  return bulat1((total / semuaJawaban.length) * 100)
}
