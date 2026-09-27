/**
 * Antrean kirim offline.
 *
 * Sinyal di kelas pesantren tidak bisa diandalkan, jadi penilaian TIDAK PERNAH
 * menunggu jaringan: hasil ketukan masuk localStorage seketika, dikirim
 * belakangan. RPC `simpan_penilaian` aman diulang, jadi kirim ulang tidak
 * pernah menggandakan.
 *
 * Dibuat sebagai factory yang menerima klien, bukan composable yang mengambil
 * sendiri, supaya bisa diuji dengan klien palsu tanpa menjalankan Nuxt.
 */
import { computed, reactive, ref } from 'vue'
import { simpanPenilaian, type Klien, type PayloadPenilaian } from './repo'

const KUNCI = 'sorogan.antrean'
const JEDA_MS = 15_000
/** Setelah sekian gagal beruntun, satu item dipindah ke "macet" supaya tidak
 *  menyumbat sisanya. Data tidak dibuang — ditampilkan supaya bisa ditangani. */
const BATAS_GAGAL = 5

interface Item { payload: PayloadPenilaian, gagal: number }

interface Tersimpan { antre: Item[], macet: Item[] }

function baca(): Tersimpan {
  if (typeof localStorage === 'undefined') return { antre: [], macet: [] }
  try {
    const isi = JSON.parse(localStorage.getItem(KUNCI) ?? '{}') as Partial<Tersimpan>
    return { antre: isi.antre ?? [], macet: isi.macet ?? [] }
  }
  catch {
    // Isi rusak lebih baik dibuang daripada membuat aplikasi tak bisa dibuka
    // sama sekali di tengah ujian.
    return { antre: [], macet: [] }
  }
}

export type Antrean = ReturnType<typeof buatAntrean>

export function buatAntrean(sb: Klien) {
  const awal = baca()
  const antre = ref<Item[]>(awal.antre)
  const macet = ref<Item[]>(awal.macet)
  let mengirim = false
  let timer: ReturnType<typeof setInterval> | undefined

  const tulis = () =>
    localStorage.setItem(KUNCI, JSON.stringify({ antre: antre.value, macet: macet.value }))

  function tambah(payload: PayloadPenilaian) {
    antre.value.push({ payload, gagal: 0 })
    tulis()
    void kirim()
  }

  async function kirim() {
    if (mengirim || antre.value.length === 0) return
    if (typeof navigator !== 'undefined' && !navigator.onLine) return
    mengirim = true
    try {
      while (antre.value.length > 0) {
        const item = antre.value[0]!
        try {
          await simpanPenilaian(sb, item.payload)
          antre.value.shift()
        }
        catch {
          item.gagal += 1
          if (item.gagal >= BATAS_GAGAL) {
            // Kemungkinan besar payload-nya sendiri yang bermasalah (mis. klaim
            // ustadz dicabut). Disingkirkan agar penilaian lain tetap terkirim,
            // TIDAK dibuang, dan ditampilkan ke penguji.
            macet.value.push(antre.value.shift()!)
            continue
          }
          break // kemungkinan cuma jaringan; coba lagi pada putaran berikutnya
        }
        finally { tulis() }
      }
    }
    finally { mengirim = false }
  }

  const saatOnline = () => { void kirim() }

  // `reactive`, bukan objek biasa: ref di dalam objek biasa TIDAK dibuka
  // otomatis di template, jadi `$antrean.jumlah > 0` akan membandingkan
  // objek ref dengan angka dan selalu bernilai true — bilah peringatan
  // muncul terus walau antrean kosong.
  return reactive({
    jumlah: computed(() => antre.value.length),
    macet,
    tambah,
    kirim,
    mulai() {
      if (typeof window === 'undefined') return
      window.addEventListener('online', saatOnline)
      timer = setInterval(saatOnline, JEDA_MS)
      void kirim()
    },
    hentikan() {
      if (typeof window === 'undefined') return
      window.removeEventListener('online', saatOnline)
      if (timer) clearInterval(timer)
    },
  })
}
