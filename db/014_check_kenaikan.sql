-- Check gerbang kenaikan kelas, lewat PANGGILAN SUNGGUHAN ke putuskan_kenaikan().
--
-- Yang dipagari, dari yang paling mudah luput:
--
--   1. KEBOCORAN LINTAS KELAS. Nilai ujian materi Kelas 2 tidak boleh ikut
--      menghitung kenaikan santri yang masih di Kelas 1. Kalau bocor, santri
--      bisa naik karena nilai ujian yang bukan haknya — dan angkanya terlihat
--      wajar sepenuhnya.
--   2. Kedua tes wajib. Lolos daring saja tidak cukup.
--   3. Tes ulang: yang dipakai nilai TERBARU, bukan yang pertama atau terbaik.
--   4. Potret nilai tersimpan di baris kenaikan, sehingga tes ulang sesudahnya
--      tidak mengubah dasar keputusan yang sudah terjadi.
--   5. Menaikkan di luar ambang boleh, TAPI wajib berkatatan alasan.
--
-- Aman diulang: seluruhnya dibatalkan lewat exception 'NAIK_OK_ROLLBACK'.
-- Jalankan:  psql < db/014_check_kenaikan.sql

do $$
declare
  v_uid uuid := '55555555-5555-5555-5555-555555555555';
  uA bigint; k1 bigint; sX bigint; sY bigint; ib bigint;
  soalBK2 bigint; soalBK1 bigint; ses1 bigint; ses2 bigint; pen bigint;
  r record; v_id bigint; tingkat_akhir text; snap record;
  pesan text := '(tidak melempar)';
begin
  select id into uA from ustadz order by id limit 1;
  select id into k1 from kelompok where nama = 'Kelompok 1';
  select santri_id into sX from kelompok_santri where kelompok_id = k1 order by santri_id limit 1;
  select santri_id into sY from kelompok_santri where kelompok_id = k1 order by santri_id offset 1 limit 1;
  select id into ib from ibarat where urutan = 1;
  select id into soalBK2 from soal where nomor_bank = 31;
  insert into soal (ibarat_id, teks, tipe, tingkat)
       values (ib, 'UJICOBA_LAFAD', 'lafad', 'BK1') returning id into soalBK1;

  insert into auth.users (id, email) values (v_uid, 'naik@sorogan.local');
  update ustadz set auth_id = v_uid where id = uA;

  -- 1. Ujian materi BK2 dengan nilai sempurna, tapi santri masih di BK1.
  insert into sesi (tanggal, ustadz_id, mode, kelompok_id)
       values (current_date - 1, uA, 'ujian', k1) returning id into ses1;
  insert into penilaian (sesi_id, santri_id, soal_id, urutan)
       values (ses1, sX, soalBK2, 1) returning id into pen;
  insert into jawaban (penilaian_id, langkah_id, verdict)
       select pen, id, 'benar' from langkah where tipe = 'nawasikh' and urutan <= 5;

  select * into r from v_kesiapan_naik where santri_id = sX;
  assert r.nilai_online is null,
    format('BOCOR LINTAS KELAS: nilai ujian BK2 terhitung untuk santri BK1 (%s)', r.nilai_online);

  -- 2. Ujian materi BK1 nilai 100 -> lolos daring, tapi belum siap.
  insert into sesi (tanggal, ustadz_id, mode, kelompok_id)
       values (current_date, uA, 'ujian', k1) returning id into ses2;
  insert into penilaian (sesi_id, santri_id, soal_id, urutan)
       values (ses2, sX, soalBK1, 1) returning id into pen;
  insert into jawaban (penilaian_id, langkah_id, verdict)
       select pen, id, 'benar' from langkah where tipe = 'lafad' and urutan <= 5;

  select * into r from v_kesiapan_naik where santri_id = sX;
  assert r.nilai_online = 100, format('nilai daring harus 100, dapat %s', r.nilai_online);
  assert r.lolos_online, 'harus lolos daring';
  assert not r.siap, 'belum boleh siap: nilai luring belum ada';

  -- 3. Tes luring 40 lalu tes ulang 90 -> yang TERBARU dipakai.
  insert into tes_offline (santri_id, kelas_kode, tanggal, nilai, dicatat_oleh)
       values (sX, 'BK1', current_date - 2, 40, uA);
  select * into r from v_kesiapan_naik where santri_id = sX;
  assert not r.lolos_offline and not r.siap, 'nilai luring 40 tidak boleh lolos';

  insert into tes_offline (santri_id, kelas_kode, tanggal, nilai, dicatat_oleh)
       values (sX, 'BK1', current_date, 90, uA);
  select * into r from v_kesiapan_naik where santri_id = sX;
  assert r.nilai_offline = 90, format('tes ulang terbaru harus dipakai, dapat %s', r.nilai_offline);
  assert r.siap, 'harus siap naik';

  -- 4. Keputusan asatidz lewat RPC sungguhan.
  perform set_config('request.jwt.claims',
    '{"sub":"55555555-5555-5555-5555-555555555555","role":"authenticated"}', true);
  set local role authenticated;
  v_id := putuskan_kenaikan(sX, true, null);
  reset role;

  select tingkat into tingkat_akhir from santri where id = sX;
  select * into snap from kenaikan where id = v_id;
  assert tingkat_akhir = 'BK2', format('tingkat harus jadi BK2, dapat %s', tingkat_akhir);
  assert snap.nilai_online = 100 and snap.nilai_offline = 90, 'potret nilai tidak tersimpan';
  assert snap.memenuhi_ambang, 'harus tercatat memenuhi ambang';

  -- 5. Menaikkan di luar ambang tanpa alasan harus DITOLAK.
  set local role authenticated;
  begin
    perform putuskan_kenaikan(sY, true, null);
  exception when others then pesan := SQLERRM;
  end;
  reset role;
  assert pesan = 'Menaikkan di luar ambang harus disertai catatan alasan.',
    format('penjaga catatan tidak bekerja: %s', pesan);

  raise exception 'NAIK_OK_ROLLBACK | lintas-kelas ditolak | daring=100 luring=90(tes ulang) siap=t | tingkat->% | tanpa-alasan: "%"',
    tingkat_akhir, pesan;
end $$;
