-- Satu check yang bisa dijalankan ulang kapan saja. Aman: seluruhnya
-- dibatalkan (rollback) di akhir lewat exception 'CHECK_OK_ROLLBACK'.
--
-- Yang diuji hanya logika yang benar-benar bisa salah diam-diam:
--
--   1. Nilai = rata-rata PER SOAL dulu, baru antar soal.
--      Kalau seseorang "menyederhanakan" jadi rata-rata seluruh langkah,
--      soal bertangga panjang otomatis berbobot lebih besar. Hasilnya tetap
--      terlihat wajar di layar — itulah kenapa harus ada test.
--   2. verdict 'dibantu' = 0.5, bukan 0 dan bukan 1.
--   3. Langkah yang dilewati (tak punya baris) tidak menurunkan nilai.
--
-- Jalankan:  psql < db/003_check.sql   (atau lewat SQL editor Supabase)

do $$
declare
  v_ust    bigint;  v_san bigint;  v_sesi bigint;
  v_soal_a bigint;  v_soal_b bigint;
  v_pa     bigint;  v_pb  bigint;
  v_a numeric; v_b numeric; v_santri numeric; v_flat numeric;
begin
  select id into v_ust  from ustadz order by id limit 1;
  select id into v_san  from santri order by id limit 1;
  select id into v_soal_a from soal where nomor_bank = 1;   -- ismiyah,  9 langkah
  select id into v_soal_b from soal where nomor_bank = 31;  -- nawasikh, 7 langkah

  insert into sesi (ustadz_id, mode) values (v_ust, 'ujian') returning id into v_sesi;
  insert into penilaian (sesi_id, santri_id, soal_id, urutan)
    values (v_sesi, v_san, v_soal_a, 1) returning id into v_pa;
  insert into penilaian (sesi_id, santri_id, soal_id, urutan)
    values (v_sesi, v_san, v_soal_b, 2) returning id into v_pb;

  -- Soal A: 9 langkah tercatat = 4 benar + 1 dibantu + 4 salah = 4.5/9 = 50.0
  insert into jawaban (penilaian_id, langkah_id, verdict)
  select v_pa, l.id, x.v
  from langkah l join (values
    (1,'benar'),(2,'benar'),(3,'benar'),(4,'benar'),(5,'dibantu'),
    (6,'salah'),(7,'salah'),(8,'salah'),(9,'salah')
  ) as x(u, v) on x.u = l.urutan
  where l.tipe = 'ismiyah';

  -- Soal B: hanya 5 dari 7 langkah dicatat, semua benar = 5/5 = 100.0
  -- 2 langkah sisanya DILEWATI dan sengaja tidak punya baris.
  insert into jawaban (penilaian_id, langkah_id, verdict)
  select v_pb, l.id, 'benar'
  from langkah l where l.tipe = 'nawasikh' and l.urutan <= 5;

  select nilai into v_a from v_nilai_soal where penilaian_id = v_pa;
  select nilai into v_b from v_nilai_soal where penilaian_id = v_pb;
  select nilai into v_santri from v_nilai_santri
   where sesi_id = v_sesi and santri_id = v_san;

  assert v_a = 50.0,  format('nilai soal A harus 50.0, dapat %s', v_a);
  assert v_b = 100.0, format('langkah dilewati tidak boleh menurunkan nilai; '
                             'soal B harus 100.0, dapat %s', v_b);
  assert v_santri = 75.0, format('nilai santri harus 75.0, dapat %s', v_santri);

  -- Pembanding: rumus SALAH (rata-rata datar seluruh langkah) menghasilkan
  -- angka lain. Kalau suatu saat keduanya jadi sama, test ini kehilangan
  -- daya bedanya dan harus diganti.
  select round(avg(bobot(verdict)) * 100, 1) into v_flat
    from jawaban where penilaian_id in (v_pa, v_pb);
  assert v_flat <> v_santri,
    format('test tumpul: rumus datar (%s) kebetulan sama dengan yang benar (%s)',
           v_flat, v_santri);

  raise exception 'CHECK_OK_ROLLBACK';   -- semua lolos; batalkan data uji
end $$;
