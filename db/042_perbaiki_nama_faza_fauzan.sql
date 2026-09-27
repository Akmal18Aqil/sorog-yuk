-- Koreksi nama yang salah ketik saat import 039.
--
-- `M. Faza Fauzan Adhima` saya ketik ulang manual jadi `Fawzan` saat
-- menyalin 124 baris ke SQL. File absensi menuliskan `Fauzan`.
--
-- Ini kesalahan proses, bukan keputusan. Nama orang harus disalin dari file,
-- bukan diketik ulang -- dan daftar 124 baris terlalu panjang untuk
-- diperiksa mata. Yang membuat celah ini lolos: jumlah barisnya tetap sama
-- persis (102 = 102), jadi tidak ada yang hilang atau dobel. Hanya ejaan
-- satu nama yang bergeser, dan itu baru ketahuan waktu nama di database
-- dibandingkan dengan isi file satu per satu.
--
-- Semester TIDAK ikut disentuh: hanya ejaan nama yang salah.

select set_config('sorogan.impor', '1', true);

update public.santri
   set nama = 'M. Faza Fauzan Adhima'
 where nama = 'M. Faza Fawzan Adhima'
   and semester = 5;