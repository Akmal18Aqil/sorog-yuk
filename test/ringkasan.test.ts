import { describe, expect, it } from 'vitest'
import { gabungKelemahan, gabungNilaiSantri } from '../shared/domain/ringkasan'

describe('gabungKelemahan', () => {
  it('menimbang dengan jumlah pengamatan, bukan merata-ratakan persentase', () => {
    // Santri A dinilai 1 kali dan kebetulan 100. Santri B dinilai 9 kali, rata 0.
    // Rata-rata polos = 50 → langkah ini terlihat sedang-sedang saja.
    // Yang benar = 10 → langkah ini yang paling perlu diajar ulang.
    const hasil = gabungKelemahan([
      { tipe: 'ismiyah', urutan: 5, pertanyaan: 'Termasuk mubtada apa?', n: 1, nilai: 100 },
      { tipe: 'ismiyah', urutan: 5, pertanyaan: 'Termasuk mubtada apa?', n: 9, nilai: 0 },
    ])
    expect(hasil).toHaveLength(1)
    expect(hasil[0]!.n).toBe(10)
    expect(hasil[0]!.nilai).toBe(10)
    expect(hasil[0]!.nilai).not.toBe(50)
  })

  it('mengurutkan yang terlemah lebih dulu', () => {
    const hasil = gabungKelemahan([
      { tipe: 'a', urutan: 1, pertanyaan: 'p1', n: 5, nilai: 90 },
      { tipe: 'a', urutan: 2, pertanyaan: 'p2', n: 5, nilai: 30 },
      { tipe: 'a', urutan: 3, pertanyaan: 'p3', n: 5, nilai: 60 },
    ])
    expect(hasil.map(h => h.pertanyaan)).toEqual(['p2', 'p3', 'p1'])
  })

  it('mengabaikan baris kosong dari view tanpa jatuh', () => {
    expect(gabungKelemahan([
      { tipe: null, urutan: null, pertanyaan: null, n: null, nilai: null },
    ])).toEqual([])
  })
})

describe('gabungNilaiSantri', () => {
  it('menimbang beberapa sesi dengan jumlah soalnya', () => {
    // 2 soal @100 dan 8 soal @50 → 60, bukan 75.
    const hasil = gabungNilaiSantri([
      { santri_id: 1, jml_soal: 2, nilai: 100 },
      { santri_id: 1, jml_soal: 8, nilai: 50 },
    ])
    expect(hasil).toEqual([{ santri_id: 1, jml_soal: 10, nilai: 60 }])
  })

  it('mengurutkan nilai tertinggi lebih dulu', () => {
    const hasil = gabungNilaiSantri([
      { santri_id: 1, jml_soal: 1, nilai: 40 },
      { santri_id: 2, jml_soal: 1, nilai: 90 },
    ])
    expect(hasil.map(h => h.santri_id)).toEqual([2, 1])
  })
})
