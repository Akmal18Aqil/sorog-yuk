import { beforeEach, describe, expect, it } from 'vitest'
import { bersihkanCacheUstadz } from '../app/utils/keluar'

/**
 * Logout harus meninggalkan NOTHING di localStorage.
 *
 * `sorogan.ustadz` menyimpan nama mentor yang sedang login, dan `periksa()`
 * membacanya sebagai cadangan saat server tidak bisa dihubungi. Kalau logout
 * lewat sidebar (jalur paling sering di desktop) tidak membersihkannya,
 * mentor berikutnya di perangkat bersama akan melihat nama orang sebelumnya
 * -- dan `useUstadz.keluar` yang membersihkannya saja tidak cukup, karena
 * tidak semua logout lewat situ.
 */

// Node tidak punya localStorage; cukup bentuk yang dipakai di sini.
const simpanan = new Map<string, string>()
Object.defineProperty(globalThis, 'localStorage', {
  configurable: true,
  value: {
    getItem: (k: string) => simpanan.get(k) ?? null,
    setItem: (k: string, v: string) => void simpanan.set(k, v),
    removeItem: (k: string) => void simpanan.delete(k),
  },
})

describe('logout membersihkan cache', () => {
  beforeEach(() => {
    simpanan.set('sorogan.ustadz', '{"nama":"Ustadz Lama"}')
    simpanan.set('sorogan.acuan', '{"santri":[]}')
  })

  it('menghapus nama ustadz dan data acuan', () => {
    bersihkanCacheUstadz()
    expect(simpanan.get('sorogan.ustadz')).toBeUndefined()
    expect(simpanan.get('sorogan.acuan')).toBeUndefined()
  })

  it('tidak留下一pun yang bisa dibaca mentor berikutnya', () => {
    bersihkanCacheUstadz()
    expect([...simpanan.keys()]).toEqual([])
  })

  it('aman dipanggil dua kali (logout lalu login ulang di perangkat sama)', () => {
    expect(() => { bersihkanCacheUstadz(); bersihkanCacheUstadz() }).not.toThrow()
  })
})
