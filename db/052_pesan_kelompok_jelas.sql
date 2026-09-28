-- Pesan kelompok yang bisa dibaca, lanjutan pola 045 (pesan kelas jelas).
--
-- Setelah 051, "Kelompok 1" sah ada di beberapa kelas sekaligus. Tapi
-- `tambah_kelompok` dan `ubah_kelompok` (048) meneruskan error UNIQUE mentah
-- apa adanya:
--
--   duplicate key value violates unique constraint "kelompok_tingkat_nama_key"
--   DETAIL:  Key (tingkat, nama)=(BK1, Kelompok 1) already exists.
--
-- Itu benar -- memang sudah ada -- tapi tidak bisa dipakai: superadmin tidak
-- jadi tahu apakah bentroknya di kelas yang sama atau di kelas lain, dan
-- justru itu satu-satunya hal yang perlu diperbaiki.
--
-- Dua pemeriksaan ditambahkan, keduanya hanya bisa memberi pesan yang jelas
-- lewat pemeriksaan eksplisit -- INDEX dan FOREIGN KEY tidak bisa menulis
-- pesan sendiri:
--
--   1. Pasangan (kelas, nama) yang sudah dipakai -> sebutkan kelasnya.
--   2. Kode kelas yang tidak ada di master `kelas` -> sebut kodenya.
--      Sebelumnya ini jatuh ke error FK mentah.
--
-- `is not distinct from` dipakai untuk membandingkan tingkat: `= NULL`
-- menghasilkan NULL, jadi kelompok tanpa kelas tidak akan pernah terdeteksi
-- bentrok padahal 051 sengaja menolaknya.

create or replace function public.tambah_kelompok(
  p_nama    text,
  p_urutan  int  default null,
  p_tingkat text default null
) returns bigint
  language plpgsql security definer set search_path = '' as
$$
declare v_id bigint;
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa menambah kelompok.';
  end if;

  if p_tingkat is not null and not exists (
    select 1 from public.kelas where kode = p_tingkat
  ) then
    raise exception 'Kelas "%" tidak dikenal. Pilih dari daftar kelas.', p_tingkat;
  end if;

  if exists (
    select 1 from public.kelompok
     where nama = p_nama and tingkat is not distinct from p_tingkat
  ) then
    raise exception 'Kelompok "%" sudah ada di %.',
      p_nama,
      coalesce((select k.nama from public.kelas k where k.kode = p_tingkat),
               'kelompok tanpa kelas');
  end if;

  insert into public.kelompok (nama, urutan, tingkat)
  values (p_nama, p_urutan, p_tingkat)
  returning id into v_id;
  return v_id;
end
$$;

create or replace function public.ubah_kelompok(
  p_id      bigint,
  p_nama    text,
  p_urutan  int  default null,
  p_tingkat text default null
) returns void
  language plpgsql security definer set search_path = '' as
$$
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa mengubah kelompok.';
  end if;

  if p_tingkat is not null and not exists (
    select 1 from public.kelas where kode = p_tingkat
  ) then
    raise exception 'Kelas "%" tidak dikenal. Pilih dari daftar kelas.', p_tingkat;
  end if;

  -- `id <> p_id`: baris ini sendiri tidak dihitung bentrok, kalau tidak
  -- menyimpan tanpa mengubah namanya akan ditolak.
  if exists (
    select 1 from public.kelompok
     where nama = p_nama
       and tingkat is not distinct from p_tingkat
       and id <> p_id
  ) then
    raise exception 'Kelompok "%" sudah ada di %.',
      p_nama,
      coalesce((select k.nama from public.kelas k where k.kode = p_tingkat),
               'kelompok tanpa kelas');
  end if;

  update public.kelompok
     set nama = p_nama, urutan = p_urutan, tingkat = p_tingkat
   where id = p_id;
end
$$;
