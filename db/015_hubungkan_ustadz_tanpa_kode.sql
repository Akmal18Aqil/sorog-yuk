-- Kode klaim dihapus. Ustadz cukup memilih namanya sendiri dari daftar.
--
-- Kode 6 karakter itu satu langkah tambahan yang harus dibagikan lisan,
-- dicatat, dan sering hilang — beban nyata untuk keamanan yang sebenarnya
-- TUMPANG TINDIH dengan penjaga yang sudah ada.
--
-- Setelah perubahan ini, keamanan bersandar pada dua hal:
--   1. PENDAFTARAN DITUTUP di Supabase (Authentication -> Sign Ups).
--      Ini jadi WAJIB, bukan opsional. Selama pendaftaran terbuka, siapa pun
--      yang mendaftar bisa memilih nama ustadz yang belum terpakai.
--   2. RLS: akun yang belum terhubung ke baris `ustadz` tetap melihat nol baris.
create function public.hubungkan_ustadz(p_ustadz_id bigint) returns bigint
  language plpgsql security definer set search_path = '' as
$$
begin
  if (select auth.uid()) is null then
    raise exception 'Belum login.';
  end if;
  if priv.my_ustadz_id() is not null then
    raise exception 'Akun ini sudah terhubung ke seorang ustadz.';
  end if;

  -- Syarat `auth_id is null` yang membuat ini aman: nama yang sudah dipakai
  -- akun lain tidak bisa diambil alih.
  update public.ustadz set auth_id = (select auth.uid())
   where id = p_ustadz_id and auth_id is null;
  if not found then
    raise exception 'Nama itu sudah dipakai akun lain.';
  end if;

  return p_ustadz_id;
end
$$;

revoke all on function public.hubungkan_ustadz(bigint) from public, anon;
grant execute on function public.hubungkan_ustadz(bigint) to authenticated;

-- Jalur lama dibuang seluruhnya supaya tidak ada dua cara masuk yang hidup
-- berdampingan — satu pintu lebih mudah dijaga daripada dua.
drop function if exists public.klaim_ustadz(text);
drop table if exists public.ustadz_kode;
