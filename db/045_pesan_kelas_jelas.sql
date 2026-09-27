-- `tambah_kelas` (018) dan `ubah_kelas` (018) meneruskan error UNIQUE mentah
-- apa adanya ke pengguna:
--
--   duplicate key value violates unique constraint "kelas_kode_key"
--
-- Itu benar -- kode BK1 memang sudah dipakai -- tapi tidak bisa dipakai.
-- Superadmin tidak jadi tahu kode itu sudah dipakai kelas yang mana.
--
-- Ada dua UNIQUE di `kelas`: `kode` DAN `urutan`. Yang kedua tidak pernah
-- disebut di mana pun, padahal itu yang menentukan kelas "berikutnya" saat
-- kenaikan. Kalau urutannya ikut kembar, pesan yang muncul menyebut
-- "urutan" -- padahal yang diketik dan dikira bermasalah adalah kode.
--
-- INDEX tidak bisa menulis pesan; hanya pemeriksaan eksplisit yang bisa.
-- Pola yang sama dipakai di `tautkan_akun` (041).

-- Cek `id <> p_id` di `ubah_kelas` itu wajib: tanpa itu setiap edit akan
-- menolak dirinya sendiri, karena kelas yang diedit tetap memakai kode dan
-- urutannya sendiri.

create or replace function public.tambah_kelas(
  p_kode text,
  p_nama text,
  p_urutan int,
  p_ambang_online  numeric default 70,
  p_ambang_offline numeric default 70
) returns bigint
  language plpgsql security definer set search_path = '' as
$$
declare v_id bigint; v_pemakai text;
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa menambah kelas.';
  end if;

  select nama into v_pemakai from public.kelas where kode = p_kode;
  if v_pemakai is not null then
    raise exception 'Kode "%" sudah dipakai oleh "%". Pilih kode lain, atau edit kelas itu.', p_kode, v_pemakai;
  end if;

  select nama into v_pemakai from public.kelas where urutan = p_urutan;
  if v_pemakai is not null then
    raise exception 'Urutan % sudah dipakai oleh "%".', p_urutan, v_pemakai;
  end if;

  if p_ambang_online not between 0 and 100 or p_ambang_offline not between 0 and 100 then
    raise exception 'Ambang harus antara 0 dan 100.';
  end if;

  insert into public.kelas (kode, nama, urutan, ambang_online, ambang_offline)
  values (p_kode, p_nama, p_urutan, p_ambang_online, p_ambang_offline)
  returning id into v_id;
  return v_id;
end
$$;

create or replace function public.ubah_kelas(
  p_id bigint,
  p_kode text,
  p_nama text,
  p_urutan int,
  p_ambang_online  numeric,
  p_ambang_offline numeric
) returns void
  language plpgsql security definer set search_path = '' as
$$
declare v_pemakai text;
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa mengubah kelas.';
  end if;

  select nama into v_pemakai from public.kelas
   where kode = p_kode and id <> p_id;
  if v_pemakai is not null then
    raise exception 'Kode "%" sudah dipakai oleh "%".', p_kode, v_pemakai;
  end if;

  select nama into v_pemakai from public.kelas
   where urutan = p_urutan and id <> p_id;
  if v_pemakai is not null then
    raise exception 'Urutan % sudah dipakai oleh "%".', p_urutan, v_pemakai;
  end if;

  if p_ambang_online not between 0 and 100 or p_ambang_offline not between 0 and 100 then
    raise exception 'Ambang harus antara 0 dan 100.';
  end if;

  update public.kelas
     set kode = p_kode, nama = p_nama, urutan = p_urutan,
         ambang_online = p_ambang_online, ambang_offline = p_ambang_offline
   where id = p_id;
end
$$;

revoke execute on function public.tambah_kelas(text, text, int, numeric, numeric) from public;
revoke execute on function public.tambah_kelas(text, text, int, numeric, numeric) from anon;
revoke execute on function public.ubah_kelas(bigint, text, text, int, numeric, numeric) from public;
revoke execute on function public.ubah_kelas(bigint, text, text, int, numeric, numeric) from anon;
grant execute on function
  public.tambah_kelas(text, text, int, numeric, numeric),
  public.ubah_kelas(bigint, text, text, int, numeric, numeric)
to authenticated;
