-- Sorogan Digital — Role-Based Access Control
-- 3 role: superadmin, ustadz, santri

-- ============================================================
-- 1. Tambah kolom role ke ustadz
-- ============================================================

alter table public.ustadz
  add column role text not null default 'ustadz'
  check (role in ('superadmin', 'ustadz'));

-- ============================================================
-- 2. Tambah auth_id ke santri (untuk login santri)
-- ============================================================

alter table public.santri
  add column auth_id uuid unique references auth.users(id) on delete set null;

-- ============================================================
-- 3. Seed superadmin (1 akun)
-- ============================================================

insert into public.ustadz (nama, role) values ('Super Admin', 'superadmin')
on conflict do nothing;

-- ============================================================
-- 4. Tabel kode undangan ustad
-- ============================================================

create table if not exists public.ustadz_kode (
  kode        text primary key,
  ustadz_id   bigint not null references public.ustadz(id) on delete cascade,
  digunakan   boolean not null default false,
  dibuat_pada timestamptz not null default now()
);

alter table public.ustadz_kode enable row level security;

-- ============================================================
-- 5. Update security functions
-- ============================================================

-- Drop old functions first
drop function if exists public.my_ustadz_id() cascade;
drop function if exists public.is_ustadz() cascade;
drop function if exists public.hubungkan_ustadz(bigint) cascade;

-- Return role user saat ini
create function priv.my_role() returns text
  language sql stable security definer set search_path = '' as
$$
  select role from public.ustadz where auth_id = (select auth.uid())
  limit 1
$$;

-- Superadmin check
create function priv.is_superadmin() returns boolean
  language sql stable security definer set search_path = '' as
$$ select priv.my_role() = 'superadmin' $$;

-- Ustadz check (role = 'ustadz', bukan superadmin)
create function priv.is_ustadz() returns boolean
  language sql stable security definer set search_path = '' as
$$ select priv.my_role() = 'ustadz' $$;

-- Santri check: auth_id ada di tabel santri
create function priv.my_santri_id() returns bigint
  language sql stable security definer set search_path = '' as
$$ select id from public.santri where auth_id = (select auth.uid()) $$;

create function priv.is_santri() returns boolean
  language sql stable security definer set search_path = '' as
$$ select priv.my_santri_id() is not null $$;

-- my_ustadz_id() tetap dibutuhkan untuk RLS ustadz
create function public.my_ustadz_id() returns bigint
  language sql stable security definer set search_path = '' as
$$ select id from public.ustadz where auth_id = (select auth.uid()) and role = 'ustadz' $$;

-- is_ustadz() versi public (untuk kompatibilitas)
create function public.is_ustadz() returns boolean
  language sql stable security definer set search_path = '' as
$$ select priv.is_ustadz() $$;

-- ============================================================
-- 6. RPC: daftar santri (setelah signup via Supabase Auth di client)
-- ============================================================

create function public.daftar_santri(
  p_nama text,
  p_tingkat text default 'BK1'
) returns bigint
  language plpgsql security definer set search_path = '' as
$$
declare
  v_auth_id uuid;
  v_id bigint;
begin
  if (select auth.uid()) is null then
    raise exception 'Belum login.';
  end if;

  v_auth_id := (select auth.uid());

  -- Cek apakah sudah terdaftar sebagai santri
  if exists (select 1 from public.santri where auth_id = v_auth_id) then
    raise exception 'Akun ini sudah terdaftar sebagai santri.';
  end if;

  insert into public.santri (nama, tingkat, auth_id)
  values (p_nama, p_tingkat, v_auth_id)
  returning id into v_id;

  return v_id;
end
$$;

revoke all on function public.daftar_santri(text, text) from public, anon;
grant execute on function public.daftar_santri(text, text) to authenticated;

-- ============================================================
-- 7. RPC: tambah ustad (oleh superadmin)
-- ============================================================

create function public.tambah_ustadz(p_nama text) returns bigint
  language plpgsql security definer set search_path = '' as
$$
declare
  v_id bigint;
  v_kode text;
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa menambah ustad.';
  end if;

  insert into public.ustadz (nama, role) values (p_nama, 'ustadz')
  returning id into v_id;

  -- Generate kode undangan 6 karakter
  v_kode := upper(substr(md5(random()::text), 1, 6));
  insert into public.ustadz_kode (kode, ustadz_id) values (v_kode, v_id);

  return v_id;
end
$$;

revoke all on function public.tambah_ustadz(text) from public, anon;
grant execute on function public.tambah_ustadz(text) to authenticated;

-- ============================================================
-- 8. RPC: daftar ustad pakai kode undangan
-- ============================================================

create function public.daftar_ustadz(p_kode text) returns bigint
  language plpgsql security definer set search_path = '' as
$$
declare
  v_ustadz_id bigint;
begin
  if (select auth.uid()) is null then
    raise exception 'Belum login.';
  end if;

  if public.my_ustadz_id() is not null then
    raise exception 'Akun ini sudah terhubung ke seorang ustadz.';
  end if;

  -- Cari kode yang valid
  select k.ustadz_id into v_ustadz_id
    from public.ustadz_kode k
    join public.ustadz u on u.id = k.ustadz_id
   where k.kode = upper(btrim(p_kode))
     and k.digunakan = false
     and u.auth_id is null;

  if v_ustadz_id is null then
    raise exception 'Kode salah atau sudah dipakai.';
  end if;

  -- Link auth_id
  update public.ustadz set auth_id = (select auth.uid())
   where id = v_ustadz_id and auth_id is null;

  if not found then
    raise exception 'Nama itu sudah dipakai akun lain.';
  end if;

  -- Tandai kode sebagai digunakan
  update public.ustadz_kode set digunakan = true
   where kode = upper(btrim(p_kode));

  return v_ustadz_id;
end
$$;

revoke all on function public.daftar_ustadz(text) from public, anon;
grant execute on function public.daftar_ustadz(text) to authenticated;

-- ============================================================
-- 9. RPC: ambil semua ustad (untuk admin panel)
-- ============================================================

create function public.ambil_semua_ustadz() returns json
  language plpgsql security definer set search_path = '' as
$$
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa mengakses.';
  end if;

  return (
    select coalesce(json_agg(json_build_object(
      'id', u.id,
      'nama', u.nama,
      'role', u.role,
      'auth_id', u.auth_id,
      'kode', k.kode,
      'kode_digunakan', k.digunakan
    )), '[]'::json)
    from public.ustadz u
    left join public.ustadz_kode k on k.ustadz_id = u.id
    where u.role = 'ustadz'
    order by u.nama
  );
end
$$;

revoke all on function public.ambil_semua_ustadz() from public, anon;
grant execute on function public.ambil_semua_ustadz() to authenticated;

-- ============================================================
-- 10. RPC: ambil semua santri (untuk admin panel)
-- ============================================================

create function public.ambil_semua_santri() returns json
  language plpgsql security definer set search_path = '' as
$$
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa mengakses.';
  end if;

  return (
    select coalesce(json_agg(json_build_object(
      'id', s.id,
      'nama', s.nama,
      'tingkat', s.tingkat,
      'auth_id', s.auth_id
    )), '[]'::json)
    from public.santri s
    order by s.nama
  );
end
$$;

revoke all on function public.ambil_semua_santri() from public, anon;
grant execute on function public.ambil_semua_santri() to authenticated;

-- ============================================================
-- 11. RPC: ambil statistik (untuk admin dashboard)
-- ============================================================

create function public.ambil_statistik() returns json
  language plpgsql security definer set search_path = '' as
$$
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa mengakses.';
  end if;

  return json_build_object(
    'jml_ustadz', (select count(*) from public.ustadz where role = 'ustadz'),
    'jml_santri', (select count(*) from public.santri),
    'jml_kelas', (select count(*) from public.kelas),
    'jml_kelompok', (select count(*) from public.kelompok),
    'jml_sesi_bulan_ini', (
      select count(*) from public.sesi
      where tanggal >= date_trunc('month', current_date)
    )
  );
end
$$;

revoke all on function public.ambil_statistik() from public, anon;
grant execute on function public.ambil_statistik() to authenticated;

-- ============================================================
-- 12. RPC: daftar ustad langsung oleh admin (buat akun + link)
-- ============================================================

create function public.daftar_ustadz_langsung(
  p_nama text,
  p_email text
) returns json
  language plpgsql security definer set search_path = '' as
$$
declare
  v_id bigint;
  v_kode text;
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa menambah ustad.';
  end if;

  -- Buat record ustadz
  insert into public.ustadz (nama, role) values (p_nama, 'ustadz')
  returning id into v_id;

  -- Generate kode undangan
  v_kode := upper(substr(md5(random()::text), 1, 6));
  insert into public.ustadz_kode (kode, ustadz_id) values (v_kode, v_id);

  return json_build_object(
    'id', v_id,
    'kode', v_kode,
    'email', p_email
  );
end
$$;

revoke all on function public.daftar_ustadz_langsung(text, text) from public, anon;
grant execute on function public.daftar_ustadz_langsung(text, text) to authenticated;

-- ============================================================
-- 13. Update RLS policies
-- ============================================================

-- Hapus semua policy lama
drop policy if exists baca on kitab;
drop policy if exists baca on ibarat;
drop policy if exists baca on langkah;
drop policy if exists baca on soal;
drop policy if exists tulis on soal;
drop policy if exists baca on santri;
drop policy if exists tulis on santri;
drop policy if exists ubah on santri;
drop policy if exists baca on ustadz;
drop policy if exists baca on sesi;
drop policy if exists tulis on sesi;
drop policy if exists ubah on sesi;
drop policy if exists hapus on sesi;
drop policy if exists baca on penilaian;
drop policy if exists tulis on penilaian;
drop policy if exists baca on jawaban;
drop policy if exists tulis on jawaban;

-- Kitab: semua authenticated bisa baca, superadmin bisa tulis
create policy baca on kitab for select to authenticated using (true);
create policy tulis_admin on kitab for insert to authenticated with check (priv.is_superadmin());
create policy ubah_admin on kitab for update to authenticated using (priv.is_superadmin());
create policy hapus_admin on kitab for delete to authenticated using (priv.is_superadmin());

-- Ibarat: sama dengan kitab
create policy baca on ibarat for select to authenticated using (true);
create policy tulis_admin on ibarat for insert to authenticated with check (priv.is_superadmin());
create policy ubah_admin on ibarat for update to authenticated using (priv.is_superadmin());
create policy hapus_admin on ibarat for delete to authenticated using (priv.is_superadmin());

-- Langkah: semua authenticated bisa baca, superadmin bisa tulis
create policy baca on langkah for select to authenticated using (true);
create policy tulis_admin on langkah for insert to authenticated with check (priv.is_superadmin());
create policy ubah_admin on langkah for update to authenticated using (priv.is_superadmin());
create policy hapus_admin on langkah for delete to authenticated using (priv.is_superadmin());

-- Soal: ustadz + superadmin bisa baca, superadmin bisa tulis
create policy baca on soal for select to authenticated using (priv.is_ustadz() or priv.is_superadmin());
create policy tulis_admin on soal for insert to authenticated with check (priv.is_superadmin());
create policy ubah_admin on soal for update to authenticated using (priv.is_superadmin());
create policy hapus_admin on soal for delete to authenticated using (priv.is_superadmin());

-- Santri: superadmin full, ustadz baca tulis, santri baca sendiri
create policy baca_admin on santri for select to authenticated using (priv.is_superadmin());
create policy baca_ustadz on santri for select to authenticated using (priv.is_ustadz());
create policy baca_santri on santri for select to authenticated using (id = priv.my_santri_id());
create policy tulis_admin on santri for insert to authenticated with check (priv.is_superadmin());
create policy ubah_admin on santri for update to authenticated using (priv.is_superadmin());
create policy ubah_santri on santri for update to authenticated using (id = priv.my_santri_id());

-- Ustadz: semua authenticated baca nama, superadmin bisa tulis
-- Pakai direct auth_id check (bukan priv.is_superadmin) untuk hindari circular dependency
create policy baca_admin on ustadz for select to authenticated
  using (auth_id = (select auth.uid()));
create policy baca_nama on ustadz for select to authenticated using (true);
create policy tulis_admin on ustadz for insert to authenticated
  with check (exists (select 1 from public.ustadz where auth_id = (select auth.uid()) and role = 'superadmin'));
create policy ubah_admin on ustadz for update to authenticated
  using (exists (select 1 from public.ustadz where auth_id = (select auth.uid()) and role = 'superadmin'));
create policy hapus_admin on ustadz for delete to authenticated
  using (exists (select 1 from public.ustadz where auth_id = (select auth.uid()) and role = 'superadmin'));

-- Ustadz kode: superadmin full (direct auth_id check)
create policy baca_admin on ustadz_kode for select to authenticated
  using (exists (select 1 from public.ustadz where auth_id = (select auth.uid()) and role = 'superadmin'));
create policy tulis_admin on ustadz_kode for insert to authenticated
  with check (exists (select 1 from public.ustadz where auth_id = (select auth.uid()) and role = 'superadmin'));
create policy ubah_admin on ustadz_kode for update to authenticated
  using (exists (select 1 from public.ustadz where auth_id = (select auth.uid()) and role = 'superadmin'));
create policy hapus_admin on ustadz_kode for delete to authenticated
  using (exists (select 1 from public.ustadz where auth_id = (select auth.uid()) and role = 'superadmin'));

-- Sesi: superadmin full, ustadz own only, santri baca yang diikuti
create policy baca_admin on sesi for select to authenticated using (priv.is_superadmin());
create policy baca_ustadz on sesi for select to authenticated using (priv.is_ustadz());
create policy baca_santri on sesi for select to authenticated using (
  exists (
    select 1 from public.penilaian p
    where p.sesi_id = id and p.santri_id = priv.my_santri_id()
  )
);
create policy tulis_ustadz on sesi for insert to authenticated
  with check (ustadz_id = public.my_ustadz_id());
create policy tulis_admin on sesi for insert to authenticated
  with check (priv.is_superadmin());
create policy ubah_ustadz on sesi for update to authenticated
  using (ustadz_id = public.my_ustadz_id());
create policy ubah_admin on sesi for update to authenticated
  using (priv.is_superadmin());
create policy hapus_ustadz on sesi for delete to authenticated
  using (ustadz_id = public.my_ustadz_id());
create policy hapus_admin on sesi for delete to authenticated
  using (priv.is_superadmin());

-- Penilaian: superadmin full, ustadz own only, santri baca sendiri
create policy baca_admin on penilaian for select to authenticated using (priv.is_superadmin());
create policy baca_ustadz on penilaian for select to authenticated using (priv.is_ustadz());
create policy baca_santri on penilaian for select to authenticated
  using (santri_id = priv.my_santri_id());
create policy tulis_ustadz on penilaian for all to authenticated
  using (exists (select 1 from public.sesi s where s.id = sesi_id and s.ustadz_id = public.my_ustadz_id()))
  with check (exists (select 1 from public.sesi s where s.id = sesi_id and s.ustadz_id = public.my_ustadz_id()));
create policy tulis_admin on penilaian for all to authenticated
  using (priv.is_superadmin())
  with check (priv.is_superadmin());

-- Jawaban: superadmin full, ustadz own only, santri baca sendiri
create policy baca_admin on jawaban for select to authenticated using (priv.is_superadmin());
create policy baca_ustadz on jawaban for select to authenticated using (priv.is_ustadz());
create policy baca_santri on jawaban for select to authenticated using (
  exists (
    select 1 from public.penilaian p
    where p.id = penilaian_id and p.santri_id = priv.my_santri_id()
  )
);
create policy tulis_ustadz on jawaban for all to authenticated
  using (exists (
    select 1 from public.penilaian p
    join public.sesi s on s.id = p.sesi_id
    where p.id = penilaian_id and s.ustadz_id = public.my_ustadz_id()
  ))
  with check (exists (
    select 1 from public.penilaian p
    join public.sesi s on s.id = p.sesi_id
    where p.id = penilaian_id and s.ustadz_id = public.my_ustadz_id()
  ));
create policy tulis_admin on jawaban for all to authenticated
  using (priv.is_superadmin())
  with check (priv.is_superadmin());
