-- Fitur: cari mahasantri + pindah kelas
--
-- ============================================================
-- 1. PENCARIAN
-- ============================================================
-- Semua yang dibutuhkan untuk menjawab "nama ini semester berapa, kelas
-- sorogannya apa, kelas terjemahnya apa" dalam SATU query.
--
-- Mengembalikan JSON, bukan tabel baru: ini output layar pencarian, bukan
-- data yang perlu hidup sendiri.
--
-- SECURITY DEFINER dengansayuran khusus: daftar ini HARUS memuat alumni
-- yang `aktif = false`. Policy `baca_ustadz` (027) sengaja menyembunyikan
-- nonaktif dari halaman penilaian -- benar di sana, salah di sini. Tanpa
-- ini, orang yang justru paling perlu dicari (alumni) tidak akan pernah
-- muncul. Batasan kedua: hanya superadmin, sebab hasilnya melintasi semua
-- semester.

create or replace function public.cari_mahasantri(
  p_cari text default null,
  p_kode bigint default null
) returns json
  language plpgsql security definer set search_path = '' as
$$
declare v_cari text := lower(nullif(btrim(coalesce(p_cari, '')), ''));
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa mencari mahasantri.';
  end if;

  return (
    select coalesce(json_agg(row_to_json(t) order by t.nama), '[]'::json)
    from (
      select
        s.id, s.kode, s.nama, s.semester, s.tahun_masuk, s.tingkat, s.aktif,
        -- Kelas AKTIF per jenis. Syarat `sampai is null` adalah yang
        -- membedakan "sekarang" dari "pernah" -- tanpa itu, riwayat ikut
        -- terbaca sebagai kelas kini.
        (select k.nama from public.kelompok_santri ks
           join public.kelompok k on k.id = ks.kelompok_id
          where ks.santri_id = s.id and ks.sampai is null and k.jenis = 'sorogan')  as kelas_sorogan,
        (select k.periode from public.kelompok_santri ks
           join public.kelompok k on k.id = ks.kelompok_id
          where ks.santri_id = s.id and ks.sampai is null and k.jenis = 'sorogan')  as periode_sorogan,
        (select k.nama from public.kelompok_santri ks
           join public.kelompok k on k.id = ks.kelompok_id
          where ks.santri_id = s.id and ks.sampai is null and k.jenis = 'terjemah') as kelas_terjemah,
        -- Riwayat kelas, terbaru lebih dulu. Ini yang tidak bisa dijawab
        -- tanpa 033: sebelumnya pindah menghapus baris lamanya.
        coalesce((
          select json_agg(json_build_object(
            'kelompok', k.nama, 'jenis', k.jenis,
            'periode', k.periode, 'dari', ks.dari, 'sampai', ks.sampai
          ) order by ks.dari desc)
          from public.kelompok_santri ks
          join public.kelompok k on k.id = ks.kelompok_id
          where ks.santri_id = s.id
        ), '[]'::json) as riwayat_kelas
      from public.santri s
      where (p_kode is null or s.id = p_kode)
        and (
          v_cari is null
          -- Awal nama didahulukan daripada contains: orang mencari dari
          -- awal nama, dan hasil contains yang memunculkan "Muhammad" di
          -- posisi tengah cuma menambah noise.
          or lower(s.nama) like v_cari || '%'
          or lower(s.nama) like '% ' || v_cari || '%'
          or lower(s.kode) like v_cari || '%'
        )
      limit 50
    ) t
  );
end
$$;
