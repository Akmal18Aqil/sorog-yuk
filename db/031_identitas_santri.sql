-- Sumbu 1: identitas mahasantri
--
-- Tujuan: "cepat cari nama Mahasantri ini dari semester berapa".
--
--   1. `kode` yang stabil. Nama BUKAN identitas -- ada dua orang bernama
--      sama, dan tidak ada yang bisa membedakannya. `kode` yang mengikat;
--      nama tetap disimpan dan tetap bisa dicari.
--   2. `semester` dan `tahun_masuk`. Semester tanpa tahun masuk adalah
--      angka tanpa titik waktu: "semester 3" pada 2026 dan pada 2031 adalah
--      orang yang sangat berbeda.
--
-- Yang SENGAJA TIDAK disentuh: `tingkat`. Itu BK1/BK2, yaitu jenjang MATERI,
-- sudah jadi FK ke `kelas(kode)`, dan dipakai seluruh logika penilaian.
-- Semester adalah sumbu WAKTU, jenjang materi adalah sumbu KONTEN.
--
-- Semester & tahun_masuk sengaja NULL untuk data lama: mengarang angka
-- tebakan lebih berbahaya daripada kosong, karena angka itu nanti dipakai
-- untuk keputusan kenaikan kelas.

create sequence if not exists public.santri_kode_seq;
select setval('public.santri_kode_seq', greatest(coalesce(max(id), 0), 1)) from public.santri;

alter table public.santri add column if not exists kode text;
update public.santri set kode = format('MS-%s', lpad(id::text, 4, '0')) where kode is null;
alter table public.santri alter column kode set default
  format('MS-%s', lpad(nextval('public.santri_kode_seq')::text, 4, '0'));
alter table public.santri alter column kode set not null;

alter table public.santri add column if not exists semester smallint;
alter table public.santri add column if not exists tahun_masuk smallint;
alter table public.santri drop constraint if exists qe_santri_semester;
alter table public.santri drop constraint if exists qe_santri_tahun_masuk;
alter table public.santri add constraint qe_santri_semester
  check (semester is null or semester between 1 and 12);
alter table public.santri add constraint qe_santri_tahun_masuk
  check (tahun_masuk is null or tahun_masuk between 1990 and 2100);

create unique index if not exists Santri_kode_uniq on public.santri (kode);
create index if not exists Santri_nama_cari on public.santri (lower(nama));
create index if not exists Santri_semester_cari on public.santri (semester, tahun_masuk);