-- Sorogan Digital — pulihkan policy baca yang hilang
--
-- `kelas`, `kelompok`, `kelompok_santri` RLS aktif tapi TIDAK punya policy
-- SELECT sama sekali (hanya tulis/ubah/hapus_admin dari 018). Tabel dengan
-- RLS tanpa policy SELECT berarti "gagal-tertutup": setiap SELECT mengembalikan
-- nol baris.
--
-- Akibatnya v_kesiapan_naik (013:71-72) tidak pernah melihat satu baris
-- `kelas` -> `putuskan_kenaikan` selalu melempar 'Santri tidak ditemukan',
-- dan app/utils/repo.ts:98-99 (ambilAcuan) mengembalikan kelompok kosong.
--
-- Definisi disalin apa adanya dari 012:37 dan 008:33-34.

create policy baca on kelas for select to authenticated using (priv.is_ustadz());
create policy baca on kelompok for select to authenticated using (priv.is_ustadz());
create policy baca on kelompok_santri for select to authenticated using (priv.is_ustadz());