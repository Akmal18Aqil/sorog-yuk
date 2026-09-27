-- Sumbu 2: kelas ber-periode dan ber-jenis
--
-- Tanpa `periode`, "Kelompok 1" tahun ini dan "Kelompok 1" tahun depan
-- adalah baris yang sama. Pencarian "siapa yang di Kelompok 1 Ganjil 2026"
-- jadi tidak bisa dibedakan dari "yang di Kelompok 1 Ganjil 2027" -- dan dua
-- kelompok itu orangnya beda total.
--
-- `jenis` memisahkan sorogan dari terjemah. Keduanya bentuk dan alurnya
-- sama, jadi TIDAK perlu dua tabel: satu kolom, nol tabel baru.

alter table public.kelompok add column if not exists periode text;
alter table public.kelompok add column if not exists jenis text not null default 'sorogan';

alter table public.kelompok drop constraint if exists qe_kelompok_jenis;
alter table public.kelompok add constraint qe_kelompok_jenis
  check (jenis in ('sorogan', 'terjemah'));

-- Uniqueness parsial: NULL != NULL di SQL, jadi kelas yang periodenya belum
-- diisi tidak ikut terkunci -- dan itu memang isi yang diperbolehkan.
create unique index if not exists kelompok_periode_uniq
  on public.kelompok (periode, jenis, nama)
  where periode is not null;

create index if not exists kelompok_periode_cari on public.kelompok (periode, jenis);

-- Backfill: kelompok lama tidak pernah punya periode. Tahun diambil dari
-- sesi terbaru kelompok itu; kalau tidak ada sesi sama sekali, ditandai
-- jelas sebagai belum diatur -- bukan dikarang.