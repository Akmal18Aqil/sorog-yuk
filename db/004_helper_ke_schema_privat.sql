-- Helper RLS tidak boleh bisa dipanggil lewat REST. Schema `priv` tidak
-- termasuk schema yang diekspos PostgREST, jadi fungsi di dalamnya hilang
-- dari API tapi tetap bisa dipakai policy.
create schema if not exists priv;
grant usage on schema priv to authenticated;

alter function public.my_ustadz_id() set schema priv;

-- Badan fungsi SQL gaya lama disimpan sebagai teks, jadi acuannya harus
-- diperbarui manual. CREATE OR REPLACE mempertahankan OID sehingga seluruh
-- policy yang menunjuk fungsi ini tetap utuh.
create or replace function public.is_ustadz() returns boolean
  language sql stable security definer set search_path = '' as
$$ select priv.my_ustadz_id() is not null $$;

alter function public.is_ustadz() set schema priv;

-- klaim_ustadz tetap di public: itu memang RPC yang dipanggil aplikasi.
revoke all on function public.klaim_ustadz(text) from anon;
