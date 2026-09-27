-- Sorogan Digital — izinkan ustadz menaikkan kelas santri
--
-- `santri` punya policy UPDATE untuk superadmin (ubah_admin) dan untuk diri
-- sendiri (ubah_santri), tapi TIDAK untuk ustadz. Padahal
-- putuskan_kenaikan() -- SECURITY INVOKER, jadi RLS satu-satunya penjaga --
-- menjalankan `update public.santri set tingkat = ...` (013:119).
--
-- Akibatnya: baris `kenaikan` TERCATAT "disetujui", tapi tingkat
-- tidak pernah berubah. UPDATE yang tidak cocok dengan policy hanya
-- diam-diam memengaruhi 0 baris -- tidak ada error yang menyadarinya.
-- Keputusan yang sudah tercatat bertentangan dengan kenyataan, dan itu
-- persis kelas kesalahan yang paling sulit ditinjau belakangan.
--
-- Batasnya sengaja sempit: ustadz boleh mengubah `tingkat` (memindahkan anak
-- naik kelas) dan tidak boleh menyentuh nama, auth_id, atau aktif.

create policy ubah_tingkat_ustadz on santri for update to authenticated
  using (priv.is_ustadz()) with check (priv.is_ustadz());

-- Penjaga kolom. RLS tidak bisa membatasi kolom mana yang boleh berubah, jadi
-- sisanya dikunci di sini. SECURITY DEFINER supaya policymakers check-nya
-- tidak ikut dievaluasi RLS dan berubah jadi rekursif.
create or replace function priv.tegak_ubah_santri() returns trigger
  language plpgsql security definer set search_path = '' as
$$
begin
  if priv.is_superadmin() then
    return new;
  end if;
  if row(new.nama, new.auth_id, new.aktif)
     is distinct from row(old.nama, old.auth_id, old.aktif) then
    raise exception 'Ustadz hanya boleh mengubah kelas santri.';
  end if;
  return new;
end
$$;

create trigger tegak_ubah_santri
  before update on public.santri
  for each row execute function priv.tegak_ubah_santri();

revoke execute on function priv.tegak_ubah_santri() from public;