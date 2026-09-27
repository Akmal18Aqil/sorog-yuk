-- Sorogan Digital — hentikan recursion policy pada sesi
--
-- 017:404 menulis `where p.sesi_id = id`. Postgres meng-correlate nama bebas ke
-- kolom PALING DALAM, jadi `id` di situ berarti `p.id`, bukan `sesi.id` --
-- policy tersimpan apa adanya sebagai `p.sesi_id = p.id` (terbukti di
-- pg_policies). Makanya policy itu berarti: "sesi yang punya penilaian dengan
-- sesi_id = penilaian.id", yaitu tidak pernah benar.
--
-- Yang lebih parah: policy itu menanyakan tabel `penilaian`, sedangkan
-- `penilaian.tulis_ustadz` (017:428, FOR ALL) menanyakan tabel `sesi`.
-- Dua policy saling memanggil -> `42P17: infinite recursion detected in
-- policy for relation "penilaian"`. Efeknya bukan policy yang salah saja:
-- SELURUH pembacaan sesi/penilaian/jawaban olehbruid yang sudah login
-- meledak, termasuk di dalam putuskan_kenaikan().
--
-- Perbaikannya: pindahkan kueri ke helper SECURITY DEFINER. Helper di
-- schema `priv` dijalankan sebagai pemilik tabel, jadi RLS `penilaian` tidak
-- dievaluasi -> tidak ada yang memanggil balik -> tidak ada recursion.
-- Ini pola yang sama dengan priv.is_ustadz() di 017:62.

create function priv.sesi_diikuti_santri(p_sesi_id bigint) returns boolean
  language sql stable security definer set search_path = '' as
$$ select exists (
     select 1 from public.penilaian p
     where p.sesi_id = p_sesi_id and p.santri_id = priv.my_santri_id()
   ) $$;

revoke execute on function priv.sesi_diikuti_santri(bigint) from public;

drop policy baca_santri on sesi;
create policy baca_santri on sesi for select to authenticated
  using (priv.sesi_diikuti_santri(id));