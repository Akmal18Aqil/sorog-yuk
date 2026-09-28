/**
 * Lapisan akses data. Satu-satunya tempat aplikasi menyentuh Supabase.
 *
 * Dua tugasnya:
 *  1. Menyempitkan `text` dari Postgres jadi union domain, dan MELEDAK KERAS
 *     kalau ada nilai di luar yang dikenal — artinya migrasi dan aplikasi
 *     tidak sinkron, dan itu harus ketahuan saat memuat, bukan di tengah ujian.
 *  2. Menerima klien sebagai argumen, bukan mengambilnya sendiri, supaya bisa
 *     dipalsukan dalam test tanpa menjalankan Nuxt.
 */
import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database, JenisAkun, JenisKelas, Tables } from '#shared/types/database'
import {
  isTingkat, isTipeSoal,
  type Ibarat, type Kelompok, type Langkah, type Santri, type Soal, type Ustadz,
} from '#shared/types/sorogan'
import type { JawabanLangkah } from '#shared/domain/nilai'

export type Klien = SupabaseClient<Database>

const gagal = (e: { message: string } | null, apa: string) => {
  if (e) throw new Error(`Gagal memuat ${apa}: ${e.message}`)
}

const tidakSinkron = (tabel: string, id: number, nilai: string) =>
  new Error(
    `Baris ${tabel} #${id} berisi nilai "${nilai}" yang tidak dikenal aplikasi. `
    + 'Database dan aplikasi tidak sinkron — jalankan ulang migrasi db/.',
  )

const sebagaiSoal = (r: Tables<'soal'>): Soal => {
  if (!isTipeSoal(r.tipe)) throw tidakSinkron('soal', r.id, r.tipe)
  if (!isTingkat(r.tingkat)) throw tidakSinkron('soal', r.id, r.tingkat)
  return { ...r, tipe: r.tipe, tingkat: r.tingkat }
}

const sebagaiLangkah = (r: Tables<'langkah'>): Langkah => {
  if (!isTipeSoal(r.tipe)) throw tidakSinkron('langkah', r.id, r.tipe)
  return { ...r, tipe: r.tipe }
}

const sebagaiSantri = (r: Tables<'santri'>): Santri => {
  if (!isTingkat(r.tingkat)) throw tidakSinkron('santri', r.id, r.tingkat)
  return { ...r, tingkat: r.tingkat }
}

// ——————————————————————————————— identitas ———————————————————————————————

export async function ambilUstadz(sb: Klien, authId: string): Promise<Ustadz | null> {
  const { data, error } = await sb.from('ustadz').select('id,nama').eq('auth_id', authId).eq('role', 'ustadz').maybeSingle()
  if (error) throw new Error(error.message)
  return data
}

/**
 * Nama ustadz yang belum terhubung ke akun mana pun.
 * Mentor nonaktif tidak bisa dipilih (D1) -- ia tidak lagi mengajar.
 */
export async function ambilUstadzBelumTerpakai(sb: Klien): Promise<Ustadz[]> {
  const { data, error } = await sb.from('ustadz')
    .select('id,nama').is('auth_id', null).eq('aktif', true).order('id')
  if (error) throw new Error(error.message)
  return data ?? []
}

/**
 * Hubungkan akun yang sedang login ke satu baris ustadz. Sekali seumur hidup;
 * nama yang sudah dipakai akun lain ditolak server.
 * Pakai kode undangan dari ustadz_kode table.
 */
export async function hubungkanUstadz(sb: Klien, ustadzId: number): Promise<void> {
  // Ambil kode undangan untuk ustadz ini
  const { data: kode, error: e1 } = await sb.from('ustadz_kode')
    .select('kode')
    .eq('ustadz_id', ustadzId)
    .eq('digunakan', false)
    .maybeSingle()
  if (e1) throw new Error(e1.message)
  if (!kode) throw new Error('Tidak ada kode undangan yang tersedia.')

  const { error } = await sb.rpc('daftar_ustadz', { p_kode: kode.kode })
  if (error) throw new Error(error.message)
}

// ——————————————————————————————— data acuan ———————————————————————————————

export interface Acuan {
  santri: Santri[]
  soal: Soal[]        // hanya BK2; soal BK1 lahir saat kata diketuk
  langkah: Langkah[]
  ibarat: Ibarat[]
  kelompok: Kelompok[]
  anggota: { kelompok_id: number, santri_id: number }[]
}

export async function ambilAcuan(sb: Klien): Promise<Acuan> {
  // `.eq('aktif', true)` di sini, bukan di tiap halaman: satu titik, tidak
  // bisa terlewat. Santri nonaktif hilang dari daftar operasional, tapi
  // riwayatnya di halaman hasil tetap utuh -- halaman itu tidak lewat sini
  // (R1 + D1).
  const [santri, soal, langkah, ibarat, kelompok, anggota] = await Promise.all([
    sb.from('santri').select('*').eq('aktif', true).order('nama'),
    sb.from('soal').select('*').eq('tingkat', 'BK2'),
    sb.from('langkah').select('*').order('tipe').order('urutan'),
    sb.from('ibarat').select('*').order('urutan'),
    sb.from('kelompok').select('*').order('urutan'),
    // Hanya membership AKTIF (`sampai is null`). Tanpa filter ini, riwayat
    // dari 033 ikut terbaca: seorang santri yang sudah pindah kelas akan
    // muncul di KEDUA kelompok -- dan untuk penentzikan, itu berarti menilai
    // anak yang sudah tidak ada di rombel itu.
    sb.from('kelompok_santri').select('*').is('sampai', null),
  ])
  gagal(santri.error, 'santri')
  gagal(soal.error, 'bank soal')
  gagal(langkah.error, 'tangga pertanyaan')
  gagal(ibarat.error, 'ibarat')
  gagal(kelompok.error, 'kelompok')
  gagal(anggota.error, 'anggota kelompok')

  return {
    santri: (santri.data ?? []).map(sebagaiSantri),
    soal: (soal.data ?? []).map(sebagaiSoal),
    langkah: (langkah.data ?? []).map(sebagaiLangkah),
    ibarat: ibarat.data ?? [],
    kelompok: kelompok.data ?? [],
    anggota: anggota.data ?? [],
  }
}

/** Santri anggota satu kelompok, urut nama. */
export const santriKelompok = (acuan: Acuan, kelompokId: number): Santri[] => {
  const id = new Set(acuan.anggota.filter(a => a.kelompok_id === kelompokId).map(a => a.santri_id))
  return acuan.santri.filter(s => id.has(s.id))
}

// ——————————————————————————————— penilaian ———————————————————————————————

/** Payload RPC. Bentuk ini juga yang diparkir di antrean offline. */
export interface PayloadPenilaian {
  p_tanggal: string
  p_mode: string
  p_santri_id: number
  p_urutan: number
  p_jawaban: JawabanLangkah[]
  p_soal_id?: number
  p_ibarat_id?: number
  p_lafad?: string
  p_kelompok_id?: number
}

/**
 * Satu panggilan = satu soal selesai. Atomik dan AMAN DIULANG di sisi server,
 * jadi antrean cukup mengirim ulang sampai berhasil tanpa takut ganda.
 */
export async function simpanPenilaian(sb: Klien, p: PayloadPenilaian): Promise<number> {
  const { data, error } = await sb.rpc('simpan_penilaian', p as never)
  if (error) throw new Error(error.message)
  return data as number
}

// ——————————————————————————————— laporan ———————————————————————————————

export interface Diagnostik {
  nilaiSantri: Tables<'v_nilai_santri'>[]
  kelemahan: Tables<'v_kelemahan_langkah'>[]
  kalibrasi: Tables<'v_kalibrasi_penguji'>[]
  soalSulit: Tables<'v_soal_sulit'>[]
}

export async function ambilDiagnostik(sb: Klien): Promise<Diagnostik> {
  const [nilai, lemah, kalib, sulit] = await Promise.all([
    sb.from('v_nilai_santri').select('*'),
    sb.from('v_kelemahan_langkah').select('*'),
    sb.from('v_kalibrasi_penguji').select('*'),
    sb.from('v_soal_sulit').select('*').order('nilai').limit(5),
  ])
  gagal(nilai.error, 'nilai santri')
  gagal(lemah.error, 'diagnostik langkah')
  gagal(kalib.error, 'kalibrasi penguji')
  gagal(sulit.error, 'soal tersulit')
  return {
    nilaiSantri: nilai.data ?? [],
    kelemahan: lemah.data ?? [],
    kalibrasi: kalib.data ?? [],
    soalSulit: sulit.data ?? [],
  }
}

// ——————————————————————————— kenaikan kelas ———————————————————————————

/**
 * Kesiapan naik kelas. Sistem hanya MENGUSULKAN — ambang dan kelulusan dua
 * tes dihitung di view `v_kesiapan_naik`, keputusannya tetap di asatidz.
 */
export async function ambilKesiapan(sb: Klien): Promise<Tables<'v_kesiapan_naik'>[]> {
  const { data, error } = await sb.from('v_kesiapan_naik').select('*').order('nama')
  gagal(error, 'kesiapan naik kelas')
  return data ?? []
}

export async function catatTesOffline(sb: Klien, p: {
  santri_id: number
  kelas_kode: string
  nilai: number
  tanggal: string
  dicatat_oleh: number
  catatan?: string | null
}): Promise<void> {
  const { error } = await sb.from('tes_offline').insert(p)
  if (error) throw new Error(error.message)
}

/**
 * Satu keputusan tercatat, setuju maupun tolak. Menaikkan di luar ambang
 * ditolak server kalau `catatan` kosong — alasannya wajib bisa ditinjau.
 */
export async function putuskanKenaikan(
  sb: Klien, santriId: number, setuju: boolean, catatan?: string,
): Promise<void> {
  const { error } = await sb.rpc('putuskan_kenaikan', {
    p_santri_id: santriId, p_setuju: setuju, ...(catatan != null ? { p_catatan: catatan } : {}),
  })
  if (error) throw new Error(error.message)
}

/**
 * Cari mahasantri: "nama ini semester berapa, kelas sorogannya apa".
 *
 * Lewat RPC, bukan select langsung, karena dua hal:
 *   1. Butuh alumni yang `aktif = false`. Policy `baca_ustadz` (027)
 *      menyembunyikan nonaktif dari halaman penilaian -- benar di sana,
 *      salah di sini: justru alumni yang paling perlu dicari.
 *   2. Butuh riwayat kelas yang dirangkai (kelas + jenis + periode),
 *      yang akan jadi lima subquery kalau dikerjakan di client.
 *
 * Superadmin saja, sebab hasilnya melintasi semua semester.
 */
export interface RiwayatKelas {
  kelompok: string
  jenis: JenisKelas
  periode: string | null
  dari: string | null
  sampai: string | null
}

export interface HasilCari {
  id: number
  kode: string
  nama: string
  semester: number | null
  tahun_masuk: number | null
  tingkat: string
  aktif: boolean
  kelas_sorogan: string | null
  periode_sorogan: string | null
  kelas_terjemah: string | null
  riwayat_kelas: RiwayatKelas[]
}

export async function cariMahasantri(
  sb: Klien, p: { cari?: string; kode?: number } = {},
): Promise<HasilCari[]> {
  const { data, error } = await sb.rpc('cari_mahasantri', {
    p_cari: p.cari ?? null,
    p_kode: p.kode ?? null,
  })
  if (error) throw new Error(error.message)
  return (data ?? []) as unknown as HasilCari[]
}

/**
 * Pindahkan|ال Santri ke kelas lain dalam satu operasi: membership lama
 * ditutup (diisi `sampai`), yang baru dibuka. Dikenakan sebagai satu
 * panggilan supaya tidak pernah ada jeda di mana seorang Santri punya dua
 * membership aktif.
 */
export async function pindahKelompok(sb: Klien, santri_id: number, kelompokId: number): Promise<void> {
  const { error } = await sb.rpc('pindah_kelas', {
    p_santri_id: santri_id, p_kelompok_id: kelompokId,
  })
  if (error) throw new Error(error.message)
}

// ——————————————————————————— manajemen akun ———————————————————————————

/**
 * RPC `tautkan_akun` (040): mengikat akun auth ke baris yang SUDAH ADA.
 *
 * Yang TIDAK ada di sini: membuat baris baru. Setelah 144 mahasantri
 * diimpor, membuat baris baru berarti menghasilkan orang kedua dengan
 * nama mirip -- dan yang lama tetap tanpa akun. Baris sudah benar; yang
 * belum ada hanya akunnya.
 */
export async function tautkanAkun(sb: Klien, jenis: JenisAkun, id: number, authId: string): Promise<void> {
  const { error } = await sb.rpc('tautkan_akun', {
    p_jenis: jenis, p_id: id, p_auth_id: authId,
  })
  if (error) throw new Error(error.message)
}

/**
 * Lepas akun: `auth_id` jadi NULL. Akun auth-nya sendiri TIDAK dihapus --
 * itu menghapus kata sandi orang, tindakan yang tidak selalu diinginkan.
 * Dipisah supaya "tautkan" dan "hapus akun" tidak jadi satu tombol.
 */
export async function lepasAkun(sb: Klien, jenis: JenisAkun, id: number): Promise<void> {
  const { error } = await sb.rpc('lepas_akun', { p_jenis: jenis, p_id: id })
  if (error) throw new Error(error.message)
}

/**
 * Buat akun auth saja (tanpa menautkan). Edge Function yang memegang
 * `service_role`; dipanggil setelah admin mengisi email + kata sandi, lalu
 * hasilnya langsung dikirim ke `tautkanAkun`.
 *
 * Kegagalan yang sudah ditangani di dalam fungsi: dipanggil oleh bukan
 * superadmin, atau email sudah terpakai.
 */
export async function buatAkun(
  sb: Klien, p: { email: string, password: string },
): Promise<{ auth_id: string, email: string }> {
  const { data, error } = await sb.functions.invoke('create-user', {
    body: { email: p.email.trim(), password: p.password },
  })
  if (error) throw new Error(error.message)
  if (data?.error) throw new Error(data.error)
  return data as { auth_id: string, email: string }
}

// ——————————————————————————————— admin ———————————————————————————————

export interface UstadzAdmin {
  id: number
  nama: string
  role: string
  auth_id: string | null
  /** D1: nonaktif berarti tidak lagi mengajar, bukan dihapus. */
  aktif: boolean
  /** Penanda stabil. null hanya untuk baris yang belum pernah punya kode. */
  kode: string | null
  kode_digunakan: boolean
}

export interface SantriAdmin {
  id: number
  /** Penanda stabil. Dua "Fahmi" tidak bisa dibedakan dari namanya. */
  kode: string
  nama: string
  tingkat: string
  /** 1..12, atau null kalau belum ditentukan. */
  semester: number | null
  auth_id: string | null
  /** D1: nonaktif berarti sudah lulus/keluar, bukan dihapus. */
  aktif: boolean
  /** Kelas sorogan AKTIF. null = belum masuk kelas mana pun. */
  kelas_sorogan: string | null
  /** Opsi filter "per kelas" -- nomor, bukan nama, karena nama bisa diubah. */
  kelas_id: number | null
}

export interface Statistik {
  jml_ustadz: number
  jml_santri: number
  jml_kelas: number
  jml_kelompok: number
  jml_sesi_bulan_ini: number
}

export async function ambilSemuaUstadz(sb: Klien): Promise<UstadzAdmin[]> {
  const { data, error } = await sb.rpc('ambil_semua_ustadz')
  if (error) throw new Error(error.message)
  return (data as unknown as UstadzAdmin[]) ?? []
}

export async function ambilSemuaSantri(sb: Klien): Promise<SantriAdmin[]> {
  const { data, error } = await sb.rpc('ambil_semua_santri')
  if (error) throw new Error(error.message)
  return (data as unknown as SantriAdmin[]) ?? []
}

export async function ambilStatistik(sb: Klien): Promise<Statistik> {
  const { data, error } = await sb.rpc('ambil_statistik')
  if (error) throw new Error(error.message)
  return data as unknown as Statistik
}

export async function tambahUstadz(sb: Klien, nama: string): Promise<number> {
  const { data, error } = await sb.rpc('tambah_ustadz', { p_nama: nama })
  if (error) throw new Error(error.message)
  return data as number
}

export async function ubahUstadz(sb: Klien, id: number, nama: string): Promise<void> {
  const { error } = await sb.rpc('ubah_ustadz', { p_id: id, p_nama: nama })
  if (error) throw new Error(error.message)
}

export async function hapusUstadz(sb: Klien, id: number): Promise<void> {
  const { error } = await sb.rpc('hapus_ustadz', { p_id: id })
  if (error) throw new Error(error.message)
}

// ———————————————————————— CRUD: Santri (admin) ————————————————————————

export async function tambahSantri(sb: Klien, nama: string, tingkat: string = 'BK1'): Promise<number> {
  const { data, error } = await sb.rpc('tambah_santri', { p_nama: nama, p_tingkat: tingkat })
  if (error) throw new Error(error.message)
  return data as number
}

export async function ubahSantri(sb: Klien, id: number, nama: string, tingkat: string): Promise<void> {
  const { error } = await sb.rpc('ubah_santri', { p_id: id, p_nama: nama, p_tingkat: tingkat })
  if (error) throw new Error(error.message)
}

export async function hapusSantri(sb: Klien, id: number): Promise<void> {
  const { error } = await sb.rpc('hapus_santri', { p_id: id })
  if (error) throw new Error(error.message)
}

// —————————————————————— Aktif/nonaktif (D1, docs/23-master-data.md) ——————————————————————

/**
 * Nonaktifkan, bukan hapus. Riwayat nilai tetap utuh, daftar operasional
 * menyembunyikan yang nonaktif.
 */
export async function setAktifSantri(sb: Klien, id: number, aktif: boolean): Promise<void> {
  const { error } = await sb.rpc('set_aktif_santri', { p_id: id, p_aktif: aktif })
  if (error) throw new Error(error.message)
}

export async function setAktifUstadz(sb: Klien, id: number, aktif: boolean): Promise<void> {
  const { error } = await sb.rpc('set_aktif_ustadz', { p_id: id, p_aktif: aktif })
  if (error) throw new Error(error.message)
}

// ———————————————————————— CRUD: Kelas (admin) ————————————————————————

export async function ambilKelas(sb: Klien) {
  const { data, error } = await sb.from('kelas').select('*').order('urutan')
  if (error) throw new Error(error.message)
  return data ?? []
}

export async function tambahKelas(sb: Klien, p: { kode: string; nama: string; urutan: number; ambang_online?: number; ambang_offline?: number }): Promise<number> {
  const { data, error } = await sb.rpc('tambah_kelas', {
    p_kode: p.kode, p_nama: p.nama, p_urutan: p.urutan,
    p_ambang_online: p.ambang_online ?? 70, p_ambang_offline: p.ambang_offline ?? 70,
  })
  if (error) throw new Error(error.message)
  return data as number
}

export async function ubahKelas(sb: Klien, p: { id: number; kode: string; nama: string; urutan: number; ambang_online: number; ambang_offline: number }): Promise<void> {
  const { error } = await sb.rpc('ubah_kelas', {
    p_id: p.id, p_kode: p.kode, p_nama: p.nama, p_urutan: p.urutan,
    p_ambang_online: p.ambang_online, p_ambang_offline: p.ambang_offline,
  })
  if (error) throw new Error(error.message)
}

export async function hapusKelas(sb: Klien, id: number): Promise<void> {
  const { error } = await sb.rpc('hapus_kelas', { p_id: id })
  if (error) throw new Error(error.message)
}

// ——————————————————————————————— Kelola superadmin ———————————————————————————————

export interface AdminSuper {
  id: number
  nama: string
  role: string
  aktif: boolean
  /** Tanpa akun auth, orang ini tidak bisa masuk sama sekali. */
  punya_akun: boolean
  /**
   * Dihitung SERVER (`daftar_superadmin`). UI tidak boleh menentukannya
   * sendiri: kalau penentuannya di klien, satu request yang dimanipulasi
   * sudah cukup untuk membuat tombol berbahaya muncul.
   */
  is_saya: boolean
}

export async function ambilDaftarSuperadmin(sb: Klien): Promise<AdminSuper[]> {
  const { data, error } = await sb.rpc('daftar_superadmin')
  if (error) throw new Error(error.message)
  return (data ?? []) as unknown as AdminSuper[]
}

/**
 * Naikkan / turunkan satu orang dari superadmin, atau aktif/nonaktifkan.
 *
 * Satu panggilan untuk peran DAN status sekaligus. Memisahkannya berarti UI
 * menentukan urutan dua request, dan di antara keduanya ada keadaan setengah
 * yang tidak disengaja -- "turun tapi masih aktif" adalah kondisi yang tidak
 * pernah boleh terlihat.
 *
 * Pagar "superadmin aktif terakhir" ditegakkan server (db/049), bukan di UI.
 * UI hanya menampilkan tombol; kalau server menolak, pesannya sudah jelas.
 */
export async function aturSuperadmin(
  sb: Klien, p: { id: number; peran: 'superadmin' | 'ustadz'; aktif: boolean },
): Promise<void> {
  const { error } = await sb.rpc('atur_superadmin', {
    p_id: p.id, p_peran: p.peran, p_aktif: p.aktif,
  })
  if (error) throw new Error(error.message)
}
// —————————————————————————————————— CRUD: Kelompok (admin) ——————————————————————————————————

export async function ambilKelompok(sb: Klien) {
  const { data, error } = await sb.from('kelompok').select('*, kelompok_santri(santri_id)').order('urutan')
  if (error) throw new Error(error.message)
  return data ?? []
}

export async function tambahKelompok(sb: Klien, nama: string, urutan?: number, tingkat?: string | null): Promise<number> {
  const { data, error } = await sb.rpc('tambah_kelompok', { p_nama: nama, p_urutan: urutan ?? null, p_tingkat: tingkat ?? null })
  if (error) throw new Error(error.message)
  return data as number
}

export async function ubahKelompok(sb: Klien, id: number, nama: string, urutan?: number, tingkat?: string | null): Promise<void> {
  const { error } = await sb.rpc('ubah_kelompok', { p_id: id, p_nama: nama, p_urutan: urutan ?? null, p_tingkat: tingkat ?? null })
  if (error) throw new Error(error.message)
}

export async function hapusKelompok(sb: Klien, id: number): Promise<void> {
  const { error } = await sb.rpc('hapus_kelompok', { p_id: id })
  if (error) throw new Error(error.message)
}

// ———————————————————————— Kelas kuliah & naik semester ————————————————————————

/** Hasil `naik_semester`: berapa yang dipindah, berapa yang sengaja dilewati. */
export interface HasilNaikSemester {
  dipindah: number
  /** Nonaktif (lulus/keluar) yang TIDAK dinaikkan. Dilaporkan, bukan disembunyikan. */
  dilewati: number
}

/**
 * Naikkan seluruh Santri AKTIF dari `dari` ke `ke`.
 *
 * Satu operasi, bukan satu baris per Santri: bila gagal di tengah, kelas
 * bisa tertinggal setengah naik dan tidak ada yang mengetahuinya. Validasi
 * rentang 1..12 dan "tujuan harus lebih besar" ditegakkan server
 * (db/048) — bukan di sini, karena UI bisa dilewati.
 */
export async function naikSemester(sb: Klien, dari: number, ke: number): Promise<HasilNaikSemester> {
  const { data, error } = await sb.rpc('naik_semester', { p_dari: dari, p_ke: ke })
  if (error) throw new Error(error.message)
  // `Json` belum tentu objek: PostgREST menyatakan nilai balik RPC json sebagai
  // `Json`, jadi bentuknya baru pasti setelah diperiksa. Bentuk salah akan
  // membuat UI menampilkan "undefined.undefined" -- lebih baik error jujur.
  const r = data as unknown as HasilNaikSemester
  if (typeof r?.dipindah !== 'number' || typeof r?.dilewati !== 'number') {
    throw new Error('Balasan naik semester tidak sesuai. Jalankan ulang migrasi db/.')
  }
  return r
}

// ———————————————————————— CRUD: Kelompok-Santri ————————————————————————

export async function tambahAnggotaKelompok(sb: Klien, kelompokId: number, santriId: number): Promise<void> {
  const { error } = await sb.rpc('tambah_anggota_kelompok', { p_kelompok_id: kelompokId, p_santri_id: santriId })
  if (error) throw new Error(error.message)
}

export async function hapusAnggotaKelompok(sb: Klien, kelompokId: number, santriId: number): Promise<void> {
  const { error } = await sb.rpc('hapus_anggota_kelompok', { p_kelompok_id: kelompokId, p_santri_id: santriId })
  if (error) throw new Error(error.message)
}

// ———————————————————————— CRUD: Kitab (langsung via RLS) ————————————————————————

export async function ambilKitab(sb: Klien) {
  const { data, error } = await sb.from('kitab').select('*').order('nama')
  if (error) throw new Error(error.message)
  return data ?? []
}

export async function tambahKitab(sb: Klien, nama: string, pengarang?: string) {
  const { data, error } = await sb.from('kitab').insert({ nama, pengarang: pengarang ?? null }).select().single()
  if (error) throw new Error(error.message)
  return data
}

export async function ubahKitab(sb: Klien, id: number, nama: string, pengarang?: string) {
  const { error } = await sb.from('kitab').update({ nama, pengarang: pengarang ?? null }).eq('id', id)
  if (error) throw new Error(error.message)
}

export async function hapusKitab(sb: Klien, id: number) {
  const { error } = await sb.from('kitab').delete().eq('id', id)
  if (error) throw new Error(error.message)
}

// ———————————————————————— CRUD: Ibarat (langsung via RLS) ————————————————————————

export async function ambilIbarat(sb: Klien, kitabId: number) {
  const { data, error } = await sb.from('ibarat').select('*').eq('kitab_id', kitabId).order('urutan')
  if (error) throw new Error(error.message)
  return data ?? []
}

export async function tambahIbarat(sb: Klien, p: { kitab_id: number; urutan?: number; halaman?: number; teks: string }) {
  const { data, error } = await sb.from('ibarat').insert(p).select().single()
  if (error) throw new Error(error.message)
  return data
}

export async function ubahIbarat(sb: Klien, id: number, p: { urutan?: number; halaman?: number; teks: string }) {
  const { error } = await sb.from('ibarat').update(p).eq('id', id)
  if (error) throw new Error(error.message)
}

export async function hapusIbarat(sb: Klien, id: number) {
  const { error } = await sb.from('ibarat').delete().eq('id', id)
  if (error) throw new Error(error.message)
}

// ———————————————————————— CRUD: Soal (langsung via RLS) ————————————————————————

export async function ambilSoal(sb: Klien, filters?: { tingkat?: string; tipe?: string }) {
  let q = sb.from('soal').select('*')
  if (filters?.tingkat) q = q.eq('tingkat', filters.tingkat)
  if (filters?.tipe) q = q.eq('tipe', filters.tipe)
  q = q.order('tingkat').order('tipe').order('nomor_bank')
  const { data, error } = await q
  if (error) throw new Error(error.message)
  return data ?? []
}

export async function tambahSoal(sb: Klien, p: { ibarat_id: number; teks: string; tipe: string; tingkat: string; nomor_bank?: number }) {
  const { data, error } = await sb.from('soal').insert(p).select().single()
  if (error) throw new Error(error.message)
  return data
}

export async function ubahSoal(sb: Klien, id: number, p: { teks: string; tipe: string; tingkat: string; nomor_bank?: number }) {
  const { error } = await sb.from('soal').update(p).eq('id', id)
  if (error) throw new Error(error.message)
}

export async function hapusSoal(sb: Klien, id: number) {
  const { error } = await sb.from('soal').delete().eq('id', id)
  if (error) throw new Error(error.message)
}

// ———————————————————————— CRUD: Langkah (langsung via RLS) ————————————————————————

export async function ambilLangkah(sb: Klien, tipe?: string) {
  let q = sb.from('langkah').select('*')
  if (tipe) q = q.eq('tipe', tipe)
  q = q.order('tipe').order('urutan')
  const { data, error } = await q
  if (error) throw new Error(error.message)
  return data ?? []
}

export async function tambahLangkah(sb: Klien, p: { tipe: string; urutan: number; pertanyaan: string; bersyarat?: string; sekali_per_sesi?: boolean }) {
  const { data, error } = await sb.from('langkah').insert(p).select().single()
  if (error) throw new Error(error.message)
  return data
}

export async function ubahLangkah(sb: Klien, id: number, p: { tipe: string; urutan: number; pertanyaan: string; bersyarat?: string; sekali_per_sesi?: boolean }) {
  const { error } = await sb.from('langkah').update(p).eq('id', id)
  if (error) throw new Error(error.message)
}

export async function hapusLangkah(sb: Klien, id: number) {
  const { error } = await sb.from('langkah').delete().eq('id', id)
  if (error) throw new Error(error.message)
}

// ——————————————————————————————— leger ———————————————————————————————

export interface BarisLeger { santri_id: number, urutan: number, nilai: number }

/** Leger satu lembar: hanya sesi hari ini milik penguji ini. */
export async function ambilLeger(sb: Klien, ustadzId: number, tanggal: string): Promise<BarisLeger[]> {
  const [pen, nil] = await Promise.all([
    sb.from('penilaian').select('id,santri_id,urutan,sesi!inner(tanggal,ustadz_id)')
      .eq('sesi.tanggal', tanggal).eq('sesi.ustadz_id', ustadzId),
    sb.from('v_nilai_soal').select('penilaian_id,nilai'),
  ])
  gagal(pen.error, 'leger')
  gagal(nil.error, 'nilai soal')

  const nilaiOf = new Map((nil.data ?? []).map(r => [r.penilaian_id, r.nilai]))
  return (pen.data ?? []).flatMap((p) => {
    const nilai = nilaiOf.get(p.id)
    return nilai == null ? [] : [{ santri_id: p.santri_id, urutan: p.urutan, nilai }]
  })
}
