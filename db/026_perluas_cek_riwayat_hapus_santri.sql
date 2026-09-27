-- Melengkapi cek riwayat di hapus_santri.
--
-- Cek pertama hanya melihat penilaian lewat sesi. Tapi `kenaikan` dan
-- `tes_offline` punya FK ke `santri` dengan ON DELETE CASCADE (013:6 dan
-- 013:22) -- artinya tanpa cek tambahan, hapus seorang santri yang sudah
-- naik kelas akan MENGHAPUS SEJARAH KENAIKANNYA diam-diam. Itu persis
-- kebalikan dari D1 ("nonaktifkan, jangan hapus -- riwayatnya masih dipakai").
--
-- Riwayat = ada baris di salah satu dari tiga tabel ini.

create or replace function public.hapus_santri(p_id bigint) returns void
  language plpgsql security definer set search_path = '' as
$$
declare v_nama text;
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa menghapus santri.';
  end if;
  select nama into v_nama from public.santri where id = p_id;
  if v_nama is null then
    raise exception 'Santri tidak ditemukan.';
  end if;
  if exists (select 1 from public.penilaian   where Santri_id = p_id)
     or exists (select 1 from public.kenaikan    where Santri_id = p_id)
     or exists (select 1 from public.tes_offline where Santri_id = p_id) then
    raise exception
      '% sudah punya riwayat. Nonaktifkan, jangan hapus -- riwayatnya masih dipakai.', v_nama;
  end if;
  delete from public.santri where id = p_id;
end
$$;

revoke execute on function public.hapus_santri(bigint) from public;
