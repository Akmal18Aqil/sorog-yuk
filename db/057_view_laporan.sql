-- 057: v_laporan_sorogan — nilai terakhir + absen + kendala terakhir per santri.
--
-- Nilai terakhir = rata-rata v_nilai_soal mode='harian' (bukan rata semua sesi:
-- sesi ujian dan sesi harian beda guna; laporan wali = harian).
-- Urut default: semester -> urutan BK -> nama. Filter dikerjakan client
-- (semester x BK x periode) di atas view ini.

create or replace view public.v_laporan_sorogan with (security_invoker = on) as
select
  s.id as santri_id, s.kode, s.nama, s.semester, s.tingkat as bk,
  k.urutan as bk_urutan,
  kg.id as kelompok_id, kg.nama as kelompok_nama,
  nl.nilai as nilai_terakhir, nl.tanggal as tanggal_nilai,
  hd.status as status_terakhir, hd.kendala as kendala_terakhir,
  hd.tanggal as tanggal_hadir, u.nama as dicatat_oleh
from public.santri s
left join public.kelas k on k.kode = s.tingkat
left join public.kelompok_santri ks
  on ks.santri_id = s.id and ks.sampai is null
left join public.kelompok kg on kg.id = ks.kelompok_id
left join lateral (
  select round(avg(v.nilai), 1) as nilai, max(se.tanggal) as tanggal
  from public.v_nilai_soal v
  join public.sesi se on se.id = v.sesi_id
  where v.santri_id = s.id and se.mode = 'harian' and v.nilai is not null
) nl on true
left join lateral (
  select h.status, h.kendala, h.tanggal, h.ustadz_id
  from public.kehadiran h
  where h.santri_id = s.id
  order by h.tanggal desc, h.id desc
  limit 1
) hd on true
left join public.ustadz u on u.id = hd.ustadz_id;
