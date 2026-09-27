-- Sumbu 3: anggota kelas bisa punya riwayat
--
-- `kelompok_santri_satu` (UNIQUE pada santri_id) menyatakan: satu
-- Santri = satu kelompok, selamanya. Itu yang membuat "perpindahan kelas"
-- mustahil tercatat -- saat pindah, baris lama dihapus, jadi tidak ada
-- yang tersisa untuk ditanya "dia dulu di kelompok apa".
--
-- Dua batasan yang harus tetap berlaku dan keduanya dipegang index:
--   1. Satu-aktif: seorang Santri hanya boleh punya SATU kelompok AKTIF.
--   2. Riwayat: boleh punya banyak membership yang sudah `sampai`-nya terisi.
--
-- Kolom `dari`/`sampai` sengaja DATE, bukan timestamptz: pertanyaan yang
-- dijawab selalu "periode berapa", dan tanggal sudah cukup.

alter table public.kelompok_santri add column if not exists dari date;
alter table public.kelompok_santri add column if not exists sampai date;

-- Baris lama = membership aktif yang periodenya belum pernah dicatat.
update public.kelompok_santri set dari = current_date where dari is null;

alter table public.kelompok_santri drop constraint if exists kelompok_santri_satu;
drop index if exists kelompok_santri_satu;

-- NULL berarti "masih aktif", dan hanya baris seperti itu yang harus unik.
create unique index if not exists kelompok_santri_aktif_uniq
  on public.kelompok_santri (santri_id)
  where sampai is null;

create index if not exists kelompok_santri_santri_cari
  on public.kelompok_santri (santri_id, dari desc);

alter table public.kelompok_santri drop constraint if exists qe_ks_periode;
alter table public.kelompok_santri add constraint qe_ks_periode
  check (sampai is null or sampai >= dari);
