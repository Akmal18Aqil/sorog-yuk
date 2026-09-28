import { describe, expect, it } from 'vitest'
import { halamanSendiri, navUntuk, navUtama, perluSidebar } from '../app/utils/nav'

describe('navigasi', () => {
  it('tidak memberi apa pun kalau belum masuk', () => {
    expect(navUntuk(null)).toEqual([])
    expect(navUtama(null)).toEqual([])
  })

  it('setiap role hanya melihat halamannya sendiri', () => {
    const admin = navUntuk('superadmin').map(i => i.to)
    const ustadz = navUntuk('ustadz').map(i => i.to)
    const santri = navUntuk('santri').map(i => i.to)

    // Ancaman utama: tautan ke halaman yang tidak ada akan menampilkan
    // layar kosong tanpa penjelasan. /laporan halaman bersama dua role,
    // jadi dikecualikan dari keharusan berawalan /admin.
    expect(admin.every(p => p.startsWith('/admin') || p === '/laporan')).toBe(true)
    expect(ustadz.every(p => ['/mulai', '/laporan', '/hasil', '/kenaikan'].includes(p))).toBe(true)
    expect(santri).toEqual(['/santri/dashboard'])

    // /laporan satu-satunya halaman yang boleh dimiliki dua role sekaligus.
    const semua = [...admin, ...ustadz, ...santri]
    const ganda = semua.filter((p, i) => semua.indexOf(p) !== i)
    expect(ganda.every(p => p === '/laporan')).toBe(true)
  })

  it('laporan ada di sidebar superadmin tapi tidak memakan bottom nav', () => {
    // Bottom nav superadmin sudah 5 item; laporan dibuka dari sidebar.
    const semua = navUntuk('superadmin')
    const laporan = semua.find(i => i.to === '/laporan')
    expect(laporan).toBeTruthy()
    expect(laporan!.utama).toBe(false)
    expect(navUtama('superadmin').map(i => i.to)).not.toContain('/laporan')
  })

  it('bottom nav tidak lebih dari lima item', () => {
    // Lima item di 360px menyisakan 72px tiap item. Enam item membuat
    // label "Kelompok" tidak lagi muat satu baris.
    for (const role of ['superadmin', 'ustadz', 'santri'] as const) {
      expect(navUtama(role).length).toBeLessThanOrEqual(5)
    }
  })

  it('sidebar memuat lebih banyak dari bottom nav', () => {
    // Kalau sama persis, kolom "utama" tidak ada gunanya dan daftar
    // kedua shell bisa dibuang.
    expect(navUntuk('superadmin').length).toBeGreaterThan(navUtama('superadmin').length)
  })

  it('halaman pertama selalu ada untuk sidebar', () => {
    for (const role of ['superadmin', 'ustadz', 'santri'] as const) {
      expect(navUntuk(role)[0]?.to).toBeTruthy()
    }
  })

  it('kelas kuliah ada di sidebar tapi tidak memakan bottom nav', () => {
    // Kelas kuliah jarang dipakai, dan tombolnya merusak (naik semester),
    // jadi cukup di sidebar.
    const semua = navUntuk('superadmin')
    const kuliah = semua.find(i => i.to === '/admin/kelas-kuliah')
    expect(kuliah).toBeTruthy()
    expect(kuliah!.utama).toBe(false)
    expect(navUtama('superadmin').map(i => i.to)).not.toContain('/admin/kelas-kuliah')
  })
})

describe('halaman yang berdiri sendiri', () => {
  it('login dan pendaftaran tidak punya kerangka', () => {
    expect(halamanSendiri('/')).toBe(true)
    expect(halamanSendiri('/daftar-santri')).toBe(true)
    expect(halamanSendiri('/mulai')).toBe(false)
    expect(halamanSendiri('/admin')).toBe(false)
    expect(halamanSendiri('/santri/dashboard')).toBe(false)
  })

  it('sidebar TIDAK muncul di login walau sudah lebar dan sudah masuk', () => {
    // Kasus yang paling mudah lolos: begitu sesi terdeteksi, `role` terisi,
    // lalu halaman login sempat berkedip memakai sidebar sebelum middleware
    // dialihkan. Syarat "sudah masuk" saja tidak cukup menyakikannya.
    for (const p of ['/', '/daftar-santri']) {
      for (const role of ['superadmin', 'ustadz', 'santri'] as const) {
        expect(perluSidebar(p, role, true)).toBe(false)
      }
    }
  })

  it('sidebar muncul di halaman dalam hanya kalau lebar DAN sudah masuk', () => {
    expect(perluSidebar('/mulai', 'ustadz', true)).toBe(true)
    expect(perluSidebar('/admin', 'superadmin', true)).toBe(true)
    // Terlalu sempit, atau belum masuk: tidak ada sidebar.
    expect(perluSidebar('/mulai', 'ustadz', false)).toBe(false)
    expect(perluSidebar('/mulai', null, true)).toBe(false)
  })
})
