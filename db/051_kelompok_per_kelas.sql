-- Kelompok per kelas: "Kelompok 1" boleh ada di BK1 DAN di BK2.
--
-- 048 sudah menambahkan `kelompok.tingkat` (kelas yang dilayani), tapi UNIQUE
-- dari 008 masih `UNIQUE (nama)` -- satu kolom saja. Akibatnya "Kelompok 1"
-- untuk BK2 DITOLAK:
--
--   duplicate key value violates unique constraint "kelompok_nama_key"
--
-- Padahal nama kelompok memang berulang antar kelas: tiap kelas punya
-- kelompok 1, 2, 3 sendiri. Yang harus unik adalah pasangan (kelas, nama),
-- bukan namanya sendiri.
--
-- `nulls not distinct` (PG15+) ikut menjaga baris yang kelasnya belum diatur.
-- NULL itu keadaan yang SAH (048:28 -- kelompok terjemah tidak punya tingkat
-- baca kitab), tapi dua kelompok bernama sama yang dua-duanya tanpa kelas
-- tetap dua baris yang membingungkan, jadi itu ikut ditolak.
--
-- Indeks dari UNIQUE ini sekaligus melayani saringan "kelompok milik kelas X"
-- di halaman /mulai, jadi indeks `kelompok_tingkat_cari` (048:37) yang hanya
-- berisi `tingkat` jadi mubazir -- prefix-nya sudah tercakup.

alter table public.kelompok drop constraint if exists kelompok_nama_key;

alter table public.kelompok drop constraint if exists kelompok_tingkat_nama_key;
alter table public.kelompok add  constraint kelompok_tingkat_nama_key
  unique nulls not distinct (tingkat, nama);

drop index if exists public.kelompok_tingkat_cari;
