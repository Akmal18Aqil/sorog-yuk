-- Lanjutan 046: tiga tabel lagi dengan policy `baca` yang hanya
-- mengizinkan `priv.is_ustadz()`, sehingga superadmin melihat nol baris.
--
-- Ditemukan dengan query yang sama: tabel yang punya policy `baca*` tapi TIDAK
-- punya `baca_admin` terpisah. `kitab` dan `langkah` aman karena `baca=true`
-- (semua user login), jadi tidak masuk daftar.
--
-- `kenaikan` dan `tes_offline` dipakai halaman /kenaikan. Superadmin tidak
-- punya halaman itu (auth.ts:44 mengarahkan superadmin ke /admin), jadi ini
-- bukan memperbaiki tampilan -- ini menutup lubang yang sama supaya tabel yang
-- tidak lagi dibaca tidak menyimpan keadaan rusak.
--
-- `ibarat` dipakai halaman /admin/ibarat/[kitabId] yang memang milik
-- superadmin, jadi perbaikan ini yang membuatnya benar.


drop policy baca on public.kenaikan;
create policy baca on kenaikan for select to authenticated
  using (priv.is_ustadz() or priv.is_superadmin());

drop policy baca on public.tes_offline;
create policy baca on tes_offline for select to authenticated
  using (priv.is_ustadz() or priv.is_superadmin());

drop policy baca on public.ibarat;
create policy baca on ibarat for select to authenticated
  using (priv.is_ustadz() or priv.is_superadmin());
