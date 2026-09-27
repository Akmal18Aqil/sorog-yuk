-- Manajemen akun: tautkan, bukan buat baris baru.
--
-- Masalah yang diselesaikan: sebelum ini, satu-satunya jalan membuat akun
-- adalah Edge Function `create-user`, yang INSERT baris `santri`/`ustadz`
-- BARU. Setelah 144 mahasantri diimpor (038/039), itu jadi berbahaya: satu
-- klik "Tambah" menghasilkan orang kedua dengan nama mirip, dan yang lama
-- tetap tanpa akun. Baris sudah benar sejak dulu; yang belum ada hanya
-- akun auth-nya.
--
-- Yang ditambahkan: RPC yang MENautkan auth_id ke baris yang sudah ada.
--
-- `nama` sengaja tidak ikut disentuh. Trigger penjaga kolom (024/038b)
-- tetap berlaku dan itu benar -- menautkan akun tidak boleh mengubah
-- identitas orang.

create or replace function public.tautkan_akun(
  p_jenis   text,
  p_id      bigint,
  p_auth_id uuid
) returns void
  language plpgsql security definer set search_path = '' as
$$
declare v_nama text; v_lama uuid; v_pemakai text;
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa menautkan akun.';
  end if;
  if p_auth_id is null then
    raise exception 'Akun tidak ditemukan.';
  end if;
  if p_jenis not in ('santri', 'ustadz') then
    raise exception 'Jenis tidak dikenal: %', p_jenis;
  end if;

  -- Akun sudah dipakai baris lain? INDEX UNIQUE akan menolaknya juga, tapi
  -- pesannya ("duplicate key value violates unique constraint") tidak
  -- memberi superadmin tahu AKUN mana yang terpakai dan oleh siapa.
  -- INDEX tidak bisa menulis pesan -- hanya pemeriksa eksplisit yang bisa.
  if p_jenis = 'santri' then
    select nama into v_pemakai from public.santri
     where auth_id = p_auth_id and id <> p_id;
  else
    select nama into v_pemakai from public.ustadz
     where auth_id = p_auth_id and id <> p_id;
  end if;
  if v_pemakai is not null then
    raise exception 'Akun itu sudah dipakai oleh %.', v_pemakai;
  end if;

  if p_jenis = 'santri' then
    select nama, auth_id into v_nama, v_lama from public.santri where id = p_id;
    if v_nama is null then raise exception 'Santri tidak ditemukan.'; end if;
    if v_lama is not null and v_lama <> p_auth_id then
      raise exception '% sudah punya akun. Lepas dulu sebelum menautkan yang lain.', v_nama;
    end if;
    update public.santri set auth_id = p_auth_id where id = p_id;
  else
    select nama, auth_id into v_nama, v_lama from public.ustadz where id = p_id;
    if v_nama is null then raise exception 'Ustadz tidak ditemukan.'; end if;
    if v_lama is not null and v_lama <> p_auth_id then
      raise exception '% sudah punya akun. Lepas dulu sebelum menautkan yang lain.', v_nama;
    end if;
    update public.ustadz set auth_id = p_auth_id where id = p_id;
  end if;
end
$$;

-- Lepas: `auth_id` jadi NULL. Akun auth-nya sendiri TIDAK dihapus --
-- menghapus akun berarti menghapus kata sandi orang, dan itu tidak
-- selalu diinginkan. Dipisah supaya "tautkan" dan "hapus akun" tidak jadi
-- satu tombol yang salah klik bisa membuat orang orang kehilangan akses.
create or replace function public.lepas_akun(
  p_jenis text,
  p_id    bigint
) returns void
  language plpgsql security definer set search_path = '' as
$$
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa melepas akun.';
  end if;
  if p_jenis = 'santri' then
    update public.santri set auth_id = null where id = p_id;
  elsif p_jenis = 'ustadz' then
    update public.ustadz set auth_id = null where id = p_id;
  else
    raise exception 'Jenis tidak dikenal: %', p_jenis;
  end if;
end
$$;

revoke execute on function public.tautkan_akun(text, bigint, uuid) from public;
revoke execute on function public.tautkan_akun(text, bigint, uuid) from anon;
revoke execute on function public.lepas_akun(text, bigint) from public;
revoke execute on function public.lepas_akun(text, bigint) from anon;
grant execute on function
  public.tautkan_akun(text, bigint, uuid),
  public.lepas_akun(text, bigint)
to authenticated;
