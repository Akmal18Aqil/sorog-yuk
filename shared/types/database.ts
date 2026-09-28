/**
 * DIBANGKITKAN dari skema Supabase — jangan diedit tangan.
 *
 * Perbarui setelah mengubah migrasi:
 *   npx supabase gen types typescript --project-id unozvswlxqbhqzmlsirl > shared/types/database.ts
 *
 * Ini satu-satunya titik tempat bentuk database masuk ke TypeScript. Kalau
 * sebuah kolom hilang di migrasi, yang gagal adalah build — bukan ustadz
 * di tengah ujian.
 */
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

/** Sorogan atau terjemah. Satu kolom, bukan dua tabel. */
export const JENIS_KELAS = ['sorogan', 'terjemah'] as const
export type JenisKelas = (typeof JENIS_KELAS)[number]
export const isJenisKelas = (v: unknown): v is JenisKelas =>
  v === 'sorogan' || v === 'terjemah'

export const LABEL_JENIS: Record<JenisKelas, string> = {
  sorogan: 'Sorogan', terjemah: 'Terjemah',
}

/** Tabel yang punya relasi ke `auth.users`. */
export type JenisAkun = 'santri' | 'ustadz'

export type Database = {
  __InternalSupabase: { PostgrestVersion: '14.15' }
  public: {
    Tables: {
      ibarat: {
        Row: { halaman: number | null; id: number; kitab_id: number; teks: string; urutan: number | null }
        Insert: { halaman?: number | null; id?: never; kitab_id: number; teks: string; urutan?: number | null }
        Update: { halaman?: number | null; id?: never; kitab_id?: number; teks?: string; urutan?: number | null }
        Relationships: [{ foreignKeyName: 'ibarat_kitab_id_fkey'; columns: ['kitab_id']; isOneToOne: false; referencedRelation: 'kitab'; referencedColumns: ['id'] }]
      }
      jawaban: {
        Row: { catatan: string | null; detik: number | null; dibuat_pada: string; id: number; langkah_id: number; penilaian_id: number; verdict: string }
        Insert: { catatan?: string | null; detik?: number | null; dibuat_pada?: string; id?: never; langkah_id: number; penilaian_id: number; verdict: string }
        Update: { catatan?: string | null; detik?: number | null; dibuat_pada?: string; id?: never; langkah_id?: number; penilaian_id?: number; verdict?: string }
        Relationships: [
          { foreignKeyName: 'jawaban_langkah_id_fkey'; columns: ['langkah_id']; isOneToOne: false; referencedRelation: 'langkah'; referencedColumns: ['id'] },
          { foreignKeyName: 'jawaban_penilaian_id_fkey'; columns: ['penilaian_id']; isOneToOne: false; referencedRelation: 'penilaian'; referencedColumns: ['id'] },
        ]
      }
      kelas: {
        Row: { ambang_offline: number; ambang_online: number; id: number; kode: string; nama: string; urutan: number }
        Insert: { ambang_offline?: number; ambang_online?: number; id?: never; kode: string; nama: string; urutan: number }
        Update: { ambang_offline?: number; ambang_online?: number; id?: never; kode?: string; nama?: string; urutan?: number }
        Relationships: []
      }
      kelompok: {
        Row: { id: number; jenis: JenisKelas; nama: string; periode: string | null; tingkat: string | null; urutan: number | null }
        Insert: { id?: never; jenis?: JenisKelas; nama: string; periode?: string | null; tingkat?: string | null; urutan?: number | null }
        Update: { id?: never; jenis?: JenisKelas; nama?: string; periode?: string | null; tingkat?: string | null; urutan?: number | null }
        Relationships: [{ foreignKeyName: 'kelompok_tingkat_fk'; columns: ['tingkat']; isOneToOne: false; referencedRelation: 'kelas'; referencedColumns: ['kode'] }]
      }
      kelompok_santri: {
        Row: { dari: string | null; id: number; kelompok_id: number; sampai: string | null; santri_id: number }
        Insert: { dari?: string | null; id?: never; kelompok_id: number; sampai?: string | null; santri_id: number }
        Update: { dari?: string | null; id?: never; kelompok_id?: number; sampai?: string | null; santri_id?: number }
        Relationships: [
          { foreignKeyName: 'kelompok_santri_kelompok_id_fkey'; columns: ['kelompok_id']; isOneToOne: false; referencedRelation: 'kelompok'; referencedColumns: ['id'] },
          { foreignKeyName: 'kelompok_santri_santri_id_fkey'; columns: ['santri_id']; isOneToOne: false; referencedRelation: 'santri'; referencedColumns: ['id'] },
        ]
      }
      kenaikan: {
        Row: { catatan: string | null; dari_kelas: string; diputuskan_oleh: number; diputuskan_pada: string; disetujui: boolean; id: number; ke_kelas: string; memenuhi_ambang: boolean; nilai_offline: number | null; nilai_online: number | null; santri_id: number }
        Insert: { catatan?: string | null; dari_kelas: string; diputuskan_oleh: number; diputuskan_pada?: string; disetujui: boolean; id?: never; ke_kelas: string; memenuhi_ambang: boolean; nilai_offline?: number | null; nilai_online?: number | null; santri_id: number }
        Update: { catatan?: string | null; dari_kelas?: string; diputuskan_oleh?: number; diputuskan_pada?: string; disetujui?: boolean; id?: never; ke_kelas?: string; memenuhi_ambang?: boolean; nilai_offline?: number | null; nilai_online?: number | null; santri_id?: number }
        Relationships: [
          { foreignKeyName: 'kenaikan_dari_kelas_fkey'; columns: ['dari_kelas']; isOneToOne: false; referencedRelation: 'kelas'; referencedColumns: ['kode'] },
          { foreignKeyName: 'kenaikan_diputuskan_oleh_fkey'; columns: ['diputuskan_oleh']; isOneToOne: false; referencedRelation: 'ustadz'; referencedColumns: ['id'] },
          { foreignKeyName: 'kenaikan_ke_kelas_fkey'; columns: ['ke_kelas']; isOneToOne: false; referencedRelation: 'kelas'; referencedColumns: ['kode'] },
          { foreignKeyName: 'kenaikan_santri_id_fkey'; columns: ['santri_id']; isOneToOne: false; referencedRelation: 'santri'; referencedColumns: ['id'] },
        ]
      }
      kitab: {
        Row: { id: number; nama: string; pengarang: string | null }
        Insert: { id?: never; nama: string; pengarang?: string | null }
        Update: { id?: never; nama?: string; pengarang?: string | null }
        Relationships: []
      }
      langkah: {
        Row: { bersyarat: string | null; id: number; pertanyaan: string; sekali_per_sesi: boolean; tipe: string; urutan: number }
        Insert: { bersyarat?: string | null; id?: never; pertanyaan: string; sekali_per_sesi?: boolean; tipe: string; urutan: number }
        Update: { bersyarat?: string | null; id?: never; pertanyaan?: string; sekali_per_sesi?: boolean; tipe?: string; urutan?: number }
        Relationships: []
      }
      penilaian: {
        Row: { id: number; santri_id: number; sesi_id: number; soal_id: number; urutan: number }
        Insert: { id?: never; santri_id: number; sesi_id: number; soal_id: number; urutan: number }
        Update: { id?: never; santri_id?: number; sesi_id?: number; soal_id?: number; urutan?: number }
        Relationships: [
          { foreignKeyName: 'penilaian_santri_id_fkey'; columns: ['santri_id']; isOneToOne: false; referencedRelation: 'santri'; referencedColumns: ['id'] },
          { foreignKeyName: 'penilaian_sesi_id_fkey'; columns: ['sesi_id']; isOneToOne: false; referencedRelation: 'sesi'; referencedColumns: ['id'] },
          { foreignKeyName: 'penilaian_soal_id_fkey'; columns: ['soal_id']; isOneToOne: false; referencedRelation: 'soal'; referencedColumns: ['id'] },
        ]
      }
      santri: {
        Row: { aktif: boolean; auth_id: string | null; id: number; kode: string; nama: string; semester: number | null; tahun_masuk: number | null; tingkat: string }
        Insert: { aktif?: boolean; auth_id?: string | null; id?: never; kode?: string; nama: string; semester?: number | null; tahun_masuk?: number | null; tingkat?: string }
        Update: { aktif?: boolean; auth_id?: string | null; id?: never; kode?: string; nama?: string; semester?: number | null; tahun_masuk?: number | null; tingkat?: string }
        Relationships: [
          { foreignKeyName: 'santri_tingkat_fk'; columns: ['tingkat']; isOneToOne: false; referencedRelation: 'kelas'; referencedColumns: ['kode'] },
        ]
      }
      sesi: {
        Row: { dibuat_pada: string; id: number; kelompok_id: number | null; mode: string; tanggal: string; ustadz_id: number }
        Insert: { dibuat_pada?: string; id?: never; kelompok_id?: number | null; mode?: string; tanggal?: string; ustadz_id: number }
        Update: { dibuat_pada?: string; id?: never; kelompok_id?: number | null; mode?: string; tanggal?: string; ustadz_id?: number }
        Relationships: [
          { foreignKeyName: 'sesi_kelompok_id_fkey'; columns: ['kelompok_id']; isOneToOne: false; referencedRelation: 'kelompok'; referencedColumns: ['id'] },
          { foreignKeyName: 'sesi_ustadz_id_fkey'; columns: ['ustadz_id']; isOneToOne: false; referencedRelation: 'ustadz'; referencedColumns: ['id'] },
        ]
      }
      soal: {
        Row: { ibarat_id: number; id: number; nomor_bank: number | null; teks: string; tingkat: string; tipe: string }
        Insert: { ibarat_id: number; id?: never; nomor_bank?: number | null; teks: string; tingkat: string; tipe: string }
        Update: { ibarat_id?: number; id?: never; nomor_bank?: number | null; teks?: string; tingkat?: string; tipe?: string }
        Relationships: [
          { foreignKeyName: 'soal_ibarat_id_fkey'; columns: ['ibarat_id']; isOneToOne: false; referencedRelation: 'ibarat'; referencedColumns: ['id'] },
        ]
      }
      tes_offline: {
        Row: { catatan: string | null; dibuat_pada: string; dicatat_oleh: number; id: number; kelas_kode: string; nilai: number; santri_id: number; tanggal: string }
        Insert: { catatan?: string | null; dibuat_pada?: string; dicatat_oleh: number; id?: never; kelas_kode: string; nilai: number; santri_id: number; tanggal?: string }
        Update: { catatan?: string | null; dibuat_pada?: string; dicatat_oleh?: number; id?: never; kelas_kode?: string; nilai?: number; santri_id?: number; tanggal?: string }
        Relationships: [
          { foreignKeyName: 'tes_offline_dicatat_oleh_fkey'; columns: ['dicatat_oleh']; isOneToOne: false; referencedRelation: 'ustadz'; referencedColumns: ['id'] },
          { foreignKeyName: 'tes_offline_kelas_kode_fkey'; columns: ['kelas_kode']; isOneToOne: false; referencedRelation: 'kelas'; referencedColumns: ['kode'] },
          { foreignKeyName: 'tes_offline_santri_id_fkey'; columns: ['santri_id']; isOneToOne: false; referencedRelation: 'santri'; referencedColumns: ['id'] },
        ]
      }
      ustadz: {
        Row: { aktif: boolean; auth_id: string | null; id: number; nama: string; role: string }
        Insert: { aktif?: boolean; auth_id?: string | null; id?: never; nama: string; role?: string }
        Update: { aktif?: boolean; auth_id?: string | null; id?: never; nama?: string; role?: string }
        Relationships: []
      }
      ustadz_kode: {
        Row: { dibuat_pada: string; digunakan: boolean; kode: string; ustadz_id: number }
        Insert: { dibuat_pada?: string; digunakan?: boolean; kode: string; ustadz_id: number }
        Update: { dibuat_pada?: string; digunakan?: boolean; kode?: string; ustadz_id?: number }
        Relationships: [{ foreignKeyName: 'ustadz_kode_ustadz_id_fkey'; columns: ['ustadz_id']; isOneToOne: false; referencedRelation: 'ustadz'; referencedColumns: ['id'] }]
      }
    }
    Views: {
      v_kalibrasi_penguji: {
        Row: { jml_pembanding: number | null; jml_santri: number | null; nama: string | null; rata_penguji: number | null; selisih_terkalibrasi: number | null; ustadz_id: number | null }
        Relationships: []
      }
      v_kelemahan_langkah: {
        Row: { n: number | null; nilai: number | null; pertanyaan: string | null; santri_id: number | null; tipe: string | null; urutan: number | null }
        Relationships: []
      }
      v_kesiapan_naik: {
        Row: { ambang_offline: number | null; ambang_online: number | null; kelas_berikut: string | null; kelas_berikut_nama: string | null; kelas_kode: string | null; kelas_nama: string | null; lolos_offline: boolean | null; lolos_online: boolean | null; nama: string | null; nilai_offline: number | null; nilai_online: number | null; santri_id: number | null; siap: boolean | null; tanggal_offline: string | null; tanggal_online: string | null }
        Relationships: []
      }
      v_nilai_santri: {
        Row: { jml_soal: number | null; nilai: number | null; santri_id: number | null; sesi_id: number | null }
        Relationships: []
      }
      v_nilai_soal: {
        Row: { langkah_dijawab: number | null; nilai: number | null; penilaian_id: number | null; santri_id: number | null; sesi_id: number | null; soal_id: number | null; tingkat: string | null; tipe: string | null }
        Relationships: []
      }
      v_soal_sulit: {
        Row: { dikerjakan: number | null; nilai: number | null; nomor_bank: number | null; soal_id: number | null; teks: string | null; tipe: string | null }
        Relationships: []
      }
    }
    Functions: {
      ambil_semua_santri: { Args: never; Returns: Json }
      ambil_semua_ustadz: { Args: never; Returns: Json }
      ambil_statistik: { Args: never; Returns: Json }
      atur_superadmin: { Args: { p_aktif: boolean; p_id: number; p_peran: string }; Returns: undefined }
      bobot: { Args: { v: string }; Returns: number }
      cari_mahasantri: { Args: { p_cari?: string | null; p_kode?: number | null }; Returns: Json }
      lepas_akun: { Args: { p_id: number; p_jenis: string }; Returns: undefined }
      daftar_santri: { Args: { p_nama: string; p_tingkat?: string }; Returns: number }
      daftar_superadmin: { Args: never; Returns: Json }
      daftar_ustadz: { Args: { p_kode: string }; Returns: number }
      hapus_anggota_kelompok: { Args: { p_kelompok_id: number; p_santri_id: number }; Returns: undefined }
      hapus_kelas: { Args: { p_id: number }; Returns: undefined }
      hapus_kelompok: { Args: { p_id: number }; Returns: undefined }
      hapus_santri: { Args: { p_id: number }; Returns: undefined }
      hapus_ustadz: { Args: { p_id: number }; Returns: undefined }
      pindah_kelas: { Args: { p_kelompok_id: number; p_santri_id: number }; Returns: undefined }
      is_ustadz: { Args: never; Returns: boolean }
      my_ustadz_id: { Args: never; Returns: number }
      naik_semester: { Args: { p_dari: number; p_ke: number }; Returns: Json }
      putuskan_kenaikan: { Args: { p_catatan?: string; p_santri_id: number; p_setuju: boolean }; Returns: number }
      set_aktif_santri: { Args: { p_aktif: boolean; p_id: number }; Returns: undefined }
      set_aktif_ustadz: { Args: { p_aktif: boolean; p_id: number }; Returns: undefined }
      tautkan_akun: { Args: { p_auth_id: string; p_id: number; p_jenis: string }; Returns: undefined }
      simpan_penilaian: { Args: { p_ibarat_id?: number; p_jawaban: Json; p_kelompok_id?: number; p_lafad?: string; p_mode: string; p_santri_id: number; p_soal_id?: number; p_tanggal: string; p_urutan: number }; Returns: number }
      tambah_anggota_kelompok: { Args: { p_kelompok_id: number; p_santri_id: number }; Returns: undefined }
      tambah_kelas: { Args: { p_ambang_offline?: number; p_ambang_online?: number; p_kode: string; p_nama: string; p_urutan: number }; Returns: number }
      tambah_kelompok: { Args: { p_nama: string; p_tingkat?: string | null; p_urutan?: number | null }; Returns: number }
      tambah_santri: { Args: { p_nama: string; p_tingkat?: string }; Returns: number }
      tambah_ustadz: { Args: { p_nama: string }; Returns: number }
      ubah_kelas: { Args: { p_ambang_offline: number; p_ambang_online: number; p_id: number; p_kode: string; p_nama: string; p_urutan: number }; Returns: undefined }
      ubah_kelompok: { Args: { p_id: number; p_nama: string; p_tingkat?: string | null; p_urutan?: number | null }; Returns: undefined }
      ubah_santri: { Args: { p_id: number; p_nama: string; p_tingkat: string }; Returns: undefined }
      ubah_ustadz: { Args: { p_id: number; p_nama: string }; Returns: undefined }
    }
    Enums: { [_ in never]: never }
    CompositeTypes: { [_ in never]: never }
  }
}

type Publik = Database['public']

export type Tables<T extends keyof (Publik['Tables'] & Publik['Views'])> =
  (Publik['Tables'] & Publik['Views'])[T] extends { Row: infer R } ? R : never

export type TablesInsert<T extends keyof Publik['Tables']> =
  Publik['Tables'][T] extends { Insert: infer I } ? I : never

export type ArgsRpc<T extends keyof Publik['Functions']> = Publik['Functions'][T]['Args']
