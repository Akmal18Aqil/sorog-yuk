/** YYYY-MM-DD menurut waktu setempat — bukan UTC. Sesi malam di Indonesia
 *  tidak boleh tercatat sebagai hari berikutnya. */
export const hariIni = () => new Date().toLocaleDateString('sv')

export const tanggalPanjang = (iso: string) =>
  new Date(`${iso}T00:00:00`).toLocaleDateString('id-ID', {
    day: 'numeric', month: 'long', year: 'numeric',
  })
