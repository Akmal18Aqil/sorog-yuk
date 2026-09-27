-- 036b: geser PK ke id.
--
-- PK lama (kelompok_id, santri_id) menyatakan: satu pasangan
-- Santri-kelompok hanya boleh ada SELAMANYA. Itu benar saat keanggotaan
-- tidak punya waktu -- tapi setelah 033 menambah dari/sampai, maknanya
-- berubah: riwayat menuntut pasangan yang sama BOLEH muncul lagi setelah
-- yang lama ditutup.
--
-- Buktinya nyata, bukan teori: "pindah ke Kelompok 1, pindah ke 2, kembali
-- ke 1" gagal dengan 23505 pada insert kedua ke Kelompok 1. PK menjadi
-- penghalang untuk persis hal yang harus bisa dicatat.
--
-- Yang DIGANTI: PK. Yang DIPERTAHANKAN: satu membership AKTIF per
-- (kelompok, Santri) lewat UNIQUE parsial di 036c. Aturan satu-aktif per
-- Santri (033) juga tetap berlaku dan tidak dilonggarkan.

alter table public.kelompok_santri drop constraint if exists kelompok_santri_pkey;
alter table public.kelompok_santri add constraint kelompok_santri_pkey primary key (id);
