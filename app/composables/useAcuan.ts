import type { Database } from '#shared/types/database'
import { ambilAcuan, type Acuan } from '~/utils/repo'

const KUNCI = 'sorogan.acuan'

/**
 * Data acuan (santri, bank soal, tangga, ibarat) di-cache di localStorage.
 *
 * Bukan sekadar optimasi: tanpa ini, sesi penilaian berhenti total begitu
 * sinyal hilang. Data ini berubah sangat jarang, jadi cache basi bukan risiko
 * — beda dengan nilai, yang tidak pernah di-cache.
 */
export function useAcuan() {
  const sb = useSupabaseClient<Database>()
  const acuan = useState<Acuan | null>('acuan', () => null)
  const galat = useState<string | null>('acuan-galat', () => null)

  function dariCache(): Acuan | null {
    try { return JSON.parse(localStorage.getItem(KUNCI) ?? 'null') }
    catch { return null }
  }

  async function muat() {
    acuan.value ??= dariCache()
    try {
      const segar = await ambilAcuan(sb)
      acuan.value = segar
      localStorage.setItem(KUNCI, JSON.stringify(segar))
      galat.value = null
    }
    catch (e) {
      // Cache lama masih terpakai; sesi tetap bisa jalan. Hanya kalau belum
      // pernah memuat sama sekali, penguji perlu diberi tahu bahwa pemakaian
      // pertama di perangkat ini butuh sinyal.
      galat.value = acuan.value
        ? null
        : `Butuh sinyal untuk pemakaian pertama di perangkat ini. ${(e as Error).message}`
    }
  }

  return { acuan, galat, muat }
}
