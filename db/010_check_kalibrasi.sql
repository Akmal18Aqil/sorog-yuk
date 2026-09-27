-- Check kalibrasi penguji di bawah model kelompok.
--
-- Kenapa ada: begitu satu ustadz memegang satu kelompok, membandingkan
-- rata-rata antar penguji jadi RANCU — selisihnya bisa murni karena siapa yang
-- ia dapat, bukan bagaimana ia menilai. Angkanya tetap terlihat meyakinkan,
-- dan menuduh orang yang salah.
--
-- Skenario di bawah dirancang supaya kedua metrik menunjuk ORANG YANG BERBEDA:
--
--   Ustadz A longgar, tapi kelompoknya lemah   -> rata polos 56.7
--   Ustadz B ketat,   tapi kelompoknya kuat    -> rata polos 70.0
--   Rata polos menuduh B longgar. Itu KELIRU.
--
--   Rotasi membuat A ikut menguji santri milik kelompok B. Pada santri yang
--   SAMA: A memberi 90, B memberi 40. Perbandingan berpasangan mengembalikan
--   A=+50, B=-50 — A-lah yang longgar.
--
-- Assert terakhir memagari pembalikan tanda itu, bukan sekadar angkanya:
-- kalau suatu saat kedua metrik menunjuk orang yang sama, fixture ini sudah
-- tumpul dan harus dirancang ulang.
--
-- Aman diulang: seluruhnya dibatalkan lewat exception 'KALIBRASI_OK_ROLLBACK'.

do $$
declare
  uA bigint; uB bigint; k1 bigint; k2 bigint;
  s1 bigint; s2 bigint; s3 bigint; s4 bigint; soal bigint;
  sesiA bigint; sesiA2 bigint; sesiB bigint;
  rataA numeric; rataB numeric; kalA numeric; kalB numeric; n_sesi int;
begin
  select id into uA from ustadz order by id limit 1;
  select id into uB from ustadz order by id offset 1 limit 1;
  select id into k1 from kelompok where nama = 'Kelompok 1';
  select id into k2 from kelompok where nama = 'Kelompok 2';
  select id into soal from soal where nomor_bank = 31;
  select santri_id into s1 from kelompok_santri where kelompok_id = k1 order by santri_id limit 1;
  select santri_id into s2 from kelompok_santri where kelompok_id = k1 order by santri_id offset 1 limit 1;
  select santri_id into s3 from kelompok_santri where kelompok_id = k2 order by santri_id limit 1;
  select santri_id into s4 from kelompok_santri where kelompok_id = k2 order by santri_id offset 1 limit 1;

  insert into sesi (tanggal, ustadz_id, mode, kelompok_id) values (current_date, uA, 'ujian', k1) returning id into sesiA;
  insert into sesi (tanggal, ustadz_id, mode, kelompok_id) values (current_date, uA, 'ujian', k2) returning id into sesiA2;
  insert into sesi (tanggal, ustadz_id, mode, kelompok_id) values (current_date, uB, 'ujian', k2) returning id into sesiB;
  select count(*) into n_sesi from sesi where tanggal = current_date and ustadz_id = uA;

  create temp table pola(sesi bigint, santri bigint, v text[]) on commit drop;
  insert into pola values
    (sesiA,  s1, array['benar','benar','salah','salah','salah']),     -- 40
    (sesiA,  s2, array['benar','benar','salah','salah','salah']),     -- 40
    (sesiA2, s3, array['benar','benar','benar','benar','dibantu']),   -- 90  <- rotasi
    (sesiB,  s3, array['benar','benar','salah','salah','salah']),     -- 40
    (sesiB,  s4, array['benar','benar','benar','benar','benar']);     -- 100

  insert into penilaian (sesi_id, santri_id, soal_id, urutan)
  select sesi, santri, soal, 1 from pola;

  insert into jawaban (penilaian_id, langkah_id, verdict)
  select p.id, l.id, x.v[l.urutan]
  from pola x
  join penilaian p on p.sesi_id = x.sesi and p.santri_id = x.santri and p.urutan = 1
  join langkah l on l.tipe = 'nawasikh' and l.urutan <= 5;

  select rata_penguji, selisih_terkalibrasi into rataA, kalA from v_kalibrasi_penguji where ustadz_id = uA;
  select rata_penguji, selisih_terkalibrasi into rataB, kalB from v_kalibrasi_penguji where ustadz_id = uB;

  assert n_sesi = 2, format('ustadz harus bisa memegang 2 kelompok sehari, dapat %s sesi', n_sesi);
  assert rataA = 56.7, format('rata polos A harus 56.7, dapat %s', rataA);
  assert rataB = 70.0, format('rata polos B harus 70.0, dapat %s', rataB);
  assert kalA = 50.0,  format('terkalibrasi A harus +50.0, dapat %s', kalA);
  assert kalB = -50.0, format('terkalibrasi B harus -50.0, dapat %s', kalB);
  assert (rataA < rataB) and (kalA > kalB),
    'fixture tumpul: rata-rata polos harus menuduh penguji yang keliru';

  raise exception 'KALIBRASI_OK_ROLLBACK | polos: A=% B=% -> menuduh B longgar | berpasangan: A=% B=% -> A yang longgar',
    rataA, rataB, kalA, kalB;
end $$;
