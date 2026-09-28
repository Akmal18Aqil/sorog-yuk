import { beforeEach, describe, expect, it } from 'vitest'
import { lupaPosisi, scrollBehavior, type PosisiScroll } from '../app/utils/scroll'

/** Node tidak punya `window`; scrollBehavior harus tetap benar tanpanya. */
const g = globalThis as { window?: { scrollY: number; scrollX: number } }

const diPosisi = (top: number, left = 0) => { g.window = { scrollY: top, scrollX: left } }
const rute = (path: string) => ({ path })

beforeEach(() => {
  lupaPosisi()
  delete g.window
})

describe('perpindahan halaman', () => {
  it('tombol back browser selalu menang', () => {
    // `savedPosition` datang dari history browser. Mengabaikannya membuat
    // tombol back melompat ke atas -- bug yang paling dikeluhkan.
    const simpanan: PosisiScroll = { top: 900, left: 0 }
    expect(scrollBehavior(rute('/admin/kelas'), rute('/admin/kelompok'), simpanan)).toBe(simpanan)
  })

  it('halaman yang belum pernah dibuka mulai dari atas', () => {
    diPosisi(1500)
    expect(scrollBehavior(rute('/admin/kelas'), rute('/admin/kelompok'), null))
      .toEqual({ top: 0, left: 0 })
  })

  it('kembali ke halaman mengembalikan posisi terakhir', async () => {
    diPosisi(1500)
    scrollBehavior(rute('/admin/kelas-kuliah'), rute('/admin/kelompok'), null)

    diPosisi(0)
    const kembali = scrollBehavior(rute('/admin/kelompok'), rute('/admin/kelas-kuliah'), null)
    // Lewat Promise: halaman baru harus dirender dulu. Kalau tidak, posisinya
    // diterapkan ke kontainer kosong dan browser memotongnya lagi ke atas.
    expect(kembali).toBeInstanceOf(Promise)
    expect(await kembali).toEqual({ top: 1500, left: 0 })
  })

  it('menekan item nav yang sedang aktif tidak menggerakkan halaman', () => {
    // Tanpa aturan ini, klik ke halaman yang sama melempar scroll ke atas.
    expect(scrollBehavior(rute('/admin/kelas'), rute('/admin/kelas'), null)).toBe(false)
  })

  it('posisi tiap rute terpisah, tidak saling menimpa', async () => {
    // Skenario nyata, bukan angka acak: setiap panggilan juga MENYIMPAN
    // posisi halaman yang ditinggalkan, jadi `window` harus mencerminkan
    // halaman yang sedang dibuka -- kalau tidak, tes ini menguji dirinya sendiri.

    // Di /b tergulir 300, pindah ke /a (belum pernah dibuka).
    diPosisi(300)
    expect(scrollBehavior(rute('/a'), rute('/b'), null)).toEqual({ top: 0, left: 0 })

    // Di /a tergulir 700, kembali ke /b → harus ke 300, bukan ikut 700.
    diPosisi(700)
    expect(await scrollBehavior(rute('/b'), rute('/a'), null)).toEqual({ top: 300, left: 0 })

    // Kembali ke /a → harus ke 700, tidak ketimpa langkah sebelumnya.
    diPosisi(300)
    expect(await scrollBehavior(rute('/a'), rute('/b'), null)).toEqual({ top: 700, left: 0 })
  })

  it('posisi horizontal ikut disimpan', async () => {
    diPosisi(0, 240)
    scrollBehavior(rute('/a'), rute('/b'), null)
    diPosisi(0)
    expect(await scrollBehavior(rute('/b'), rute('/a'), null)).toEqual({ top: 0, left: 240 })
  })

  it('bekerja tanpa window (mis. saat build)', () => {
    expect(() => scrollBehavior(rute('/a'), rute('/b'), null)).not.toThrow()
  })
})
