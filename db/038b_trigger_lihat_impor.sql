-- Trigger penjaga kolom harus bisa membedakan "santri/ustadz mencoba ganti
-- identitas" dari "impor master data".
--
-- 038a sempat mencoba solve ini dengan membuat RPC bypass, dan itu SALAH:
-- SECURITY DEFINER tidak melewati trigger, dan trigger tetap menolak.
-- Menembus guard lewat jalur lain bukan memperbaiki guard.
--
-- Perbaikannya di trigger sendiri: satu flag sesi yang hanya bisa diset oleh
-- pemanggil yang sudah memeriksa superadmin. Trigger mengabaikannya.
--
-- Flag memakai set_config(..., true) = LOKAL TRANSAKSI. Bukan local-sesi,
-- bukan global: kalau global, sesi berikutnya ikut mewarisi izin dan
-- penjaganya mati tanpa suara. Lokal transaksi berarti izin itu mati
-- sendiri begitu transaksi selesai.

create or replace function priv.tegak_ubah_santri() returns trigger
  language plpgsql security definer set search_path = '' as
$$
begin
  -- Impor master data: diizinkan. Flag ini hanya bisa diset oleh
  -- SECURITY DEFINER yang memeriksa superadmin lebih dulu.
  if current_setting('sorogan.impor', true) = '1' then
    return new;
  end if;

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

revoke execute on function priv.tegak_ubah_santri() from public;