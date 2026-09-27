-- Sorogan Digital — Kolom aktif santri & ustadz
-- Nonaktifkan bukan hapus: daftar operasional menyembunyikan yang nonaktif,
-- riwayat nilai tetap utuh (R1). Lihat docs/23-master-data.md (D1).

alter table santri add column if not exists aktif boolean not null default true;
alter table ustadz  add column if not exists aktif boolean not null default true;

-- RLS tidak berubah: tetap hanya ustadz/superadmin yang membaca (R9).
-- Default true: data lama otomatis dianggap aktif, tanpa backfill.
