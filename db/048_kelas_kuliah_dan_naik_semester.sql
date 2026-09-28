-- Kelas kuliah & naik semester
--
-- Dua kebutuhan, dua sebab yang berbeda.
--
-- 1. KELOMPOK -> KELAS. "Kelompok 3" tidak bisa menjawab "anak-anak BK
--    apa?". `kelompok` punya `jenis` (sorogan/terjemah) tapi tidak pernah
--    punya penanda kelas, padahal `kelas` sudah jadi master data sejak 012.
--    Satu kolom FK, bukan tabel baru.
--
-- 2. JENJANG KULIAH. `santri.semester` SUDAH ada dan sudah terisi, jadi
--    "kelas kuliah" bukan entitas baru -- ia pengelompokan berdasarkan
--    semester. Yang belum ada hanya PERALIHANNYA. Maka TIDAK dibuat tabel
--    `kelas_kuliah`: tabel itu akan jadi salinan angka yang sudah ada, dan
--    dua sumber kebenaran untuk satu fakta pasti akhirnya beda.
--
-- Naik semester TIDAK dijadwalkan otomatis per tanggal. Kapan semester
-- berganti adalah keputusan pesantren -- ada yang mundur, ada yang naik
-- lebih cepat. Jadi filanya di tangan admin, dan angkanya divalidasi
-- server supaya tidak ada yang mengarang semester 13.
--
-- Yang SENGAJA tidak disentuh: `tingkat` (BK1/BK2) tetap sumbu MATERI,
-- `semester` tetap sumbu WAKTU. Keduanya beriringan, bukan salah satu
-- menggantikan yang lain (lihat 031).

-- ============================================================
-- 1. Kelompok tahu kelas mana yang dilayaninya
-- ============================================================
-- NULL = belum ditentukan, dan itu keadaan yang sah: kelompok terjemah
-- tidak punya tingkat baca kitab. Tidak di-backfill ke mana pun --
-- mengarang "kelompok ini pasti BK1" lebih buruk daripada jujur belum tahu.
alter table public.kelompok add column if not exists tingkat text;

alter table public.kelompok drop constraint if exists kelompok_tingkat_fk;
alter table public.kelompok add  constraint kelompok_tingkat_fk
  foreign key (tingkat) references public.kelas(kode) on update cascade;

create index if not exists kelompok_tingkat_cari on public.kelompok (tingkat);

-- ============================================================
-- 2. Naik semester
-- ============================================================
-- Dipanggil sekali dalam setahun, jadi efisiensi bukan masalah; yang
-- penting tidak bisa salah diam-diam. Empat hal dijaga:
--
--   a. Hanya superadmin. Menaikkan semester seluruh kelas adalah keputusan
--      yang tidak bisa dibatalkan dari layar biasa.
--   b. 1..12, sesuai domain yang sudah dipakai `santri.semester`. Ditolak
--      di sini, bukan di UI: UI bisa dilewati.
--   c. `p_ke` harus LEBIH BESAR dari `p_dari`. Tanpa ini, "naik" bisa
--      dimaknai turun -- dan tidak ada tempat untuk mengoreksi puluhan
--      baris yang salah tanpa cek satu per satu.
--   d. Hanya yang AKTIF. Nonaktif berarti sudah lulus atau keluar.
--      Menaikkan semester mereka tidak ada gunanya, dan merusak angka
--      tahun lulus. Jumlah yang dilewati dikembalikan supaya tidak hilang
--      tanpa jejak.
create or replace function public.naik_semester(
  p_dari int,
  p_ke   int
) returns json
  language plpgsql security definer set search_path = '' as
$$
declare
  v_aktif   int;
  v_nonaktif int;
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa menaikkan semester.';
  end if;

  if p_dari is null or p_ke is null then
    raise exception 'Semester asal dan semester tujuan wajib diisi.';
  end if;

  -- Pesannya menyebut angkanya supaya "130" tidak terasa seperti
  -- semester yang sah saat diinput.
  if p_dari not between 1 and 12 or p_ke not between 1 and 12 then
    raise exception 'Semester harus antara 1 dan 12 (dapat % dan %).', p_dari, p_ke;
  end if;

  if p_ke <= p_dari then
    raise exception 'Semester tujuan (%) harus lebih besar dari asal (%).', p_ke, p_dari;
  end if;

  update public.santri
     set semester = p_ke
   where semester = p_dari and aktif;

  get diagnostics v_aktif = row_count;

  select count(*) into v_nonaktif
    from public.santri
   where semester = p_dari and not aktif;

  return json_build_object('dipindah', v_aktif, 'dilewati', v_nonaktif);
end
$$;

-- ============================================================
-- 3. RPC kelompok ikut membawa tingkat
-- ============================================================
-- Tanda tangan lama dibuang lebih dulu, bukan ditimpa: Postgres mengizinkan
-- overloading, dan dua versi hidup berdampingan membuat pemanggil lama
-- diam-diam menyimpan kelompok tanpa tingkat (pola yang sama seperti 008).
drop function if exists public.tambah_kelompok(text, int);
drop function if exists public.ubah_kelompok(bigint, text, int);

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
  update public.kelompok
     set nama = p_nama, urutan = p_urutan, tingkat = p_tingkat
   where id = p_id;
end
$$;

-- ============================================================
-- 4. Grant
-- ============================================================
-- CATATAN (025): `revoke ... from public` saja tidak cukup untuk fungsi
-- baru -- default privileges Supabase memberi EXECUTE ke `anon` dan
-- `authenticated` secara eksplisit, jadi `revoke ... from anon` wajib
-- ditulis langsung.
revoke execute on function public.naik_semester(int, int) from public;
revoke execute on function public.naik_semester(int, int) from anon;
revoke execute on function public.tambah_kelompok(text, int, text) from public;
revoke execute on function public.tambah_kelompok(text, int, text) from anon;
revoke execute on function public.ubah_kelompok(bigint, text, int, text) from public;
revoke execute on function public.ubah_kelompok(bigint, text, int, text) from anon;

grant execute on function
  public.naik_semester(int, int),
  public.tambah_kelompok(text, int, text),
  public.ubah_kelompok(bigint, text, int, text)
to authenticated;
