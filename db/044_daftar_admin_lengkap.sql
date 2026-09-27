-- Daftar admin harus bisa disaring DAN diurutkan, jadi harus membawa
-- semua yang akan disaring.
--
-- `ambil_semua_santri` (017) hanya mengembalikan nama, tingkat, auth_id.
-- Itu cukup waktu Kelola User cuma menampilkan daftar -- tidak ada yang perlu
-- disaring. Sekarang layar itu menyaring per semester, per kelas sorogan, dan
-- per status akun, dan tiga hal itu tidak ada di sana.
--
-- Yang ditambahkan: `semester`, `kelas_sorogan` (AKTIF saja), `kelas_id`, dan
-- `kode`. Syarat `sampai is null` itu yang membedakan "sekarang" dari
-- "pernah" -- tanpa itu, riwayat ikut terbaca dan anak muncul di dua kelas
-- sekaligus.
--
-- `kode` ikut karena itu penanda yang stabil: dua "Fahmi" tidak bisa
-- dibedakan dari namanya.
--
-- Untuk `ustadz` tidak ada yang perlu ditambah: tidak ada semester, dan
-- "kelompok" bukan miliknya (008: penugasan mentor->kelompok sengaja tidak
-- disimpan karena berputar). Yang relevan cuma `kode`.

create or replace function public.ambil_semua_santri() returns json
  language plpgsql security definer set search_path = '' as
$$
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa mengakses.';
  end if;
  return (
    select json_agg(json_build_object(
      'id', t.id,
      'kode', t.kode,
      'nama', t.nama,
      'tingkat', t.tingkat,
      'semester', t.semester,
      'auth_id', t.auth_id,
      'aktif', t.aktif,
      'kelas_sorogan', t.kelas_sorogan,
      'kelas_id', t.kelas_id
    ) order by t.nama)
    from (
      select
        s.id, s.kode, s.nama, s.tingkat, s.semester, s.auth_id, s.aktif,
        (select k.nama from public.kelompok_santri ks
           join public.kelompok k on k.id = ks.kelompok_id
          where ks.Santri_id = s.id and ks.sampai is null
            and k.jenis = 'sorogan' limit 1) as kelas_sorogan,
        (select ks.kelompok_id from public.kelompok_santri ks
           join public.kelompok k on k.id = ks.kelompok_id
          where ks.Santri_id = s.id and ks.sampai is null
            and k.jenis = 'sorogan' limit 1) as kelas_id
      from public.santri s
    ) t
  );
end
$$;

revoke execute on function public.ambil_semua_santri() from public;
revoke execute on function public.ambil_semua_santri() from anon;
grant execute on function public.ambil_semua_santri() to authenticated;