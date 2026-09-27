-- Menutup dari PUBLIC saja TIDAK cukup untuk dua RPC baru ini.
--
-- Default privileges Supabase memberi EXECUTE ke `anon` dan `authenticated`
-- SECARA EKSPLISIT untuk setiap fungsi baru -- bukan melalui role PUBLIC.
-- Bukti di pg_proc.proacl sebelum migrasi ini:
--   {postgres=X, anon=X, authenticated=X, service_role=X}
-- `revoke ... from public` hanya menghapus entri `=X`; entri `anon=X`
-- tetap utuh. Harus mencabut grant ke `anon` itu sendiri.

revoke execute on function public.set_aktif_santri(bigint, boolean) from anon;
revoke execute on function public.set_aktif_ustadz(bigint, boolean) from anon;