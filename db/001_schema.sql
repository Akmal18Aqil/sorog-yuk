-- Sorogan Digital — skema inti
-- Prinsip: yang disimpan adalah VERDICT PER LANGKAH, bukan nilai.
-- Semua nilai & analitik diturunkan lewat view (bagian 4), tidak pernah ditulis.

-- ============================================================
-- 1. Materi
-- ============================================================

create table kitab (
  id        bigint generated always as identity primary key,
  nama      text not null,
  pengarang text
);

create table ibarat (
  id       bigint generated always as identity primary key,
  kitab_id bigint not null references kitab(id) on delete cascade,
  urutan   int,
  halaman  int,
  teks     text not null              -- disimpan utuh; pemenggalan kata di UI
);

create table soal (
  id         bigint generated always as identity primary key,
  ibarat_id  bigint not null references ibarat(id) on delete cascade,
  teks       text not null,           -- lafad tunggal (BK1) atau potongan tarkib (BK2)
  tipe       text not null check (tipe in ('lafad','ismiyah','filiyah','nawasikh','tabi')),
  tingkat    text not null check (tingkat in ('BK1','BK2')),
  nomor_bank int,                     -- 1..60 utk BK2; null utk lafad hasil ketukan
  -- kunci gabungan ini yang membuat lafad sama dari penguji berbeda menyatu
  -- jadi satu baris, sehingga bisa dibandingkan antar santri
  unique (ibarat_id, teks, tipe)
);

-- Rubrik. Ditentukan TIPE, bukan per-soal: satu tangga dipakai puluhan soal.
create table langkah (
  id              bigint generated always as identity primary key,
  tipe            text not null,
  urutan          int  not null,
  pertanyaan      text not null,
  bersyarat       text,               -- petunjuk UI ('isim','marifat','mabni','selain_athaf')
  sekali_per_sesi boolean not null default false,
  unique (tipe, urutan)
);

-- ============================================================
-- 2. Pelaku
-- ============================================================

create table santri (
  id      bigint generated always as identity primary key,
  nama    text not null,
  kelas   text,
  tingkat text not null default 'BK1' check (tingkat in ('BK1','BK2'))
  -- tingkat SEKARANG, hanya untuk memilih bank soal.
  -- Riwayat tingkat tidak disimpan: sudah terbaca dari soal.tingkat penilaian lampau.
);

create table ustadz (
  id      bigint generated always as identity primary key,
  nama    text not null,
  auth_id uuid unique references auth.users(id) on delete set null
);

-- Kode klaim identitas. RLS aktif TANPA policy apa pun => tidak bisa dibaca
-- lewat API sama sekali, hanya lewat fungsi klaim_ustadz() di bawah.
create table ustadz_kode (
  ustadz_id bigint primary key references ustadz(id) on delete cascade,
  kode      text not null unique
);

-- ============================================================
-- 3. Pelaksanaan
-- ============================================================

create table sesi (
  id           bigint generated always as identity primary key,
  tanggal      date not null default current_date,
  ustadz_id    bigint not null references ustadz(id),
  mode         text not null default 'ujian' check (mode in ('ujian','harian')),
  dibuat_pada  timestamptz not null default now()
);

create table penilaian (
  id         bigint generated always as identity primary key,
  sesi_id    bigint not null references sesi(id) on delete cascade,
  santri_id  bigint not null references santri(id),
  soal_id    bigint not null references soal(id),
  urutan     int not null,
  unique (sesi_id, santri_id, urutan)
);

-- INTI SISTEM.
create table jawaban (
  id            bigint generated always as identity primary key,
  penilaian_id  bigint not null references penilaian(id) on delete cascade,
  langkah_id    bigint not null references langkah(id),
  verdict       text not null check (verdict in ('benar','dibantu','salah')),
  detik         numeric,             -- lama menjawab; sinyal gratis, boleh null
  catatan       text,
  dibuat_pada   timestamptz not null default now(),
  -- Langkah yang tidak berlaku / dilewati TIDAK punya baris di sini.
  -- Itu sebabnya rata-rata otomatis benar tanpa filter khusus di mana pun.
  unique (penilaian_id, langkah_id)
);

create index on penilaian (santri_id);
create index on penilaian (soal_id);
create index on jawaban   (penilaian_id);
create index on jawaban   (langkah_id);

-- ============================================================
-- 4. Penilaian — SATU-SATUNYA tempat rumus nilai hidup
-- ============================================================

create function public.bobot(v text) returns numeric
  language sql immutable set search_path = '' as
$$ select case v when 'benar' then 1 when 'dibantu' then 0.5 else 0 end $$;

-- Nilai per soal = rata-rata langkah YANG TERCATAT pada soal itu.
create view public.v_nilai_soal with (security_invoker = on) as
  select p.id as penilaian_id, p.sesi_id, p.santri_id, p.soal_id,
         s.tipe, s.tingkat,
         count(j.id)                              as langkah_dijawab,
         round(avg(public.bobot(j.verdict)) * 100, 1) as nilai
  from public.penilaian p
  join public.soal s on s.id = p.soal_id
  left join public.jawaban j on j.penilaian_id = p.id
  group by p.id, s.tipe, s.tingkat;

-- Nilai santri = rata-rata NILAI SOAL, bukan rata-rata seluruh langkah.
-- Urutan ini yang mencegah soal bertangga panjang (ismiyah 9 langkah)
-- otomatis berbobot lebih besar daripada yang pendek (nawasikh 7 langkah).
create view public.v_nilai_santri with (security_invoker = on) as
  select sesi_id, santri_id,
         count(*)               as jml_soal,
         round(avg(nilai), 1)   as nilai
  from public.v_nilai_soal
  where nilai is not null
  group by sesi_id, santri_id;

-- Diagnostik: anak-tangga mana yang lemah, per santri.
create view public.v_kelemahan_langkah with (security_invoker = on) as
  select p.santri_id, l.tipe, l.urutan, l.pertanyaan,
         count(*)                                    as n,
         round(avg(public.bobot(j.verdict)) * 100, 1) as nilai
  from public.jawaban j
  join public.langkah   l on l.id = j.langkah_id
  join public.penilaian p on p.id = j.penilaian_id
  group by p.santri_id, l.tipe, l.urutan, l.pertanyaan;

-- Diagnostik: soal yang menjebak semua orang => rubrik/ibarat yang perlu ditinjau.
create view public.v_soal_sulit with (security_invoker = on) as
  select v.soal_id, s.tipe, s.nomor_bank, s.teks,
         count(*)             as dikerjakan,
         round(avg(v.nilai),1) as nilai
  from public.v_nilai_soal v
  join public.soal s on s.id = v.soal_id
  where v.nilai is not null
  group by v.soal_id, s.tipe, s.nomor_bank, s.teks;

-- Diagnostik: kalibrasi penguji. Masalah keadilan yang tak terlihat di kertas.
create view public.v_kalibrasi_penguji with (security_invoker = on) as
  select se.ustadz_id, u.nama,
         count(*)                                   as jml_dinilai,
         round(avg(v.nilai), 1)                     as rata_penguji,
         round((select avg(nilai) from public.v_nilai_santri), 1) as rata_semua
  from public.v_nilai_santri v
  join public.sesi   se on se.id = v.sesi_id
  join public.ustadz u  on u.id  = se.ustadz_id
  group by se.ustadz_id, u.nama;
  -- ponytail: subquery skalar dijalankan per grup. Tidak masalah utk puluhan
  -- penguji; ganti ke CTE kalau sudah ratusan.

-- ============================================================
-- 5. Identitas & keamanan
-- ============================================================

-- SECURITY DEFINER: wajib, kalau tidak policy pada `ustadz` akan rekursif.
create function public.my_ustadz_id() returns bigint
  language sql stable security definer set search_path = '' as
$$ select id from public.ustadz where auth_id = (select auth.uid()) $$;

create function public.is_ustadz() returns boolean
  language sql stable security definer set search_path = '' as
$$ select public.my_ustadz_id() is not null $$;

-- Klaim identitas sekali seumur hidup, pakai kode yang diberikan lisan.
-- Tanpa ini, siapa pun yang mendaftar bisa membaca data santri (anak di bawah umur).
create function public.klaim_ustadz(p_kode text) returns bigint
  language plpgsql security definer set search_path = '' as
$$
declare v_id bigint;
begin
  if (select auth.uid()) is null then
    raise exception 'Belum login.';
  end if;
  if public.my_ustadz_id() is not null then
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

-- ============================================================
-- 6. RLS — semua tabel tertutup, hanya ustadz terklaim yang masuk
-- ============================================================

alter table kitab       enable row level security;
alter table ibarat      enable row level security;
alter table soal        enable row level security;
alter table langkah     enable row level security;
alter table santri      enable row level security;
alter table ustadz      enable row level security;
alter table ustadz_kode enable row level security;   -- sengaja TANPA policy
alter table sesi        enable row level security;
alter table penilaian   enable row level security;
alter table jawaban     enable row level security;

-- Materi: dibaca semua ustadz. `soal` juga bisa ditambah (lafad hasil ketukan BK1).
create policy baca on kitab   for select to authenticated using (public.is_ustadz());
create policy baca on ibarat  for select to authenticated using (public.is_ustadz());
create policy baca on langkah for select to authenticated using (public.is_ustadz());
create policy baca on soal    for select to authenticated using (public.is_ustadz());
create policy tulis on soal   for insert to authenticated with check (public.is_ustadz());

create policy baca  on santri for select to authenticated using (public.is_ustadz());
create policy tulis on santri for insert to authenticated with check (public.is_ustadz());
create policy ubah  on santri for update to authenticated using (public.is_ustadz());

-- Nama ustadz boleh dibaca (dipakai layar kalibrasi). Kodenya tidak, ada di tabel lain.
create policy baca on ustadz for select to authenticated using (true);

-- Sesi: semua ustadz boleh MELIHAT (kalibrasi butuh itu), hanya pemilik boleh MENGUBAH.
create policy baca  on sesi for select to authenticated using (public.is_ustadz());
create policy tulis on sesi for insert to authenticated with check (ustadz_id = public.my_ustadz_id());
create policy ubah  on sesi for update to authenticated using (ustadz_id = public.my_ustadz_id());
create policy hapus on sesi for delete to authenticated using (ustadz_id = public.my_ustadz_id());

create policy baca  on penilaian for select to authenticated using (public.is_ustadz());
create policy tulis on penilaian for all to authenticated
  using      (exists (select 1 from public.sesi s where s.id = sesi_id and s.ustadz_id = public.my_ustadz_id()))
  with check (exists (select 1 from public.sesi s where s.id = sesi_id and s.ustadz_id = public.my_ustadz_id()));

create policy baca  on jawaban for select to authenticated using (public.is_ustadz());
create policy tulis on jawaban for all to authenticated
  using      (exists (select 1 from public.penilaian p join public.sesi s on s.id = p.sesi_id
                       where p.id = penilaian_id and s.ustadz_id = public.my_ustadz_id()))
  with check (exists (select 1 from public.penilaian p join public.sesi s on s.id = p.sesi_id
                       where p.id = penilaian_id and s.ustadz_id = public.my_ustadz_id()));
