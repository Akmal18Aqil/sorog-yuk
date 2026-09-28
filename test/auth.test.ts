import { describe, expect, it } from 'vitest'
import { hanyaSuperadmin } from '../app/utils/nav'

/**
 * Rantai middleware menentukan boleh-tidaknya sebuah halaman.
 *
 * Bug yang paling mahal di sini adalah halaman yang DITOLAK middleware: tidak
 * ada error, tidak ada toast, tidak ada apa-apa -- hanya "kenapa saya
 * terus berbalik?" yang tidak terjawab.
 */

describe('halaman khusus superadmin', () => {
  it('/super-adminn termasuk halaman superadmin', () => {
    // Inilah yang diperbaiki: path ini tidak berawalan `/admin`, jadi
    // sebelumnya jatuh ke cabang "ustadz" di bawah dan superadmin yang
    // membukanya justru diarahkan balik ke `/admin` -- halaman mustahil dibuka.
    expect(hanyaSuperadmin('/super-adminn')).toBe(true)
  })

  it('semua halaman /admin tetap khusus superadmin', () => {
    for (const p of ['/admin', '/admin/kelas', '/admin/kelola-user', '/admin/kelas-kuliah']) {
      expect(hanyaSuperadmin(p)).toBe(true)
    }
  })

  it('halaman lain BUKAN khusus superadmin', () => {
    // Kalau salah satu ikut,true, superadmin akan dialihkan dari /mulai atau
    // /santri/dashboard setiap kali membuka halaman itu.
    for (const p of ['/', '/mulai', '/nilai', '/hasil', '/kenaikan', '/santri/dashboard', '/daftar-santri']) {
      expect(hanyaSuperadmin(p)).toBe(false)
    }
  })

  it('path kosong tidak dianggap halaman admin', () => {
    expect(hanyaSuperadmin('')).toBe(false)
  })
})
