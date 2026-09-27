import { describe, expect, it } from 'vitest'
import { bagikanBK2, tipeKurangStok, type Pengacak } from '../shared/domain/pembagian'
import { TIPE_BK2, type Soal, type TipeSoal } from '../shared/types/sorogan'

const tetap: Pengacak = daftar => [...daftar]   // deterministik untuk test

const bank = (perTipe: number): Soal[] =>
  TIPE_BK2.flatMap((tipe, t) =>
    Array.from({ length: perTipe }, (_, i) => ({
      id: t * 100 + i, ibarat_id: t * 100 + i, teks: `${tipe}-${i}`,
      tipe: tipe as TipeSoal, tingkat: 'BK2' as const, nomor_bank: t * 100 + i,
    })),
  )

const hitungTipe = (soal: Soal[]) =>
  Object.fromEntries(TIPE_BK2.map(t => [t, soal.filter(s => s.tipe === t).length]))

describe('bagikanBK2', () => {
  it('memberi jumlah yang SAMA untuk tiap tipe', () => {
    // Inti keadilannya. Kalau ini timpang, santri dinilai dengan beban berbeda
    // padahal nilainya diperlakukan setara — dan itu tidak terlihat di hasil.
    const dibagi = bagikanBK2(bank(15), 2, tetap)
    expect(dibagi).toHaveLength(8)
    expect(hitungTipe(dibagi)).toEqual({ ismiyah: 2, filiyah: 2, nawasikh: 2, tabi: 2 })
  })

  it('tetap merata pada jumlah lain', () => {
    expect(hitungTipe(bagikanBK2(bank(15), 3, tetap)))
      .toEqual({ ismiyah: 3, filiyah: 3, nawasikh: 3, tabi: 3 })
  })

  it('tidak pernah memberi soal yang sama dua kali', () => {
    const dibagi = bagikanBK2(bank(15), 3, tetap)
    expect(new Set(dibagi.map(s => s.id)).size).toBe(dibagi.length)
  })

  it('mengambil dari bank sungguhan lewat pengacak acak, tetap merata', () => {
    for (let i = 0; i < 25; i++) {
      expect(hitungTipe(bagikanBK2(bank(15), 2)))
        .toEqual({ ismiyah: 2, filiyah: 2, nawasikh: 2, tabi: 2 })
    }
  })

  it('tidak berhenti di tengah kalau satu tipe kurang stok', () => {
    // Ujian yang macet lebih buruk daripada komposisi timpang — tapi
    // tipeKurangStok() harus sudah memberi tahu sebelum sesi dimulai.
    const kurang = bank(15).filter(s => s.tipe !== 'tabi')
    expect(bagikanBK2(kurang, 2, tetap)).toHaveLength(6)
    expect(tipeKurangStok(kurang, 2)).toEqual(['tabi'])
  })
})

describe('tipeKurangStok', () => {
  it('diam kalau bank sehat', () => {
    expect(tipeKurangStok(bank(15), 2)).toEqual([])
  })
})
