import { scrollBehavior } from './utils/scroll'

/**
 * Opsi router milik Nuxt. Bukan `nuxt.config` karena `scrollBehavior` TIDAK
 * termasuk kunci yang diterima di sana -- hanya lewat berkas ini.
 *
 * Isinya: kembali ke halaman yang tadi dibaca harus berakhir di tempat yang
 * sama, bukan selalu melompat ke atas. Alasan & tesnya di `utils/scroll.ts`.
 */
export default { scrollBehavior }
