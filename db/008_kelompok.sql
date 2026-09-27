-- Satu ustadz memegang satu KELOMPOK, dan kelompoknya berganti-ganti.
--
-- Penugasan ustadz->kelompok sengaja TIDAK disimpan. Justru karena berputar:
-- kolom "penanggung jawab" akan basi terus dan menuntut admin merawatnya.
-- Ustadz memilih kelompok saat memulai sesi; `sesi.kelompok_id` merekamnya.
-- Riwayat siapa memegang apa tetap terbaca penuh dari tabel sesi.
create table kelompok (
  id     bigint generated always as identity primary key,
  nama   text not null unique,
  urutan int
);

create table kelompok_santri (
  kelompok_id bigint not null references kelompok(id) on delete cascade,
  santri_id   bigint not null references santri(id) on delete cascade,
  primary key (kelompok_id, santri_id)
);
-- Satu santri hanya di satu kelompok pada satu waktu.
create unique index kelompok_santri_satu on kelompok_santri (santri_id);
create index on kelompok_santri (kelompok_id);

alter table sesi add column kelompok_id bigint references kelompok(id);

-- Seorang ustadz bisa menguji dua kelompok di hari yang sama.
-- NULLS NOT DISTINCT: sesi tanpa kelompok (sorogan harian lepas) tetap
-- dianggap kembar, jadi tidak menumpuk sesi baru tiap kali disimpan.
alter table sesi drop constraint sesi_unik;
alter table sesi add constraint sesi_unik
  unique nulls not distinct (ustadz_id, tanggal, mode, kelompok_id);

alter table kelompok        enable row level security;
alter table kelompok_santri enable row level security;
create policy baca on kelompok        for select to authenticated using (priv.is_ustadz());
create policy baca on kelompok_santri for select to authenticated using (priv.is_ustadz());

-- ============================================================
-- Kalibrasi penguji, diperbaiki untuk model kelompok.
--
-- Versi lama membandingkan rata-rata tiap penguji dengan rata-rata kelas.
-- Itu sah hanya kalau tiap penguji menilai santri yang sebanding. Begitu satu
-- ustadz memegang satu kelompok tetap, selisihnya bisa murni karena SIAPA yang
-- ia dapat — bukan BAGAIMANA ia menilai. Angkanya terlihat meyakinkan dan
-- menuduh orang yang salah. Lihat db/010_check_kalibrasi.sql.
--
-- Perbandingan yang sah adalah BERPASANGAN: nilai seorang penguji atas santri
-- tertentu, dibanding nilai penguji LAIN atas santri yang sama. Rotasi
-- kelompoklah yang menciptakan irisan itu. Selama belum ada irisan,
-- `selisih_terkalibrasi` bernilai null — jujur bahwa belum bisa dibandingkan.
-- ============================================================
drop view if exists v_kalibrasi_penguji;

create view public.v_kalibrasi_penguji with (security_invoker = on) as
with per_penguji as (
  select se.ustadz_id, v.santri_id, avg(v.nilai) as nilai
  from public.v_nilai_soal v
  join public.sesi se on se.id = v.sesi_id
  where v.nilai is not null
  group by se.ustadz_id, v.santri_id
),
berpasangan as (
  select p.ustadz_id, p.santri_id, p.nilai,
         (select avg(q.nilai) from per_penguji q
           where q.santri_id = p.santri_id and q.ustadz_id <> p.ustadz_id) as nilai_penguji_lain
  from per_penguji p
)
select u.id as ustadz_id, u.nama,
       count(*)                                      as jml_santri,
       round(avg(b.nilai), 1)                        as rata_penguji,
       count(b.nilai_penguji_lain)                   as jml_pembanding,
       round(avg(b.nilai - b.nilai_penguji_lain), 1) as selisih_terkalibrasi
from berpasangan b
join public.ustadz u on u.id = b.ustadz_id
group by u.id, u.nama;

-- ============================================================
-- RPC ikut membawa kelompok.
-- ============================================================
create or replace function public.simpan_penilaian(
  p_tanggal     date,
  p_mode        text,
  p_santri_id   bigint,
  p_urutan      int,
  p_jawaban     jsonb,
  p_soal_id     bigint default null,
  p_ibarat_id   bigint default null,
  p_lafad       text   default null,
  p_kelompok_id bigint default null
) returns bigint
language plpgsql security invoker set search_path = '' as
$$
declare v_ust bigint; v_sesi bigint; v_soal bigint; v_pen bigint;
begin
  -- plpgsql meresolusi nama saat DIJALANKAN: acuan wajib berkualifikasi penuh
  -- dan benar, karena migrasi yang sukses tidak membuktikan apa pun di sini.
  v_ust := priv.my_ustadz_id();
  if v_ust is null then
    raise exception 'Akun belum terhubung ke ustadz mana pun.';
  end if;

  insert into public.sesi (tanggal, ustadz_id, mode, kelompok_id)
       values (p_tanggal, v_ust, p_mode, p_kelompok_id)
  on conflict (ustadz_id, tanggal, mode, kelompok_id) do update set mode = excluded.mode
    returning id into v_sesi;

  v_soal := p_soal_id;
  if v_soal is null then
    if p_ibarat_id is null or btrim(coalesce(p_lafad, '')) = '' then
      raise exception 'Soal tidak lengkap: butuh soal_id, atau ibarat_id + lafad.';
    end if;
    insert into public.soal (ibarat_id, teks, tipe, tingkat)
         values (p_ibarat_id, btrim(p_lafad), 'lafad', 'BK1')
    on conflict (ibarat_id, teks, tipe) do nothing;
    select id into v_soal from public.soal
     where ibarat_id = p_ibarat_id and teks = btrim(p_lafad) and tipe = 'lafad';
  end if;

  insert into public.penilaian (sesi_id, santri_id, soal_id, urutan)
       values (v_sesi, p_santri_id, v_soal, p_urutan)
  on conflict (sesi_id, santri_id, urutan) do update set soal_id = excluded.soal_id
    returning id into v_pen;

  delete from public.jawaban where penilaian_id = v_pen;
  insert into public.jawaban (penilaian_id, langkah_id, verdict, detik)
  select v_pen, (j->>'langkah_id')::bigint, j->>'verdict', (j->>'detik')::numeric
    from jsonb_array_elements(p_jawaban) j;

  return v_pen;
end
$$;

-- Tanda tangan lama (8 argumen) dibuang supaya tidak ada dua versi hidup
-- berdampingan dan klien lama diam-diam menyimpan sesi tanpa kelompok.
drop function if exists public.simpan_penilaian(date, text, bigint, int, jsonb, bigint, bigint, text);

revoke all on function public.simpan_penilaian(date, text, bigint, int, jsonb, bigint, bigint, text, bigint) from public, anon;
grant execute on function public.simpan_penilaian(date, text, bigint, int, jsonb, bigint, bigint, text, bigint) to authenticated;
