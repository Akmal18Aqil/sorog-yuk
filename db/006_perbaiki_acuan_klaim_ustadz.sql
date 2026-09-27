-- PERBAIKAN untuk bug yang lolos dari migrasi 004.
--
-- 004 memindahkan my_ustadz_id() ke schema `priv`. Policy RLS ikut pindah
-- sendiri karena menyimpan OID fungsi, bukan namanya. Fungsi SQL gaya lama
-- sudah saya perbarui manual saat itu.
--
-- Yang terlewat: `klaim_ustadz` ditulis dalam PLPGSQL, dan plpgsql meresolusi
-- panggilan fungsi PER NAMA SAAT DIJALANKAN — bukan saat dibuat. Jadi tidak
-- ada error apa pun waktu migrasi dijalankan, dan baru meledak saat ustadz
-- pertama mencoba menghubungkan akunnya:
--
--     function public.my_ustadz_id() does not exist
--
-- Pelajarannya bukan "hati-hati memindahkan fungsi", tapi: setiap RPC harus
-- diuji lewat panggilan sungguhan. Uji sebelumnya menyetel ustadz.auth_id
-- dengan UPDATE langsung, jadi menguji SEKELILING jalur ini, bukan jalurnya.
-- Lihat db/007_check_klaim.sql.
create or replace function public.klaim_ustadz(p_kode text) returns bigint
  language plpgsql security definer set search_path = '' as
$$
declare v_id bigint;
begin
  if (select auth.uid()) is null then
    raise exception 'Belum login.';
  end if;
  if priv.my_ustadz_id() is not null then
    raise exception 'Akun ini sudah terhubung ke seorang ustadz.';
  end if;
  select k.ustadz_id into v_id
    from public.ustadz_kode k
    join public.ustadz u on u.id = k.ustadz_id
   where k.kode = upper(btrim(p_kode)) and u.auth_id is null;
  if v_id is null then
    raise exception 'Kode salah atau sudah dipakai.';
  end if;
  update public.ustadz set auth_id = (select auth.uid()) where id = v_id;
  return v_id;
end
$$;

revoke all on function public.klaim_ustadz(text) from public, anon;
grant execute on function public.klaim_ustadz(text) to authenticated;
