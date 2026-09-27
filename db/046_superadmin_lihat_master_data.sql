-- Superadmin tidak bisa membaca kelas, kelompok, dan kelompok_santri.
--
-- Gejalanya tidak konsisten: dashboard menampilkan "2 kelas" (lewat RPC
-- `ambil_statistik`, SECURITY DEFINER yang melewati RLS) sementara halaman
-- /admin/kelas kosong (lewat select biasa yang tertahan policy). Dua angka
-- dari dua sumber berbeda, dan hanya satu yang benar.
--
-- Akar masalahnya di 012:37 dan 023: `using (priv.is_ustadz())`.
-- `priv.is_ustadz()` = `priv.my_role() = 'ustadz'` (017:62) -- bernilai TRUE
-- hanya untuk role='ustadz'. Superadmin punya role='superadmin', jadi nilainya
-- FALSE dan ia melihat nol baris.
--
-- Itu terbalik: superadmin adalah orang yang MENGELOLA master data ini. Tidak
-- bisa membacanya berarti tidak bisa mengelolanya.
--
-- Tulis/ubah/hapus TIDAK disentuh: tetap superadmin saja.
--
-- Pola yang sama sudah dipasang di 017 untuk `santri` (`baca_admin`), dan di
-- situ tidak ada bug. Yang bermasalah hanya tabel yang policy bacanya satu.


drop policy baca on public.kelas;
create policy baca on kelas for select to authenticated
  using (priv.is_ustadz() or priv.is_superadmin());

drop policy baca on public.kelompok;
create policy baca on kelompok for select to authenticated
  using (priv.is_ustadz() or priv.is_superadmin());

drop policy baca on public.kelompok_santri;
create policy baca on kelompok_santri for select to authenticated
  using (priv.is_ustadz() or priv.is_superadmin());
