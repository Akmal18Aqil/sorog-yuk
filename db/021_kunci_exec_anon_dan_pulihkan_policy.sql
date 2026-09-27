-- Sorogan Digital — Kunci RPC dari anon + pulihkan policy yang hilang
--
-- 1. Empat belas fungsi SECURITY DEFINER masih bisa dipanggil tanpa login.
--    Badannya sudah dijaga priv.is_superadmin(), jadi ini defense-in-depth:
--    guard di dalam body jadi lapisan kedua, bukan satu-satunya.
--
-- 2. `kenaikan` dan `tes_offline` RLS aktif tapi tanpa policy sama sekali,
--    padahal 013 membuatnya.

-- ============================================================
-- 1. Tutup EXECUTE untuk anon
-- ============================================================
-- PENTING: cabut dari role PUBLIC, bukan dari `anon`. Postgres memberi
-- EXECUTE ke PUBLIC secara default, dan `anon` adalah salah satu anggotanya,
-- jadi `revoke ... from anon` hanya menghapus grant eksplisit ke `anon` --
-- hak dari PUBLIC tetap menyala dan tidak ada yang berubah.
--
-- Catatan revisi: migrasi ini pernah ditulis `from anon` dan dilaporkan
-- berhasil, padahal tidak mengubah apa pun. Buktinya ada di
-- pg_proc.proacl: seluruh fungsi masih punya `=X/postgres`, yang artinya
-- "PUBLIC punya EXECUTE". Verifikasi lewat
--   select has_function_privilege('anon', oid, 'EXECUTE')
-- yang tetap true sampai dicabut dari PUBLIC.
revoke execute on function public.hapus_anggota_kelompok(bigint, bigint)   from public;
revoke execute on function public.hapus_kelas(bigint)                      from public;
revoke execute on function public.hapus_kelompok(bigint)                   from public;
revoke execute on function public.hapus_santri(bigint)                      from public;
revoke execute on function public.hapus_ustadz(bigint)                      from public;
revoke execute on function public.tambah_anggota_kelompok(bigint, bigint)  from public;
revoke execute on function public.tambah_kelas(text, text, int, numeric, numeric) from public;
revoke execute on function public.tambah_kelompok(text, int)               from public;
revoke execute on function public.tambah_santri(text, text)                from public;
revoke execute on function public.ubah_kelas(bigint, text, text, int, numeric, numeric) from public;
revoke execute on function public.ubah_kelompok(bigint, text, int)         from public;
revoke execute on function public.ubah_santri(bigint, text, text)          from public;
revoke execute on function public.ubah_ustadz(bigint, text)                 from public;

-- Helper. Dipakai di dalam policy RLS, jadi authenticated tetap butuh dan
-- diberi kembali di bawah. Dicabut dari PUBLIC supaya tidak bisa dipanggil
-- sebagai RPC tanpa login.
revoke execute on function public.is_ustadz()     from public;
revoke execute on function public.my_ustadz_id()  from public;

-- Event trigger DDL. Tidak pernah dipanggil lewat PostgREST; menutupnya
-- menutup satu-satunya cara memanggilnya sebagai fungsi biasa.
revoke execute on function public.rls_auto_enable() from public;

grant execute on function
  public.hapus_anggota_kelompok(bigint, bigint),
  public.hapus_kelas(bigint),
  public.hapus_kelompok(bigint),
  public.hapus_santri(bigint),
  public.hapus_ustadz(bigint),
  public.tambah_anggota_kelompok(bigint, bigint),
  public.tambah_kelas(text, text, int, numeric, numeric),
  public.tambah_kelompok(text, int),
  public.tambah_santri(text, text),
  public.ubah_kelas(bigint, text, text, int, numeric, numeric),
  public.ubah_kelompok(bigint, text, int),
  public.ubah_santri(bigint, text, text),
  public.ubah_ustadz(bigint, text),
  public.is_ustadz(),
  public.my_ustadz_id()
to authenticated;

-- ============================================================
-- 2. Pulihkan policy kenaikan & tes_offline
-- ============================================================
-- RLS aktif tapi tanpa policy = "gagal-tertutup": setiap SELECT mengembalikan
-- nol baris. Kedua tabel kehilangan policynya, jadi putuskan_kenaikan()
-- (SECURITY INVOKER) gagal menulis dan halaman kenaikan tidak membaca apa pun.
-- Definisi disalin apa adanya dari 013:134-140.
create policy baca on tes_offline for select to authenticated using (priv.is_ustadz());
create policy tulis on tes_offline for insert to authenticated
  with check (dicatat_oleh = priv.my_ustadz_id());

create policy baca on kenaikan for select to authenticated using (priv.is_ustadz());
create policy tulis on kenaikan for insert to authenticated
  with check (diputuskan_oleh = priv.my_ustadz_id());