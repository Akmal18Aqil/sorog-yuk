import type { Database } from '#shared/types/database'

type Role = 'superadmin' | 'ustadz' | 'santri' | null

/**
 * Auth composable: login, register, logout, role check.
 *
 * Role ditentukan oleh:
 *  - auth_id di tabel ustadz (role column) → 'superadmin' | 'ustadz'
 *  - auth_id di tabel santri → 'santri'
 *  - tidak ada → null
 */
export function useAuth() {
  const sb = useSupabaseClient<Database>()
  const pengguna = useSupabaseUser()
  const role = useState<Role>('role', () => null)

  async function idSesi(): Promise<string | null> {
    const { data } = await sb.auth.getSession()
    return data.session?.user.id ?? null
  }

  /**
   * Deteksi role dari database.
   * Cek ustadz dulu (superadmin/ustadz), lalu santri.
   */
  async function deteksiRole(): Promise<Role> {
    const uid = await idSesi()
    if (!uid) { role.value = null; return null }

    // Cek ustadz (superadmin atau ustadz)
    const { data: ustadz } = await sb.from('ustadz')
      .select('role')
      .eq('auth_id', uid)
      .maybeSingle()

    if (ustadz) {
      role.value = ustadz.role as Role
      return role.value
    }

    // Cek santri
    const { data: santri } = await sb.from('santri')
      .select('id')
      .eq('auth_id', uid)
      .maybeSingle()

    if (santri) {
      role.value = 'santri'
      return 'santri'
    }

    role.value = null
    return null
  }

  /** Login pakai email + password. */
  async function login(email: string, sandi: string): Promise<void> {
    const { error } = await sb.auth.signInWithPassword({ email, password: sandi })
    if (error) throw new Error(error.message)
  }

  /** Register santri: signup Supabase Auth + insert santri record. */
  async function registerSantri(email: string, sandi: string, nama: string, tingkat: string = 'BK1'): Promise<void> {
    // 1. Buat akun Supabase Auth
    const { data, error } = await sb.auth.signUp({ email, password: sandi })
    if (error) throw new Error(error.message)
    if (!data.session) throw new Error('Akun dibuat. Cek email untuk konfirmasi, lalu masuk.')

    // 2. Insert santri record
    const { error: rpcError } = await sb.rpc('daftar_santri', {
      p_nama: nama,
      p_tingkat: tingkat,
    })
    if (rpcError) throw new Error(rpcError.message)
  }

  /** Daftar ustad pakai kode undangan. */
  async function daftarUstadz(kode: string): Promise<void> {
    const { error } = await sb.rpc('daftar_ustadz', { p_kode: kode })
    if (error) throw new Error(error.message)
  }

  /** Logout. */
  async function keluar(): Promise<void> {
    role.value = null
    await sb.auth.signOut()
  }

  return { pengguna, role, idSesi, deteksiRole, login, registerSantri, daftarUstadz, keluar }
}
