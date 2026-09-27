-- Kenaikan kelas menuntut DUA tes. Yang daring dikerjakan aplikasi ini
-- (sesi mode='ujian'); yang luring dikerjakan tatap muka dan nilainya dicatat
-- ke sini. Tanpa keduanya, kesiapan tidak bisa dihitung.
create table tes_offline (
  id           bigint generated always as identity primary key,
  santri_id    bigint not null references santri(id) on delete cascade,
  -- Kelas yang sedang diuji. Nilai ujian luring untuk materi Kelas 1 tidak
  -- boleh ikut menghitung kenaikan dari Kelas 2.
  kelas_kode   text not null references kelas(kode) on update cascade,
  tanggal      date not null default current_date,
  nilai        numeric not null check (nilai between 0 and 100),
  dicatat_oleh bigint not null references ustadz(id),
  catatan      text,
  dibuat_pada  timestamptz not null default now()
);
create index on tes_offline (santri_id);
-- Tes ulang dibiarkan menumpuk sebagai baris baru; yang dipakai adalah
-- yang TERBARU. Menimpa nilai lama akan menghapus jejak perbaikan santri.

create table kenaikan (
  id              bigint generated always as identity primary key,
  santri_id       bigint not null references santri(id) on delete cascade,
  dari_kelas      text not null references kelas(kode) on update cascade,
  ke_kelas        text not null references kelas(kode) on update cascade,
  -- Potret nilai SAAT keputusan diambil. Tes ulang sesudahnya tidak boleh
  -- mengubah dasar keputusan yang sudah terjadi.
  nilai_online    numeric,
  nilai_offline   numeric,
  memenuhi_ambang boolean not null,
  disetujui       boolean not null,
  catatan         text,
  diputuskan_oleh bigint not null references ustadz(id),
  diputuskan_pada timestamptz not null default now()
);
create index on kenaikan (santri_id);

-- ============================================================
-- Kesiapan naik kelas. Sistem MENGUSULKAN; asatidz memutuskan.
-- ============================================================
create view public.v_kesiapan_naik with (security_invoker = on) as
with per_sesi as (
  -- Nilai satu santri pada satu sesi ujian, dipisah per tingkat materi.
  select v.santri_id, v.tingkat, v.sesi_id, se.tanggal, round(avg(v.nilai), 1) as nilai
  from public.v_nilai_soal v
  join public.sesi se on se.id = v.sesi_id
  where se.mode = 'ujian' and v.nilai is not null
  group by v.santri_id, v.tingkat, v.sesi_id, se.tanggal
),
daring as (
  select distinct on (santri_id, tingkat) santri_id, tingkat, nilai, tanggal
  from per_sesi
  order by santri_id, tingkat, tanggal desc, sesi_id desc
),
luring as (
  select distinct on (santri_id, kelas_kode) santri_id, kelas_kode, nilai, tanggal
  from public.tes_offline
  order by santri_id, kelas_kode, tanggal desc, id desc
)
select s.id as santri_id, s.nama,
       s.tingkat as kelas_kode, k.nama as kelas_nama,
       kb.kode as kelas_berikut, kb.nama as kelas_berikut_nama,
       d.nilai as nilai_online,  d.tanggal as tanggal_online,
       l.nilai as nilai_offline, l.tanggal as tanggal_offline,
       k.ambang_online, k.ambang_offline,
       coalesce(d.nilai >= k.ambang_online,  false) as lolos_online,
       coalesce(l.nilai >= k.ambang_offline, false) as lolos_offline,
       (kb.kode is not null
        and coalesce(d.nilai >= k.ambang_online,  false)
        and coalesce(l.nilai >= k.ambang_offline, false)) as siap
from public.santri s
join public.kelas k on k.kode = s.tingkat
left join public.kelas kb on kb.urutan = k.urutan + 1
-- Nilai HARUS dari materi kelas yang sedang dijalani, bukan kelas mana pun.
left join daring d on d.santri_id = s.id and d.tingkat    = s.tingkat
left join luring l on l.santri_id = s.id and l.kelas_kode = s.tingkat;

-- ============================================================
-- Keputusan kenaikan. Satu panggilan = satu keputusan tercatat.
-- ============================================================
create function public.putuskan_kenaikan(
  p_santri_id bigint,
  p_setuju    boolean,
  p_catatan   text default null
) returns bigint
language plpgsql security invoker set search_path = '' as
$$
declare v_ust bigint; r record; v_id bigint; v_catatan text;
begin
  v_ust := priv.my_ustadz_id();
  if v_ust is null then
    raise exception 'Akun belum terhubung ke ustadz mana pun.';
  end if;

  select * into r from public.v_kesiapan_naik where santri_id = p_santri_id;
  if not found then
    raise exception 'Santri tidak ditemukan.';
  end if;
  if r.kelas_berikut is null then
    raise exception '% sudah berada di kelas tertinggi.', r.nama;
  end if;

  v_catatan := nullif(btrim(coalesce(p_catatan, '')), '');

  -- Kebijaksanaan asatidz boleh melampaui ambang — memang ada santri yang
  -- pantas naik walau angkanya kurang. Tapi alasannya wajib tercatat:
  -- keputusan di luar aturan tanpa keterangan tidak bisa ditinjau ulang,
  -- dan justru itu yang paling perlu bisa ditinjau.
  if p_setuju and not r.siap and v_catatan is null then
    raise exception 'Menaikkan di luar ambang harus disertai catatan alasan.';
  end if;

  insert into public.kenaikan (santri_id, dari_kelas, ke_kelas, nilai_online, nilai_offline,
                               memenuhi_ambang, disetujui, catatan, diputuskan_oleh)
       values (p_santri_id, r.kelas_kode, r.kelas_berikut, r.nilai_online, r.nilai_offline,
               r.siap, p_setuju, v_catatan, v_ust)
    returning id into v_id;

  if p_setuju then
    update public.santri set tingkat = r.kelas_berikut where id = p_santri_id;
  end if;
  return v_id;
end
$$;

revoke all on function public.putuskan_kenaikan(bigint, boolean, text) from public, anon;
grant execute on function public.putuskan_kenaikan(bigint, boolean, text) to authenticated;

-- ============================================================
-- RLS
-- ============================================================
alter table tes_offline enable row level security;
alter table kenaikan    enable row level security;

create policy baca  on tes_offline for select to authenticated using (priv.is_ustadz());
create policy tulis on tes_offline for insert to authenticated
  with check (dicatat_oleh = priv.my_ustadz_id());

create policy baca  on kenaikan for select to authenticated using (priv.is_ustadz());
create policy tulis on kenaikan for insert to authenticated
  with check (diputuskan_oleh = priv.my_ustadz_id());
