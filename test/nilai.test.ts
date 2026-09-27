import { describe, expect, it } from 'vitest'
import { nilaiDatarKeliru, nilaiSesi, nilaiSoal, type JawabanLangkah } from '../shared/domain/nilai'
import type { Verdict } from '../shared/types/sorogan'

const jwb = (...v: Verdict[]): JawabanLangkah[] =>
  v.map((verdict, i) => ({ langkah_id: i + 1, verdict }))

describe('nilai satu soal', () => {
  it('menghitung dibantu sebagai setengah, bukan nol atau satu', () => {
    expect(nilaiSoal(jwb('dibantu', 'dibantu'))).toBe(50)
    expect(nilaiSoal(jwb('benar', 'salah'))).toBe(50)
    expect(nilaiSoal(jwb('benar', 'dibantu'))).toBe(75)
  })

  it('tidak menghukum langkah yang dilewati', () => {
    // Tangga nawasikh punya 7 langkah; hanya 5 yang berlaku dan semuanya benar.
    // Dua yang dilewati tidak punya baris, jadi tidak ikut membagi.
    expect(nilaiSoal(jwb('benar', 'benar', 'benar', 'benar', 'benar'))).toBe(100)
  })

  it('mengembalikan null kalau tak satu pun langkah tercatat', () => {
    expect(nilaiSoal([])).toBeNull()
  })
})

describe('nilai santri', () => {
  // Skenario ini SAMA PERSIS dengan db/003_check.sql. Kedua sisi — TypeScript
  // di layar dan SQL di laporan — wajib menghasilkan angka yang identik.
  // Kalau salah satunya digeser, test ini yang jatuh duluan.
  const soalA = jwb('benar', 'benar', 'benar', 'benar', 'dibantu', 'salah', 'salah', 'salah', 'salah')
  const soalB = jwb('benar', 'benar', 'benar', 'benar', 'benar')

  it('cocok dengan angka yang dihasilkan view Postgres', () => {
    expect(nilaiSoal(soalA)).toBe(50)      // 4.5 / 9
    expect(nilaiSoal(soalB)).toBe(100)     // 5 / 5
    expect(nilaiSesi([nilaiSoal(soalA), nilaiSoal(soalB)])).toBe(75)
  })

  it('merata-ratakan per soal, bukan seluruh langkah', () => {
    // Inti seluruh aturan nilai. Rumus datar memberi bobot lebih besar pada
    // soal bertangga panjang, dan hasilnya tetap terlihat wajar di layar —
    // itulah kenapa hanya test yang bisa menangkapnya.
    const benar = nilaiSesi([nilaiSoal(soalA), nilaiSoal(soalB)])
    const keliru = nilaiDatarKeliru([...soalA, ...soalB])
    expect(benar).toBe(75)
    expect(keliru).toBe(67.9)
    expect(benar).not.toBe(keliru)
  })

  it('mengabaikan soal yang belum dinilai sama sekali', () => {
    expect(nilaiSesi([100, null, 50])).toBe(75)
    expect(nilaiSesi([null, null])).toBeNull()
  })
})
