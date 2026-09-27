import { describe, expect, it } from 'vitest'
import {
  jawab, langkahKini, mulaiTangga, mundur, susunTangga,
  tandaiSudahDitanya, tanggaSelesai,
} from '../shared/domain/tangga'
import type { Langkah, TipeSoal } from '../shared/types/sorogan'

const L = (id: number, urutan: number, tipe: TipeSoal, sekali = false): Langkah => ({
  id, urutan, tipe, pertanyaan: `p${urutan}`, bersyarat: null, sekali_per_sesi: sekali,
})

// Bentuknya meniru tangga ismiyah: pertanyaan definisi diselipkan di antaranya.
const SEMUA: Langkah[] = [
  L(3, 3, 'ismiyah'), L(1, 1, 'ismiyah'), L(2, 2, 'ismiyah', true),
  L(9, 1, 'nawasikh'),
]

describe('susunTangga', () => {
  it('menyaring per tipe dan mengurutkan, apa pun urutan datangnya', () => {
    expect(susunTangga(SEMUA, 'ismiyah').map(l => l.urutan)).toEqual([1, 2, 3])
    expect(susunTangga(SEMUA, 'nawasikh').map(l => l.id)).toEqual([9])
  })

  it("membuang pertanyaan definisi yang sudah ditanyakan di sesi ini", () => {
    const sisa = susunTangga(SEMUA, 'ismiyah', new Set([2]))
    expect(sisa.map(l => l.id)).toEqual([1, 3])
  })

  it('tidak membuang langkah biasa walau id-nya sudah tercatat', () => {
    // Hanya yang bertanda sekali_per_sesi yang boleh hilang.
    expect(susunTangga(SEMUA, 'ismiyah', new Set([1, 3])).map(l => l.id)).toEqual([1, 2, 3])
  })
})

describe('menjawab', () => {
  const mulai = () => mulaiTangga(susunTangga(SEMUA, 'ismiyah'))

  it('maju dan mencatat', () => {
    const s = jawab(mulai(), 'benar', 2.5)
    expect(s.posisi).toBe(1)
    expect(s.jawaban).toEqual([{ langkah_id: 1, verdict: 'benar', detik: 2.5 }])
    expect(langkahKini(s)?.id).toBe(2)
  })

  it('LEWATI maju tanpa meninggalkan baris apa pun', () => {
    // Pembeda terpenting: dilewati ≠ salah. Kalau ini bocor jadi baris
    // dengan verdict apa pun, nilai santri jatuh tanpa sebab.
    const s = jawab(mulai(), null)
    expect(s.posisi).toBe(1)
    expect(s.jawaban).toEqual([])
  })

  it('menghapus jawaban lama saat mundur, bukan menumpuknya', () => {
    let s = jawab(mulai(), 'salah')
    s = mundur(s)
    expect(s.posisi).toBe(0)
    expect(s.jawaban).toEqual([])
    s = jawab(s, 'benar')
    expect(s.jawaban).toEqual([{ langkah_id: 1, verdict: 'benar' }])
  })

  it('mundur di langkah pertama tidak melakukan apa-apa', () => {
    const s = mulai()
    expect(mundur(s)).toEqual(s)
  })

  it('selesai setelah langkah terakhir', () => {
    let s = mulai()
    expect(tanggaSelesai(s)).toBe(false)
    for (let i = 0; i < 3; i++) s = jawab(s, 'benar')
    expect(tanggaSelesai(s)).toBe(true)
    expect(langkahKini(s)).toBeNull()
    expect(jawab(s, 'benar')).toEqual(s)   // sudah habis, tidak berubah
  })
})

describe('tandaiSudahDitanya', () => {
  it('hanya menandai definisi yang benar-benar dijawab', () => {
    const s = jawab(jawab(mulaiTangga(susunTangga(SEMUA, 'ismiyah')), 'benar'), 'benar')
    expect([...tandaiSudahDitanya(s, new Set())]).toEqual([2])
  })

  it('tidak menandai definisi yang justru dilewati', () => {
    // Dilewati berarti belum pernah ditanyakan, jadi harus muncul lagi
    // di soal berikutnya.
    const s = jawab(jawab(mulaiTangga(susunTangga(SEMUA, 'ismiyah')), 'benar'), null)
    expect([...tandaiSudahDitanya(s, new Set())]).toEqual([])
  })
})
