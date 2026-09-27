import {
  JML_SOAL_BK1, PER_TIPE_BK2,
  type Ibarat, type Kelompok, type Mode, type Santri, type Soal,
  type Tingkat, type TipeSoal, type Verdict,
} from '#shared/types/sorogan'
import { nilaiSesi, nilaiSoal } from '#shared/domain/nilai'
import { bagikanBK2 } from '#shared/domain/pembagian'
import {
  jawab as jawabDomain, langkahKini, mulaiTangga, mundur as mundurDomain,
  susunTangga, tandaiSudahDitanya, tanggaSelesai, type StatusTangga,
} from '#shared/domain/tangga'
import { hariIni } from '~/utils/tanggal'

const KUNCI = 'sorogan.sesi'
const KUNCI_SELESAI = 'sorogan.selesai'

/** Soal yang sedang dikerjakan. BK2 datang dari bank; BK1 lahir dari ketukan. */
export interface SoalAktif {
  tipe: TipeSoal
  teks: string
  soalId?: number
  ibaratId?: number
  lafad?: string
  nomorBank?: number | null
}

export interface SesiAktif {
  santri: Santri
  kelompok: Kelompok | null
  tingkat: Tingkat
  mode: Mode
  ke: number
  daftar: Soal[] | null          // BK2 saja
  sudahDitanya: number[]
  nilaiPerSoal: (number | null)[]
  soal: SoalAktif | null
  tangga: StatusTangga | null
}

/**
 * Orkestrasi satu sesi penilaian.
 *
 * Semua ATURANnya ada di `shared/domain` dan sudah diuji tanpa merender apa
 * pun. Yang tinggal di sini hanya penjahitan: memilih ibarat, mengirim ke
 * antrean, dan menyimpan kemajuan.
 */
export function useSesi() {
  const { $antrean } = useNuxtApp()
  const { acuan } = useAcuan()
  const sesi = useState<SesiAktif | null>('sesi', () => null)
  const ibaratKini = useState<Ibarat | null>('ibarat-kini', () => null)
  let jamLangkah = 0

  // Santri mana di kelompok ini yang sudah dinilai HARI INI, di perangkat ini.
  // Sengaja dari localStorage, bukan query: ustadz menggarap satu kelompok
  // berurutan dan perlu tahu sudah sampai mana walau tidak ada sinyal.
  const selesaiHariIni = useState<number[]>('selesai-hari-ini', () => {
    try {
      const t = JSON.parse(localStorage.getItem(KUNCI_SELESAI) ?? 'null')
      return t?.tanggal === hariIni() ? (t.santri ?? []) : []
    }
    catch { return [] }
  })

  function tandaiSelesai(santriId: number) {
    if (!selesaiHariIni.value.includes(santriId)) selesaiHariIni.value.push(santriId)
    localStorage.setItem(KUNCI_SELESAI, JSON.stringify({
      tanggal: hariIni(), santri: selesaiHariIni.value,
    }))
  }

  const target = computed(() =>
    !sesi.value ? 0 : sesi.value.tingkat === 'BK1' ? JML_SOAL_BK1 : (sesi.value.daftar?.length ?? 0))

  const selesai = computed(() => !!sesi.value && sesi.value.ke >= target.value)
  const langkahSekarang = computed(() => sesi.value?.tangga ? langkahKini(sesi.value.tangga) : null)
  const nilaiBerjalan = computed(() => sesi.value ? nilaiSesi(sesi.value.nilaiPerSoal) : null)

  // ——— penyimpanan kemajuan ———
  // Tanpa ini, reload di tengah sesi membuat penomoran soal mulai dari 1 lagi
  // dan MENIMPA penilaian yang sudah tersimpan (RPC-nya upsert per urutan).
  // Hasilnya rekaman campuran yang tidak ketahuan salahnya.
  function simpanKemajuan() {
    if (!sesi.value) { localStorage.removeItem(KUNCI); return }
    const s = sesi.value
    localStorage.setItem(KUNCI, JSON.stringify({
      santriId: s.santri.id, kelompokId: s.kelompok?.id ?? null,
      tingkat: s.tingkat, mode: s.mode, ke: s.ke,
      daftarId: s.daftar?.map(x => x.id) ?? null,
      sudahDitanya: s.sudahDitanya, nilaiPerSoal: s.nilaiPerSoal,
    }))
  }

  function pulihkan(): boolean {
    if (!acuan.value) return false
    let t: any
    try { t = JSON.parse(localStorage.getItem(KUNCI) ?? 'null') }
    catch { return false }
    if (!t) return false

    const santri = acuan.value.santri.find(x => x.id === t.santriId)
    if (!santri) return false
    const daftar: Soal[] | null = t.daftarId
      ? t.daftarId.flatMap((id: number) => acuan.value!.soal.filter(s => s.id === id))
      : null

    sesi.value = {
      santri,
      kelompok: acuan.value.kelompok.find(k => k.id === t.kelompokId) ?? null,
      tingkat: t.tingkat, mode: t.mode, ke: t.ke, daftar,
      sudahDitanya: t.sudahDitanya ?? [], nilaiPerSoal: t.nilaiPerSoal ?? [],
      soal: null, tangga: null,
    }
    siapkanSoal()
    return true
  }

  // ——— alur ———

  function mulai(santri: Santri, tingkat: Tingkat, mode: Mode, kelompok: Kelompok | null) {
    sesi.value = {
      santri, kelompok, tingkat, mode, ke: 0,
      daftar: tingkat === 'BK2' ? bagikanBK2(acuan.value?.soal ?? [], PER_TIPE_BK2) : null,
      sudahDitanya: [], nilaiPerSoal: [], soal: null, tangga: null,
    }
    siapkanSoal()
    simpanKemajuan()
  }

  /** Menyiapkan soal berikutnya. BK1 menunggu ketukan; BK2 langsung jalan. */
  function siapkanSoal() {
    const s = sesi.value
    if (!s || s.ke >= target.value) return
    if (s.tingkat === 'BK1') {
      s.soal = null
      s.tangga = null
      gantiIbarat()
    }
    else {
      const soal = s.daftar![s.ke]!
      pasangSoal({
        tipe: soal.tipe, teks: soal.teks, soalId: soal.id, nomorBank: soal.nomor_bank,
      })
    }
  }

  function gantiIbarat() {
    const daftar = acuan.value?.ibarat ?? []
    if (daftar.length === 0) return
    ibaratKini.value = daftar[Math.floor(Math.random() * daftar.length)]!
  }

  /** BK1: penguji mengetuk satu kata pada ibarat. Nol pengetikan Arab. */
  function pilihLafad(kata: string) {
    const ib = ibaratKini.value
    if (!ib || !sesi.value) return
    pasangSoal({ tipe: 'lafad', teks: ib.teks, ibaratId: ib.id, lafad: kata })
  }

  function pasangSoal(soal: SoalAktif) {
    const s = sesi.value!
    s.soal = soal
    s.tangga = mulaiTangga(
      susunTangga(acuan.value?.langkah ?? [], soal.tipe, new Set(s.sudahDitanya)),
    )
    jamLangkah = performance.now()
  }

  function jawabLangkah(verdict: Verdict | null) {
    const s = sesi.value
    if (!s?.tangga) return
    const detik = verdict ? +((performance.now() - jamLangkah) / 1000).toFixed(1) : undefined
    s.tangga = jawabDomain(s.tangga, verdict, detik)
    jamLangkah = performance.now()
    if (tanggaSelesai(s.tangga)) tutupSoal()
  }

  function mundurLangkah() {
    const s = sesi.value
    if (!s?.tangga) return
    s.tangga = mundurDomain(s.tangga)
    jamLangkah = performance.now()
  }

  function tutupSoal() {
    const s = sesi.value!
    const tangga = s.tangga!
    if (tangga.jawaban.length > 0) {
      s.nilaiPerSoal.push(nilaiSoal(tangga.jawaban))
      s.sudahDitanya = [...tandaiSudahDitanya(tangga, new Set(s.sudahDitanya))]
      $antrean.tambah({
        p_tanggal: hariIni(),
        p_mode: s.mode,
        p_santri_id: s.santri.id,
        p_urutan: s.ke + 1,
        p_jawaban: [...tangga.jawaban],
        ...(s.kelompok ? { p_kelompok_id: s.kelompok.id } : {}),
        ...(s.soal?.soalId ? { p_soal_id: s.soal.soalId } : {}),
        ...(s.soal?.ibaratId ? { p_ibarat_id: s.soal.ibaratId } : {}),
        ...(s.soal?.lafad ? { p_lafad: s.soal.lafad } : {}),
      })
    }
    s.ke += 1
    s.soal = null
    s.tangga = null
    simpanKemajuan()
    siapkanSoal()
  }

  function sudahi() {
    const hasil = sesi.value
      ? { nama: sesi.value.santri.nama, jml: sesi.value.nilaiPerSoal.length, nilai: nilaiBerjalan.value }
      : null
    if (sesi.value && sesi.value.nilaiPerSoal.length > 0) tandaiSelesai(sesi.value.santri.id)
    sesi.value = null
    localStorage.removeItem(KUNCI)
    return hasil
  }

  return {
    sesi, ibaratKini, target, selesai, langkahSekarang, nilaiBerjalan, selesaiHariIni,
    mulai, pulihkan, gantiIbarat, pilihLafad, jawabLangkah, mundurLangkah, sudahi,
  }
}
