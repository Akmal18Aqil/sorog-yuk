/**
 * Pembagian soal BK 2.
 *
 * Empat tipe tarkib tidak sama beratnya. Kalau penguji memilih sendiri,
 * santri yang kebagian 5 soal nawasikh dinilai jauh lebih keras daripada
 * yang kebagian 5 soal ismiyah — padahal nilainya diperlakukan setara.
 * Di kertas ketimpangan ini tidak pernah terlihat.
 *
 * Karena itu pembagiannya merata per tipe dan diacak, dan penguji tidak
 * memilih apa pun. Efek sampingnya sama pentingnya: tiap santri dijamin
 * punya data di keempat tipe, tanpa itu diagnostik per tipe berlubang.
 */
import { TIPE_BK2, type Soal, type TipeBK2 } from '../types/sorogan'

export type Pengacak = <T>(daftar: readonly T[]) => T[]

/** Pengacak bawaan. Disuntikkan sebagai argumen supaya test bisa deterministik. */
export const acakBawaan: Pengacak = daftar =>
  daftar
    .map(v => [Math.random(), v] as const)
    .sort((a, b) => a[0] - b[0])
    .map(([, v]) => v)

export function bagikanBK2(
  bank: readonly Soal[],
  perTipe: number,
  acak: Pengacak = acakBawaan,
): Soal[] {
  const terpilih = TIPE_BK2.flatMap((tipe: TipeBK2) =>
    // Kalau satu tipe kekurangan stok, ambil yang ada. Lebih baik sesi berjalan
    // dengan komposisi timpang daripada ujian berhenti di tengah — tapi
    // `cukupUntukBK2()` memberi tahu itu SEBELUM sesi dimulai.
    acak(bank.filter(s => s.tipe === tipe)).slice(0, perTipe),
  )
  return acak(terpilih)
}

/** Tipe mana yang stoknya kurang. Kosong = bank sehat. */
export function tipeKurangStok(bank: readonly Soal[], perTipe: number): TipeBK2[] {
  return TIPE_BK2.filter(tipe => bank.filter(s => s.tipe === tipe).length < perTipe)
}
