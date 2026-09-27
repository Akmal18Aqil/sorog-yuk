-- Sorogan Digital — RPC toggle aktif + hapus yang menjelaskan dirinya
--
-- D1/D2 dari docs/23-master-data.md. Kolom `aktif` sudah ada (019); ini
-- memberi jalan untuk memakainya.
--
-- Yang dijaga di sini: `hapus_santri`/`hapus_ustadz` dulunya gagal dengan
-- error FK mentah ("violates foreign key constraint") yang tidak
-- memberitahu superadmin APA yang harus dilakukan. D2: gagal dengan kalimat
-- yang bisa langsung ditindaklanjuti — yaitu "nonaktifkan, jangan hapus".
--
-- (026 melengkapi cek riwayat hapus_santri; 027/028 sisi pembacaan.)

-- ============================================================
-- 1. Toggle aktif (superadmin saja)
-- ============================================================
create or replace function public.set_aktif_santri(
  p_id    bigint,
  p_aktif boolean
) returns void
  language plpgsql security definer set search_path = '' as
$$
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa menonaktifkan santri.';
  end if;
  if not exists (select 1 from public.santri where id = p_id) then
    raise exception 'Santri tidak ditemukan.';
  end if;
  update public.santri set aktif = p_aktif where id = p_id;
end
$$;

create or replace function public.set_aktif_ustadz(
  p_id    bigint,
  p_aktif boolean
) returns void
  language plpgsql security definer set search_path = '' as
$$
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa menonaktifkan mentor.';
  end if;
  if not exists (select 1 from public.ustadz where id = p_id) then
    raise exception 'Ustadz tidak ditemukan.';
  end if;
  -- Superadmin tidak boleh dinonaktifkan lewat jalur ini: satu-satunya
  -- akun yang bisa memanggilnya adalah superadmin, jadi memblokirnya
  -- berarti tidak ada cara memulihkan kalau tidak ada superadmin lain.
  if (select role from public.ustadz where id = p_id) = 'superadmin' and not p_aktif then
    raise exception 'Superadmin tidak bisa dinonaktifkan dari sini.';
  end if;
  update public.ustadz set aktif = p_aktif where id = p_id;
end
$$;
-- ============================================================
-- 2. Hapus: pesan jelas, bukan error FK mentah
-- ============================================================
create or replace function public.hapus_ustadz(p_id bigint) returns void
  language plpgsql security definer set search_path = '' as
$$
declare v_nama text;
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa menghapus ustad.';
  end if;
  select nama into v_nama from public.ustadz where id = p_id and role = 'ustadz';
  if v_nama is null then
    raise exception 'Ustadz tidak ditemukan.';
  end if;
  if exists (select 1 from public.sesi where ustadz_id = p_id) then
    raise exception
      '% sudah punya riwayat sesi. Nonaktifkan, jangan hapus — riwayatnya masih dipakai.', v_nama;
  end if;
  delete from public.ustadz where id = p_id;
end
$$;

-- ============================================================
-- 3. Daftar admin harus membawa `aktif`, kalau tidak UI tidak bisa
--    menampilkan siapa yang nonaktif.
-- ============================================================
create or replace function public.ambil_semua_santri() returns json
  language plpgsql security definer set search_path = '' as
$$
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa mengakses.';
  end if;
  return (
    select json_agg(json_build_object(
      'id', t.id, 'nama', t.nama, 'tingkat', t.tingkat,
      'auth_id', t.auth_id, 'aktif', t.aktif
    ) order by t.nama)
    from (select id, nama, tingkat, auth_id, aktif from public.santri) t
  );
end
$$;

create or replace function public.ambil_semua_ustadz() returns json
  language plpgsql security definer set search_path = '' as
$$
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa mengakses.';
  end if;
  return (
    select json_agg(json_build_object(
      'id', t.id, 'nama', t.nama, 'role', t.role, 'auth_id', t.auth_id,
      'aktif', t.aktif,
      'kode', t.kode, 'kode_digunakan', t.kode_digunakan
    ) order by t.nama)
    from (
      SELECT u.id, u.nama, u.role, u.auth_id, u.aktif,
        (SELECT kode FROM public.ustadz_kode WHERE ustadz_id = u.id LIMIT 1) as kode,
        (SELECT digunakan FROM public.ustadz_kode WHERE ustadz_id = u.id LIMIT 1) as kode_digunakan
      FROM public.ustadz u
      WHERE u.role = 'ustadz'
    ) t
  );
end
$$;

-- Statistik = angka operasional. Santri/mentor nonaktif tidak lagi
-- mengajar, jadi menghitungnya membuat angka ini berbohong.
create or replace function public.ambil_statistik() returns json
  language plpgsql security definer set search_path = '' as
$$
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa mengakses.';
  end if;
  return json_build_object(
    'jml_ustadz', (select count(*) from public.ustadz where role = 'ustadz' and aktif),
    'jml_santri', (select count(*) from public.santri where aktif),
    'jml_kelas', (select count(*) from public.kelas),
    'jml_kelompok', (select count(*) from public.kelompok),
    'jml_sesi_bulan_ini', (
      select count(*) from public.sesi
      where tanggal >= date_trunc('month', current_date)
    )
  );
end
$$;

-- ============================================================
-- 4. Grant
-- ============================================================
-- CATATAN: `revoke ... from public` saja TIDAK cukup untuk fungsi baru.
-- Default privileges Supabase memberi EXECUTE ke `anon` dan
-- `authenticated` SECARA EKSPLISIT (bukan lewat PUBLIC), jadi entri
-- `anon=X` di pg_proc.proacl tetap ada. Harus `revoke ... from anon`
-- secara langsung — lihat 030, yang mengulang grant ini setelah dicabut.
revoke execute on function public.set_aktif_santri(bigint, boolean) from public;
revoke execute on function public.set_aktif_ustadz(bigint, boolean) from public;
grant execute on function
  public.set_aktif_santri(bigint, boolean),
  public.set_aktif_ustadz(bigint, boolean)
to authenticated;