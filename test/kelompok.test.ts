import { describe, expect, it } from 'vitest'
import { kelasBerisiKelompok, kelompokKelas, kelompokTanpaKelas } from '../shared/domain/kelompok'
import type { Kelompok } from '../shared/types/sorogan'

/**
 * Nama kelompok berulang antar kelas: tiap kelas punya "Kelompok 1" sendiri.
 * Test ini menjaga satu hal yang tidak kelihatan sampai terjadi: setelah
 * BK2 dibuat, mentor di /mulai masih melihat kelompok BK1 -- atau tidak
 * melihat kelompoknya sendiri sama sekali.
 */

const k = (id: number, nama: string, tingkat: string | null): Kelompok =>
  ({ id, nama, urutan: id, periode: null, jenis: 'sorogan', tingkat })

// Bentuk data yang sebenarnya: BK1 sudah diisi, BK2 baru dibuat, dan ada
// kelompok terjemah yang belum ditentukan kelasnya.
const data: Kelompok[] = [
  k(1, 'Kelompok 1', 'BK1'),
  k(2, 'Kelompok 2', 'BK1'),
  k(3, 'Kelompok 3', 'BK1'),
  k(4, 'Kelompok 1', 'BK2'),
  k(5, 'Kelompok 2', 'BK2'),
  k(6, 'Kelompok Terjemah', null),
]

describe('kelas yang punya kelompok', () => {
  it('hanya kelas yang benar-benar punya kelompok', () => {
    // BK3 dan TR ada di master `kelas` tapi belum punya kelompok: menampilkan
    // tabnya berarti menyediakan jalan menuju layar kosong.
    expect(kelasBerisiKelompok(data)).toEqual(['BK1', 'BK2'])
  })

  it('urut kelas, bukan urut database', () => {
    const acak = [k(9, 'Kelompok 1', 'BK2'), k(8, 'Kelompok 1', 'BK1')]
    expect(kelasBerisiKelompok(acak)).toEqual(['BK1', 'BK2'])
  })

  it('kelas tanpa kelompok sama sekali tidak muncul', () => {
    expect(kelasBerisiKelompok([])).toEqual([])
  })

  it('kelas di luar yang dikenal aplikasi tidak dianggap kelas', () => {
    // Kalau ini lolos, `mulai()` menerima tingkat yang tidak dipahami
    // `useSesi` dan alur ujiannya jadi tidak pasti.
    expect(kelasBerisiKelompok([k(7, 'Kelompok 1', 'BK3')])).toEqual([])
  })
})

describe('kelompok per kelas', () => {
  it('hanya kelompok kelas itu, walaupun namanya sama', () => {
    // Inti fitur ini. "Kelompok 1" ada di dua kelas; yang boleh tampil hanya
    // milik kelas yang sedang dipilih.
    expect(kelompokKelas(data, 'BK2').map(x => x.id)).toEqual([4, 5])
    expect(kelompokKelas(data, 'BK1').map(x => x.id)).toEqual([1, 2, 3])
  })

  it('kelompok tanpa kelas tidak bocor ke kelas mana pun', () => {
    for (const t of ['BK1', 'BK2'] as const) {
      expect(kelompokKelas(data, t).map(x => x.nama)).not.toContain('Kelompok Terjemah')
    }
  })
})

describe('kelompok yang kelasnya belum jelas', () => {
  it('NULL dan kode tak dikenal dua-duanya dilaporkan', () => {
    // Keduanya sama-sama tidak bisa dinilai, jadi keduanya harus kelihatan.
    const dilaporkan = kelompokTanpaKelas([...data, k(7, 'Kelompok 9', 'BK3')])
    expect(dilaporkan.map(x => x.id)).toEqual([6, 7])
  })

  it('tidak ada yang hilang antara yang tampil dan yang dilaporkan', () => {
    // Jaring pengaman terhadap perubahan berikutnya: setiap kelompok harus
    // bisa ditemukan entah lewat kelasnya atau lewat peringatan ini.
    const tampil = ['BK1', 'BK2'] as const
    const terlihat = new Set([
      ...tampil.flatMap(t => kelompokKelas(data, t).map(x => x.id)),
      ...kelompokTanpaKelas(data).map(x => x.id),
    ])
    expect(terlihat.size).toBe(data.length)
  })
})
