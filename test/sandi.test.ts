import { describe, expect, it } from 'vitest'
import { PANJANG_MIN, periksaSandiBaru } from '../app/utils/sandi'

const LAMA = 'rahasia-lama'

describe('ganti password', () => {
  it('menerima password baru yang cukup panjang dan sesuai', () => {
    expect(periksaSandiBaru('sandi-baru-kuat', 'sandi-baru-kuat', LAMA)).toBeNull()
  })

  it('password kosong ditolak sebagai "wajib diisi", bukan "terlalu pendek"', () => {
    // Kalau yang muncul "minimal 8 karakter", orang mengira tinggal menambah
    // spasi. "Wajib diisi"-addresses masalah yang sebenarnya.
    expect(periksaSandiBaru('', '', LAMA)).toBe('Password baru wajib diisi.')
  })

  it('password di bawah minimum ditolak', () => {
    const pendek = 'a'.repeat(PANJANG_MIN - 1)
    expect(periksaSandiBaru(pendek, pendek, LAMA)).toContain(String(PANJANG_MIN))
    // Tepat di batas harus lolos -- off-by-one di sini mengunci orang.
    const pas = 'a'.repeat(PANJANG_MIN)
    expect(periksaSandiBaru(pas, pas, LAMA)).toBeNull()
  })

  it('ulangan yang tidak sama ditolak', () => {
    // Salah ketik adalah penyebab paling sering orang mengira passwordnya
    // sudah diganti padahal tidak.
    expect(periksaSandiBaru('sandi-baru-kuat', 'sandi-baru-kuatx', LAMA))
      .toBe('Ulangi password tidak sama.')
  })

  it('password baru harus beda dari yang lama', () => {
    // Kalau sama, orang mengira sudah mengganti padahal tidak ada yang berubah.
    expect(periksaSandiBaru(LAMA, LAMA, LAMA))
      .toBe('Password baru harus berbeda dari yang lama.')
  })

  it('cek panjang jalan sebelum cek ulang', () => {
    // Dua-duanya salah; yang lebih mendasar lebih dulu dilaporkan.
    expect(periksaSandiBaru('pendek', 'lain', LAMA)).toContain(String(PANJANG_MIN))
  })
})
