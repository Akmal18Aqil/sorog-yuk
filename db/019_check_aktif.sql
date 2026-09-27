-- Check kolom aktif (019), lewat SKEMA + DATA SUNGGUHAN.
--
-- Invarian yang dipagari:
--   1. Kolom aktif ada di santri dan ustadz.
--   2. NOT NULL dengan default true.
--   3. Semua baris lama bernilai true (tanpa backfill manual).
--
-- Aman diulang: hanya SELECT, tidak menulis apa pun.
-- Jalankan: paste di SQL Editor dashboard Supabase.

do $$
declare
  c_santri int; c_ustadz int;
  n_santri_off int; n_ustadz_off int;
begin
  select count(*) into c_santri
    from information_schema.columns
    where table_schema = 'public' and table_name = 'santri'
      and column_name = 'aktif' and is_nullable = 'NO'
      and column_default ilike '%true%';
  assert c_santri = 1, 'kolom santri.aktif harus NOT NULL DEFAULT true';

  select count(*) into c_ustadz
    from information_schema.columns
    where table_schema = 'public' and table_name = 'ustadz'
      and column_name = 'aktif' and is_nullable = 'NO'
      and column_default ilike '%true%';
  assert c_ustadz = 1, 'kolom ustadz.aktif harus NOT NULL DEFAULT true';

  select count(*) into n_santri_off from santri where aktif is not true;
  assert n_santri_off = 0,
    format('ada %s santri tidak aktif padahal migrasi 019 baru jalan', n_santri_off);

  select count(*) into n_ustadz_off from ustadz where aktif is not true;
  assert n_ustadz_off = 0,
    format('ada %s ustadz tidak aktif padahal migrasi 019 baru jalan', n_ustadz_off);

  raise notice 'CHECK 019 OK';
end $$;
