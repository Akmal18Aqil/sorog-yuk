-- Percobaan pertama: `revoke ... from public` seperti di 021. Tidak
-- berefek -- `anon` tetap punya EXECUTE. Alasannya ada di
-- pg_proc.proacl: default privileges Supabase memberi EXECUTE ke `anon`
-- SECARA EKSPLISIT, bukan lewat role PUBLIC, jadi revoke dari public
-- tidak menyentuhnya. Perbaikannya di 030.

revoke execute on function public.set_aktif_santri(bigint, boolean) from public;
revoke execute on function public.set_aktif_ustadz(bigint, boolean) from public;