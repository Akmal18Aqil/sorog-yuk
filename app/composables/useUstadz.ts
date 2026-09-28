import type { Database } from '#shared/types/database'
import type { Ustadz } from '#shared/types/sorogan'
import { ambilUstadz, hubungkanUstadz } from '~/utils/repo'

const KUNCI = 'sorogan.ustadz'

/**
 * Identitas penguji (ustadz).
 *
 * Login saja tidak cukup: akun harus terhubung ke satu baris `ustadz` dengan
 * role='ustadz'. Superadmin tidak menggunakan composable ini.
 */
export function useUstadz() {
  const sb = useSupabaseClient<Database>()
  const pengguna = useSupabaseUser()
  const ustadz = useState<Ustadz | null>('ustadz', () => null)

  function dariCache(): Ustadz | null {
    try { return JSON.parse(localStorage.getItem(KUNCI) ?? 'null') }
    catch { return null }
  }

  async function idSesi(): Promise<string | null> {
    const { data } = await sb.auth.getSession()
    return data.session?.user.id ?? null
  }

  /** true kalau akun sudah terhubung ke seorang ustadz (role='ustadz'). */
  async function periksa(): Promise<boolean> {
    const uid = await idSesi()
    if (!uid) { ustadz.value = null; return false }
    try {
      const data = await ambilUstadz(sb, uid)
      ustadz.value = data
      if (data) localStorage.setItem(KUNCI, JSON.stringify(data))
    }
    catch {
      ustadz.value ??= dariCache()
    }
    return ustadz.value !== null
  }

  async function hubungkan(ustadzId: number) {
    await hubungkanUstadz(sb, ustadzId)
    await periksa()
  }

  /**
   * Logout.
   *
   * Sama seperti `useAuth.keluar`: WAJIB pindah ke `/` di akhir, kalau tidak
   * orang tetap berdiri di halaman yang tadi. Urutannya juga sama: `signOut`
   * dulu, baru `navigateTo`, supaya middleware tidak mengembalikannya lagi
   * sebelum sesi benar-benar putus.
   */
  async function keluar() {
    localStorage.removeItem(KUNCI)
    localStorage.removeItem('sorogan.acuan')
    ustadz.value = null
    await sb.auth.signOut()
    await navigateTo('/')
  }

  return { ustadz, pengguna, idSesi, periksa, hubungkan, keluar }
}
