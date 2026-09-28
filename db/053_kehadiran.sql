-- 053: kehadiran (absen + kendala harian, grain santri/hari)
--
-- `jawaban.catatan` tidak dipakai: grain-nya per-langkah, terlalu halus.
-- Satu baris per anak per hari: kirim ulang offline = keadaan yang sama.
-- ponytail: sehari 2x sorogan menimpa baris yang sama (upsert).
-- Upgrade path: pecah PK ke (tanggal, sesi_ke) kalau diminta.

create table if not exists public.kehadiran (
  id          bigint generated always as identity primary key,
  tanggal     date   not null default current_date,
  santri_id   bigint not null references public.santri(id) on delete cascade,
  kelompok_id bigint references public.kelompok(id) on delete set null,
  ustadz_id   bigint not null references public.ustadz(id),
  status      text   not null default 'hadir'
                check (status in ('hadir','izin','sakit','alpa')),
  kendala     text,
  dibuat_pada timestamptz not null default now(),
  unique (tanggal, santri_id)
);

create index if not exists kehadiran_tanggal_cari on public.kehadiran (tanggal desc);
create index if not exists kehadiran_santri_cari on public.kehadiran (santri_id, tanggal desc);
create index if not exists kehadiran_kelompok_cari on public.kehadiran (kelompok_id, tanggal desc);

alter table public.kehadiran enable row level security;

-- Semua ustadz boleh baca (laporan lintas kelompok butuh itu);
-- tulis hanya pemilik; superadmin penuh.
drop policy if exists baca_ustadz on public.kehadiran;
create policy baca_ustadz on public.kehadiran for select to authenticated
  using (priv.is_ustadz() or priv.is_superadmin());
drop policy if exists tulis_pemilik on public.kehadiran;
create policy tulis_pemilik on public.kehadiran for all to authenticated
  using (ustadz_id = priv.my_ustadz_id() or priv.is_superadmin())
  with check (ustadz_id = priv.my_ustadz_id() or priv.is_superadmin());
