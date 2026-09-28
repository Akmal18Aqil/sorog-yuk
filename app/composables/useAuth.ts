import type { Database } from '#shared/types/database'
import { bersihkanCacheUstadz } from '~/utils/keluar'

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

  /**
   * Logout.
   *
   * WAJIB pindah ke `/` di akhir. Tanpa itu, orang tetap berdiri di halaman
   * yang tadi dengan data yang sudah terlanjur terambil di layar -- dan
   * middleware hanya jalan saat navigasi, jadi halaman itu tidak akan
   * membersihkan dirinya sendiri.
   *
   * Urutannya: `signOut` DULU, baru `navigateTo`. Kalau navigasi duluan,
   * middleware masih membaca sesi yang belum putus dan mengembalikannya lagi
   * ke halaman admin -- persis gejala "keluar tapi malah balik ke /admin".
   *
   * Cache ustadz ikut dibuang di sini juga, bukan cuma di `useUstadz.keluar`:
   * tombol "Keluar" yang paling sering dipakai justru yang di sidebar, dan
   * dia memanggil fungsi INI. Kalau cache-nya tertinggal, orang berikutnya
   * yang memakai perangkat bersama dan kebetulan offline masih membaca nama
   * ustadz sebelumnya dari `localStorage`.
   */
  async function keluar(): Promise<void> {
    await sb.auth.signOut()
    role.value = null
    bersihkanCacheUstadz()
    await navigateTo('/')
  }

  /**
   * Ganti password akun yang SEDANG login.
   *
   * Password lama diverifikasi lebih dulu, dan itu bukan formalitas: sesi
   * login tersimpan di localStorage, jadi siapa pun yang memakai perangkat
   * yang tidak terkunci bisa mengganti password tanpa jejak, lalu asatidz
   * terkunci tanpa bisa minta bantuan. Meminta password lama mengubah
   * "sesi ini terbuka" menjadi "orang yang benar-benar tahu".
   *
   * Verifikasi lewat `signInWithPassword`, bukan `reauthenticate` (yang untuk
   * MFA). Password tidak pernah masuk ke kode kita: yang dipakai hanya status
   * berhasil atau tidaknya.
   *
   * Tidak memakai service_role, jadi ini tidak bisa dipakai untuk mengubah
   * password orang lain -- itu terpisah, dan tidak ada di sini.
   */
  async function gantiPassword(lama: string, baru: string): Promise<void> {
    const email = pengguna.value?.email
    if (!email) throw new Error('Email akun tidak terbaca. Masuk ulang, lalu coba lagi.')

    const cek = await sb.auth.signInWithPassword({ email, password: lama })
    if (cek.error) {
      // Pesan asli dari server sengaja tidak ditampilkan: "Invalid login
      // credentials" membingungkan yang salah ketik, dan tidak acrescenta
      // informasi apa pun.
      throw new Error('Password lama salah.')
    }

    const { error } = await sb.auth.updateUser({ password: baru })
    if (error) throw new Error(error.message)
  }

  return { pengguna, role, idSesi, deteksiRole, login, registerSantri, daftarUstadz, keluar, gantiPassword }
}
