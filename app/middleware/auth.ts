/**
 * Middleware autentikasi berbasis role.
 *
 * Cek role user → redirect ke route yang sesuai:
 *  - /admin/* → harus superadmin
 *  - /mulai, /nilai, /hasil, /kenaikan → harus ustadz
 *  - /santri/* → harus santri
 *
 * Penjaga sebenarnya adalah RLS. Ini hanya kenyamanan navigasi.
 */
export default defineNuxtRouteMiddleware(async (to) => {
  const { role, deteksiRole, idSesi } = useAuth()

  // Sudah punya role di state → skip
  if (role.value) {
    return redirectIfWrongRole(role.value, to.path)
  }

  // Cek sesi
  const uid = await idSesi()
  if (!uid) return navigateTo('/')

  // Deteksi role dari database
  const r = await deteksiRole()
  if (!r) return navigateTo('/')

  return redirectIfWrongRole(r, to.path)
})

function redirectIfWrongRole(role: string, path: string) {
  // Admin routes
  if (path.startsWith('/admin')) {
    if (role !== 'superadmin') return navigateTo(role === 'ustadz' ? '/mulai' : '/santri/dashboard')
    return
  }

  // Santri routes
  if (path.startsWith('/santri')) {
    if (role !== 'santri') return navigateTo(role === 'superadmin' ? '/admin' : '/mulai')
    return
  }

  // Ustadz routes (mulai, nilai, hasil, kenaikan)
  if (role !== 'ustadz') {
    if (role === 'superadmin') return navigateTo('/admin')
    if (role === 'santri') return navigateTo('/santri/dashboard')
    return navigateTo('/')
  }
}
