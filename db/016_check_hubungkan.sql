-- Check jalur penghubungan identitas, lewat PANGGILAN SUNGGUHAN.
--
-- Menggantikan db/007_check_klaim.sql setelah kode klaim dihapus. Ada karena
-- bug yang pernah dipagarinya nyata: badan plpgsql hanya diresolusi saat
-- dijalankan, jadi HANYA panggilan sungguhan yang bisa membuktikannya hidup.
-- Jangan pernah menguji ini dengan menyetel `ustadz.auth_id` langsung.
--
-- Invarian yang dipagari:
--   1. Akun login tapi BELUM terhubung melihat NOL baris data santri…
--   2. …tapi tetap bisa melihat daftar nama untuk dipilih.
--   3. Sesudah terhubung, data terbuka.
--   4. Satu akun tidak bisa terhubung ke dua ustadz.
--   5. Nama yang sudah dipakai TIDAK bisa diambil alih akun lain.
--
-- Aman diulang: dibatalkan lewat exception 'HUBUNG_OK_ROLLBACK'.
-- Jalankan:  psql < db/016_check_hubungkan.sql

do $$
declare
  v_uid  uuid := '66666666-6666-6666-6666-666666666666';
  v_uid2 uuid := '77777777-7777-7777-7777-777777777777';
  v_ust bigint; v_nama text; n_belum int; n_soal int; n_sudah int; n_pilihan int;
  pesan2 text := '(tidak melempar)'; pesan3 text := '(tidak melempar)';
begin
  select id, nama into v_ust, v_nama from ustadz where auth_id is null order by id limit 1;
  if v_ust is null then
    raise exception 'Semua ustadz sudah terhubung — tidak ada yang bisa diuji.';
  end if;

  insert into auth.users (id, email)
       values (v_uid, 'h1@sorogan.local'), (v_uid2, 'h2@sorogan.local');

  perform set_config('request.jwt.claims',
    '{"sub":"66666666-6666-6666-6666-666666666666","role":"authenticated"}', true);
  set local role authenticated;

  select count(*) into n_belum   from santri;
  select count(*) into n_soal    from soal;
  select count(*) into n_pilihan from ustadz where auth_id is null;
  assert n_belum = 0, format('BOCOR: belum terhubung melihat %s santri', n_belum);
  assert n_soal  = 0, format('BOCOR: belum terhubung melihat %s soal', n_soal);
  assert n_pilihan > 0, 'daftar nama untuk dipilih harus tetap terlihat';

  perform hubungkan_ustadz(v_ust);
  select count(*) into n_sudah from santri;

  begin perform hubungkan_ustadz(v_ust);
  exception when others then pesan2 := SQLERRM; end;
  reset role;

  perform set_config('request.jwt.claims',
    '{"sub":"77777777-7777-7777-7777-777777777777","role":"authenticated"}', true);
  set local role authenticated;
  begin perform hubungkan_ustadz(v_ust);
  exception when others then pesan3 := SQLERRM; end;
  reset role;

  assert n_sudah = 20, format('sesudah terhubung harus melihat 20 santri, dapat %s', n_sudah);
  assert pesan2 = 'Akun ini sudah terhubung ke seorang ustadz.', format('pilih ulang: %s', pesan2);
  assert pesan3 = 'Nama itu sudah dipakai akun lain.', format('nama terpakai: %s', pesan3);

  raise exception 'HUBUNG_OK_ROLLBACK | % | santri 0 -> % | pilihan tampil=% | ulang: "%" | akun lain: "%"',
    v_nama, n_sudah, n_pilihan, pesan2, pesan3;
end $$;
