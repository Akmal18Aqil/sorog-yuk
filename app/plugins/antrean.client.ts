import type { Database } from '#shared/types/database'
import { buatAntrean, type Antrean } from '~/utils/antrean'

/**
 * Satu antrean untuk seluruh aplikasi. Dijadikan plugin, bukan composable
 * biasa, supaya pendengar `online` dan timer 15 detik dipasang TEPAT SEKALI —
 * kalau tiap komponen memasangnya sendiri, satu penilaian bisa dikirim
 * berkali-kali bersamaan.
 */
export default defineNuxtPlugin(() => {
  const antrean = buatAntrean(useSupabaseClient<Database>())
  antrean.mulai()
  return { provide: { antrean } }
})

declare module '#app' {
  interface NuxtApp { $antrean: Antrean }
}
